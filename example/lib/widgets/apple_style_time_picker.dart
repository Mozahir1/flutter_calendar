import 'dart:async';
import 'package:flutter/material.dart';

class AppleStyleTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay>? onTimeChanged;

  const AppleStyleTimePicker({
    super.key,
    required this.initialTime,
    this.onTimeChanged,
  });

  @override
  State<AppleStyleTimePicker> createState() => _AppleStyleTimePickerState();
}

class _AppleStyleTimePickerState extends State<AppleStyleTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _periodController;
  
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAM;
  
  static const int _centerOffset = 1000; // Center position in the list for infinite scrolling

  @override
  void initState() {
    super.initState();
    
    // Convert to 12-hour format
    _selectedHour = widget.initialTime.hourOfPeriod;
    _selectedMinute = widget.initialTime.minute;
    _isAM = widget.initialTime.period == DayPeriod.am;
    
    // Initialize controllers with current values at center
    final minuteIndex = _selectedMinute % 60;
    final hourOffset = (_selectedHour - 1) % 12;
    
    _hourController = FixedExtentScrollController(initialItem: _centerOffset + hourOffset);
    _minuteController = FixedExtentScrollController(initialItem: _centerOffset + minuteIndex);
    _periodController = FixedExtentScrollController(initialItem: _isAM ? 0 : 1);
    
    // No custom infinite scroll logic - use Flutter's built-in capabilities
    
    // Ensure controllers are positioned correctly after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _hourController.jumpToItem(_centerOffset + hourOffset);
        _minuteController.jumpToItem(_centerOffset + minuteIndex);
        _periodController.jumpToItem(_isAM ? 0 : 1);
      }
    });
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }


  void _onTimeChanged() {
    // Convert 12-hour format to 24-hour format correctly
    int hour24;
    if (_isAM) {
      // AM: 12 becomes 0, 1-11 stay the same
      hour24 = _selectedHour == 12 ? 0 : _selectedHour;
    } else {
      // PM: 1-11 add 12, 12 stays 12
      hour24 = _selectedHour == 12 ? 12 : _selectedHour + 12;
    }
    
    final newTime = TimeOfDay(
      hour: hour24,
      minute: _selectedMinute,
    );
    widget.onTimeChanged?.call(newTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Hour picker
          Expanded(
            child: _buildInfinitePicker(
              controller: _hourController,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedHour = (index % 12) + 1;
                });
                _onTimeChanged();
              },
              itemBuilder: (context, index) {
                final hour = (index % 12) + 1;
                final isSelected = hour == _selectedHour;
                return Container(
                  alignment: Alignment.center,
                  child: Text(
                    hour.toString(),
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Separator
          Container(
            width: 20,
            alignment: Alignment.center,
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          
          // Minute picker
          Expanded(
            child: _buildInfinitePicker(
              controller: _minuteController,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedMinute = index % 60;
                });
                _onTimeChanged();
              },
              itemBuilder: (context, index) {
                final minute = index % 60;
                final isSelected = minute == _selectedMinute;
                return Container(
                  alignment: Alignment.center,
                  child: Text(
                    minute.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // AM/PM picker
          Expanded(
            child: _buildSimplePicker(
              controller: _periodController,
              onSelectedItemChanged: (index) {
                setState(() {
                  _isAM = index == 0;
                });
                _onTimeChanged();
              },
              itemBuilder: (context, index) {
                final period = index == 0 ? 'AM' : 'PM';
                final isSelected = (index == 0) == _isAM;
                return Container(
                  alignment: Alignment.center,
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: isSelected ? 20 : 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfinitePicker({
    required FixedExtentScrollController controller,
    required ValueChanged<int> onSelectedItemChanged,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 50,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelectedItemChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: null, // Infinite scrolling
          builder: itemBuilder,
        ),
      ),
    );
  }

  Widget _buildSimplePicker({
    required FixedExtentScrollController controller,
    required ValueChanged<int> onSelectedItemChanged,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 50,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelectedItemChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: 2, // Only AM and PM
          builder: itemBuilder,
        ),
      ),
    );
  }
}

/// Shows an Apple-style time picker dialog
Future<TimeOfDay?> showAppleStyleTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (BuildContext context) {
      TimeOfDay selectedTime = initialTime;
      
      return AlertDialog(
        title: const Text('Select Time'),
        content: AppleStyleTimePicker(
          initialTime: initialTime,
          onTimeChanged: (time) {
            selectedTime = time;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(selectedTime),
            child: const Text('Done'),
          ),
        ],
      );
    },
  );
}
