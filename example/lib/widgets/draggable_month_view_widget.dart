import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import '../pages/event_details_page.dart';
import '../pages/create_event_page.dart';
import '../pages/create_free_time_page.dart';
import '../extension.dart';
import 'draggable_month_cell.dart';

class DraggableMonthViewWidget extends StatefulWidget {
  final GlobalKey<MonthViewState>? state;
  final double? width;

  const DraggableMonthViewWidget({
    super.key,
    this.state,
    this.width,
  });

  @override
  State<DraggableMonthViewWidget> createState() => _DraggableMonthViewWidgetState();
}

class _DraggableMonthViewWidgetState extends State<DraggableMonthViewWidget> {
  DateTime? _dragOverDate;
  CalendarEventData? _draggedEvent;

  @override
  Widget build(BuildContext context) {
    return MonthView(
      key: widget.state,
      width: widget.width,
      showWeekends: true,
      startDay: WeekDays.friday,
      useAvailableVerticalSpace: true,
      hideDaysNotInMonth: true,
      cellBuilder: _buildDraggableCell,
      onEventTap: (event, date) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailsPage(
              event: event,
              date: date,
            ),
          ),
        );
      },
      onDateLongPress: (date) {
        _showQuickEventDialog(context, date);
      },
    );
  }

  Widget _buildDraggableCell(
    DateTime date,
    List<CalendarEventData> events,
    bool isToday,
    bool isInMonth,
    bool hideDaysNotInMonth,
    bool isOutOfMonth,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get month view theme data from theme extensions
    final monthViewTheme = Theme.of(context).extension<MonthViewThemeData>();
    final themeColor = monthViewTheme ?? MonthViewThemeData.light();

    return DragTarget<CalendarEventData>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        // Only accept if the event is being moved to a different date
        return data.date.year != date.year || 
               data.date.month != date.month || 
               data.date.day != date.day;
      },
      onAcceptWithDetails: (details) {
        _handleEventMovedToDate(details.data, date);
      },
      onMove: (details) {
        setState(() {
          _dragOverDate = date;
        });
      },
      onLeave: (data) {
        setState(() {
          _dragOverDate = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isDragTarget = candidateData.isNotEmpty;
        
        return Container(
          decoration: BoxDecoration(
            color: isDragTarget 
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            border: isDragTarget
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: DraggableMonthCell(
            date: date,
            shouldHighlight: isToday,
            backgroundColor: isInMonth
                ? themeColor.cellInMonthColor
                : themeColor.cellNotInMonthColor,
            events: events,
            isInMonth: isInMonth,
            onTileTap: (event, date) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetailsPage(
                    event: event,
                    date: date,
                  ),
                ),
              );
            },
            dateStringBuilder: (date, {secondaryDate}) => "${date.day}",
            hideDaysNotInMonth: hideDaysNotInMonth,
            titleColor: isInMonth
                ? themeColor.cellTextColor
                : themeColor.cellTextColor.withAlpha(150),
            highlightColor: themeColor.cellHighlightColor,
            highlightRadius: 11,
            tileColor: themeColor.cellHighlightColor,
            onEventMovedToDate: _handleEventMovedToDate,
            onDragStart: _handleDragStart,
            onDragEnd: _handleDragEnd,
          ),
        );
      },
    );
  }

  void _handleEventMovedToDate(CalendarEventData event, DateTime newDate) {
    final controller = CalendarControllerProvider.of(context).controller;
    
    // Remove the old event
    controller.remove(event);
    
    // Create new event with updated date but same time
    final updatedEvent = CalendarEventData(
      title: event.title,
      description: event.description,
      date: newDate,
      startTime: event.startTime != null 
          ? DateTime(
              newDate.year,
              newDate.month,
              newDate.day,
              event.startTime!.hour,
              event.startTime!.minute,
            )
          : null,
      endTime: event.endTime != null
          ? DateTime(
              newDate.year,
              newDate.month,
              newDate.day,
              event.endTime!.hour,
              event.endTime!.minute,
            )
          : null,
      color: event.color,
      titleStyle: event.titleStyle,
      descriptionStyle: event.descriptionStyle,
    );
    
    // Add the updated event
    controller.add(updatedEvent);
    
    // Show feedback
    final dayName = _getDayName(newDate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event moved to $dayName'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _getDayName(DateTime date) {
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return dayNames[date.weekday % 7];
  }

  void _handleDragStart(CalendarEventData event, DateTime date) {
    setState(() {
      _draggedEvent = event;
    });
  }

  void _handleDragEnd(CalendarEventData event, DateTime date) {
    setState(() {
      _draggedEvent = null;
      _dragOverDate = null;
    });
  }

  /// Shows a quick event creation dialog when user long presses on calendar
  void _showQuickEventDialog(BuildContext context, DateTime date) {
    // Create a default event with the selected date (no specific time for month view)
    final startTime = DateTime(date.year, date.month, date.day, 9, 0); // Default to 9 AM
    final endTime = startTime.add(const Duration(hours: 1));
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Event'),
          content: const Text('What would you like to create?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final defaultEvent = CalendarEventData(
                  title: '',
                  date: startTime,
                  startTime: startTime,
                  endTime: endTime,
                );
                context.pushRoute(CreateEventPage(event: defaultEvent));
              },
              child: const Text('Regular Event'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final defaultEvent = CalendarEventData(
                  title: '',
                  date: startTime,
                  startTime: startTime,
                  endTime: endTime,
                );
                context.pushRoute(CreateFreeTimePage(event: defaultEvent));
              },
              child: const Text('Free Time Block'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
