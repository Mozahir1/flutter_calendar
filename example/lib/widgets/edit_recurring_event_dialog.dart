import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

enum EditRecurringEventType {
  thisEvent,
  thisAndFollowing,
  allEvents,
}

class EditRecurringEventDialog extends StatefulWidget {
  final CalendarEventData event;

  const EditRecurringEventDialog({
    super.key,
    required this.event,
  });

  @override
  _EditRecurringEventDialogState createState() => _EditRecurringEventDialogState();
}

class _EditRecurringEventDialogState extends State<EditRecurringEventDialog> {
  EditRecurringEventType _selectedOption = EditRecurringEventType.thisEvent;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit recurring event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile(
            title: Text('Only this event'),
            subtitle: Text('Edit just this occurrence'),
            value: EditRecurringEventType.thisEvent,
            groupValue: _selectedOption,
            onChanged: (editType) {
              if (editType != null) {
                setState(() => _selectedOption = editType);
              }
            },
          ),
          RadioListTile(
            title: Text('This and following events'),
            subtitle: Text('Edit this event and all future occurrences'),
            value: EditRecurringEventType.thisAndFollowing,
            groupValue: _selectedOption,
            onChanged: (editType) {
              if (editType != null) {
                setState(() => _selectedOption = editType);
              }
            },
          ),
          RadioListTile(
            title: Text('All events'),
            subtitle: Text('Edit all occurrences in the series'),
            value: EditRecurringEventType.allEvents,
            groupValue: _selectedOption,
            onChanged: (editType) {
              if (editType != null) {
                setState(() => _selectedOption = editType);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedOption),
          child: Text('Continue'),
        ),
      ],
    );
  }
}
