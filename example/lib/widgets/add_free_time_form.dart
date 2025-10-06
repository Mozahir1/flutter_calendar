import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../extension.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';
import 'date_time_selector.dart';

class AddOrEditFreeTimeForm extends StatefulWidget {
  final void Function(CalendarEventData)? onFreeTimeAdd;
  final CalendarEventData? event;
  final DateTime? specificDate; // The specific date of the occurrence being edited

  const AddOrEditFreeTimeForm({
    super.key,
    this.onFreeTimeAdd,
    this.event,
    this.specificDate,
  });

  @override
  _AddOrEditFreeTimeFormState createState() => _AddOrEditFreeTimeFormState();
}

class _AddOrEditFreeTimeFormState extends State<AddOrEditFreeTimeForm> {
  late DateTime _startDate = DateTime.now().withoutTime;
  late DateTime _endDate = DateTime.now().withoutTime;
  DateTime? _recurrenceEndDate;

  DateTime? _startTime;
  DateTime? _endTime;
  List<bool> _selectedDays = List.filled(7, false);
  RepeatFrequency? _selectedFrequency = RepeatFrequency.doNotRepeat;
  RecurrenceEnd? _selectedRecurrenceEnd = RecurrenceEnd.never;
  bool _isRecurring = false;

  // Free time always uses transparent green
  final Color _color = Colors.green.withOpacity(0.3);

  final _form = GlobalKey<FormState>();

  late final _descriptionController = TextEditingController();
  late final _occurrenceController = TextEditingController();
  late final _descriptionNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setDates();
    _setTimes();
    _setTexts();
    _setRecurrence();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _occurrenceController.dispose();
    _descriptionNode.dispose();
    super.dispose();
  }

  void _setDates() {
    if (widget.event != null) {
      _startDate = widget.specificDate ?? widget.event!.date.withoutTime;
      _endDate = widget.event!.endDate.withoutTime;
    }
  }

  void _setTimes() {
    if (widget.event != null) {
      _startTime = widget.event!.startTime;
      _endTime = widget.event!.endTime;
    }
  }

  void _setTexts() {
    if (widget.event != null) {
      _descriptionController.text = widget.event!.description ?? '';
    }
  }

  void _setRecurrence() {
    if (widget.event?.recurrenceSettings != null) {
      _isRecurring = true;
      _selectedFrequency = widget.event!.recurrenceSettings!.frequency;
      _selectedRecurrenceEnd = widget.event!.recurrenceSettings!.recurrenceEndOn;
      _selectedDays = widget.event!.recurrenceSettings!.weekdays
          .map((day) => _selectedDays[day - 1] = true)
          .toList();
      _recurrenceEndDate = widget.event!.recurrenceSettings!.endDate;
      _occurrenceController.text =
          widget.event!.recurrenceSettings!.occurrences?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextFormField(
              controller: _descriptionController,
              focusNode: _descriptionNode,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DateTimeSelectorFormField(
                    type: DateTimeSelectionType.date,
                    onSelect: (date) => setState(() => _startDate = date),
                    initialDateTime: _startDate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DateTimeSelectorFormField(
                    type: DateTimeSelectionType.date,
                    onSelect: (date) => setState(() => _endDate = date),
                    initialDateTime: _endDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DateTimeSelectorFormField(
                    type: DateTimeSelectionType.time,
                    onSelect: (time) => setState(() => _startTime = time),
                    initialDateTime: _startTime ?? DateTime.now(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DateTimeSelectorFormField(
                    type: DateTimeSelectionType.time,
                    onSelect: (time) => setState(() => _endTime = time),
                    initialDateTime: _endTime ?? DateTime.now(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecurrenceSection(),
            const SizedBox(height: 16),
            _buildRecurrenceOptions(),
            const SizedBox(height: 16),
            CustomButton(
              onTap: _createFreeTime,
              title: widget.event != null ? 'Update Free Time' : 'Create Free Time',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Repeat'),
                const Spacer(),
                Switch(
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                      if (!value) {
                        _selectedFrequency = RepeatFrequency.doNotRepeat;
                        _selectedRecurrenceEnd = RecurrenceEnd.never;
                        _selectedDays = List.filled(7, false);
                        _recurrenceEndDate = null;
                        _occurrenceController.clear();
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceOptions() {
    if (!_isRecurring) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Repeat every'),
            const SizedBox(height: 8),
            DropdownButtonFormField<RepeatFrequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: RepeatFrequency.values
                  .where((frequency) => frequency != RepeatFrequency.doNotRepeat)
                  .map((frequency) => DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedFrequency == RepeatFrequency.weekly) ...[
              const Text('Repeat on'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return FilterChip(
                    label: Text(dayNames[index]),
                    selected: _selectedDays[index],
                    onSelected: (selected) {
                      setState(() {
                        _selectedDays[index] = selected;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Ends'),
            const SizedBox(height: 8),
            DropdownButtonFormField<RecurrenceEnd>(
              value: _selectedRecurrenceEnd,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: RecurrenceEnd.values.map((end) => DropdownMenuItem(
                        value: end,
                        child: Text(end.name),
                      )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRecurrenceEnd = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedRecurrenceEnd == RecurrenceEnd.onDate) ...[
              DateTimeSelectorFormField(
                type: DateTimeSelectionType.date,
                onSelect: (date) => setState(() => _recurrenceEndDate = date),
                initialDateTime: _recurrenceEndDate ?? _startDate,
              ),
              const SizedBox(height: 16),
            ],
            if (_selectedRecurrenceEnd == RecurrenceEnd.after) ...[
              TextFormField(
                controller: _occurrenceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Number of occurrences',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  List<int> get _toWeekdayInIndices {
    final weekdays = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        weekdays.add(i + 1);
      }
    }
    return weekdays;
  }

  void _createFreeTime() {
    if (!(_form.currentState?.validate() ?? true)) return;

    _form.currentState?.save();

    DateTime? combinedStartTime;
    DateTime? combinedEndTime;

    if (_startTime != null) {
      // Create a proper DateTime that combines the start date with start time
      combinedStartTime = DateTime(_startDate.year, _startDate.month,
          _startDate.day, _startTime!.hour, _startTime!.minute);
    }

    if (_endTime != null) {
      // Create a proper DateTime that combines the end date with end time
      combinedEndTime = DateTime(_endDate.year, _endDate.month, _endDate.day,
          _endTime!.hour, _endTime!.minute);
    }

    // Only create recurrence settings if not using the default "Do not repeat" option
    RecurrenceSettings? recurrence;
    if (_selectedFrequency != null &&
        _selectedFrequency != RepeatFrequency.doNotRepeat) {
      var occurrences = int.tryParse(_occurrenceController.text);
      DateTime? endDate;

      // On event edit recurrence end is selected "Never"
      // Remove any previous end date & occurrences stored.
      if (_selectedRecurrenceEnd == RecurrenceEnd.never) {
        endDate = null;
        occurrences = null;
      }

      if (_selectedRecurrenceEnd == RecurrenceEnd.onDate) {
        endDate = _recurrenceEndDate;
      }

      recurrence = RecurrenceSettings.withCalculatedEndDate(
        startDate: _startDate,
        endDate: endDate,
        frequency: _selectedFrequency ?? RepeatFrequency.daily,
        weekdays: _toWeekdayInIndices,
        occurrences: occurrences,
        recurrenceEndOn: _selectedRecurrenceEnd ?? RecurrenceEnd.never,
      );
    }

    // Determine the appropriate endDate based on whether this is a recurring event
    final DateTime eventEndDate =
        recurrence != null ? (recurrence.endDate ?? _startDate) : _endDate;

    final freeTimeEvent = CalendarEventData(
      title: 'Free Time',
      description: _descriptionController.text,
      color: _color, // Always transparent green for free time
      startTime: combinedStartTime,
      endTime: combinedEndTime,
      date: _startDate,
      endDate: eventEndDate,
      recurrenceSettings: recurrence,
    );

    widget.onFreeTimeAdd?.call(freeTimeEvent);
  }
}
