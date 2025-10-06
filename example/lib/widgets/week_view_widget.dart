import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/event_details_page.dart';
import '../pages/create_event_page.dart';
import '../extension.dart';
import 'draggable_event_tile.dart';
import '../controllers/enhanced_event_controller.dart';

class WeekViewWidget extends StatelessWidget {
  final GlobalKey<WeekViewState>? state;
  final double? width;

  const WeekViewWidget({super.key, this.state, this.width});

  @override
  Widget build(BuildContext context) {
    return WeekView(
      key: state,
      width: width,
      showWeekends: true,
      showLiveTimeLineInAllDays: true,
      eventArranger: FullWidthEventArranger(),
      eventTileBuilder: (date, events, boundary, startDuration, endDuration) => 
          _buildDraggableEventTile(context, date, events, boundary, startDuration, endDuration),
      timeLineWidth: 65,
      scrollPhysics: const BouncingScrollPhysics(),
      liveTimeIndicatorSettings: LiveTimeIndicatorSettings(
        color: Colors.blueAccent,
        showTime: true,
      ),
      onTimestampTap: (date) {
        SnackBar snackBar = SnackBar(
          content: Text("On tap: ${date.hour} Hr : ${date.minute} Min"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      // onEventTap is now handled by DraggableEventTile
      onEventLongTap: (events, date) {
        if (events.isNotEmpty) {
          _showEventContextMenu(context, events.first, date);
        }
      },
      onDateLongPress: (date) {
        _showQuickEventDialog(context, date);
      },
    );
  }

  /// Builds a draggable and resizable event tile
  Widget _buildDraggableEventTile(
    BuildContext context,
    DateTime date,
    List<CalendarEventData> events,
    Rect boundary,
    DateTime startDuration,
    DateTime endDuration,
  ) {
    // Calculate week context for cross-day dragging
    // Use the same start day as the WeekView (which defaults to Sunday)
    final weekStart = date.firstDayOfWeek(start: WeekDays.sunday);
    final weekDates = List.generate(7, (index) => weekStart.add(Duration(days: index)));
    
    // Calculate more accurate day width
    final screenWidth = MediaQuery.of(context).size.width;
    // Try different timeline widths to see which one works
    final timelineWidth = 65.0; // WeekView default timeline width
    final availableWidth = screenWidth - timelineWidth;
    final dayWidth = availableWidth / 7; // 7 days in a week
    
    // Alternative calculation - try using the actual boundary width
    final alternativeDayWidth = boundary.width;
    
    // Debug information
    print('Week context: screenWidth=$screenWidth, timelineWidth=$timelineWidth, dayWidth=$dayWidth');
    print('Alternative dayWidth from boundary: $alternativeDayWidth');
    print('Week dates: $weekDates');
    print('Current date: $date');
    
    return DraggableEventTile(
      date: date,
      events: events,
      boundary: boundary,
      startDuration: startDuration,
      endDuration: endDuration,
      heightPerMinute: 1.0, // WeekView default heightPerMinute
      dayWidth: alternativeDayWidth, // Use the actual boundary width as day width
      weekDates: weekDates,
      onEventMoved: (event, start, end) => _handleEventMoved(context, event, start, end),
      onEventMovedToDay: (event, start, end, newDate) => _handleEventMovedToDay(context, event, start, end, newDate),
      onEventResized: (event, start, end) => _handleEventResized(context, event, start, end),
      onEventTap: (event, date) => _handleEventTap(context, event, date),
          onEventDuplicate: (event, date) => _handleEventDuplicate(context, event, date),
          onEventDelete: (event, date) => _handleEventDelete(context, event, date),
    );
  }

  /// Handles when an event is tapped (opens edit menu)
  void _handleEventTap(BuildContext context, CalendarEventData event, DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailsPage(
          event: event,
          date: date,
        ),
      ),
    );
  }

  /// Handles when an event is moved to a new time (same day)
  void _handleEventMoved(BuildContext context, CalendarEventData event, DateTime newStartTime, DateTime newEndTime) {
    final controller = CalendarControllerProvider.of(context).controller;
    
    // Remove the old event
    controller.remove(event);
    
    // Create new event with updated times
    final updatedEvent = CalendarEventData(
      title: event.title,
      description: event.description,
      date: newStartTime,
      startTime: newStartTime,
      endTime: newEndTime,
      color: event.color,
      titleStyle: event.titleStyle,
      descriptionStyle: event.descriptionStyle,
    );
    
    // Add the updated event
    controller.add(updatedEvent);
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event moved to ${_formatTime(newStartTime)}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Handles when an event is moved to a different day
  void _handleEventMovedToDay(BuildContext context, CalendarEventData event, DateTime newStartTime, DateTime newEndTime, DateTime newDate) {
    final controller = CalendarControllerProvider.of(context).controller;
    
    // Remove the old event
    controller.remove(event);
    
    // Create new event with updated date and times
    final updatedEvent = CalendarEventData(
      title: event.title,
      description: event.description,
      date: newDate,
      startTime: newStartTime,
      endTime: newEndTime,
      color: event.color,
      titleStyle: event.titleStyle,
      descriptionStyle: event.descriptionStyle,
    );
    
    // Add the updated event
    controller.add(updatedEvent);
    
    // Show feedback with day information
    final dayName = _getDayName(newDate);
    final oldDayName = _getDayName(event.date);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event moved from $oldDayName to $dayName at ${_formatTime(newStartTime)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handles when an event is resized to a new duration
  void _handleEventResized(BuildContext context, CalendarEventData event, DateTime startTime, DateTime newEndTime) {
    final controller = CalendarControllerProvider.of(context).controller;
    
    // Remove the old event
    controller.remove(event);
    
    // Create new event with updated end time
    final updatedEvent = CalendarEventData(
      title: event.title,
      description: event.description,
      date: startTime,
      startTime: startTime,
      endTime: newEndTime,
      color: event.color,
      titleStyle: event.titleStyle,
      descriptionStyle: event.descriptionStyle,
    );
    
    // Add the updated event
    controller.add(updatedEvent);
    
    // Show feedback
    final duration = newEndTime.difference(startTime);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event duration: ${duration.inMinutes} minutes'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Formats time for display
  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Gets the day name for a given date
  String _getDayName(DateTime date) {
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return dayNames[date.weekday % 7];
  }

  /// Shows a quick event creation dialog when user long presses on calendar
  void _showQuickEventDialog(BuildContext context, DateTime date) {
    // Create a default event with the selected time slot
    final startTime = DateTime(date.year, date.month, date.day, date.hour, date.minute);
    final endTime = startTime.add(const Duration(hours: 1));
    
    final defaultEvent = CalendarEventData(
      title: '',
      date: startTime,
      startTime: startTime,
      endTime: endTime,
    );

    // Navigate to the existing CreateEventPage with pre-filled data
    context.pushRoute(CreateEventPage(event: defaultEvent));
  }

  /// Shows context menu for editing/deleting existing events
  void _showEventContextMenu(BuildContext context, CalendarEventData event, DateTime date) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Event'),
                onTap: () {
                  Navigator.of(context).pop();
                  _editEvent(context, event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.blue),
                title: const Text('Delete Event', style: TextStyle(color: Colors.blue)),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteEvent(context, event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetailsPage(
                        event: event,
                        date: date,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Edit an existing event
  void _editEvent(BuildContext context, CalendarEventData event) {
    // Navigate to the existing CreateEventPage with the event to edit
    context.pushRoute(CreateEventPage(event: event));
  }

  /// Delete an existing event
  void _deleteEvent(BuildContext context, CalendarEventData event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: Text('Are you sure you want to delete "${event.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final enhancedController = Provider.of<EnhancedEventController>(context, listen: false);
                final calendarController = CalendarControllerProvider.of(context).controller;
                
                // Delete from both controllers
                await enhancedController.deleteEventByProperties(event);
                calendarController.remove(event);
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Event "${event.title}" deleted'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }


  /// Handles duplicate event action
  void _handleEventDuplicate(BuildContext context, CalendarEventData event, DateTime date) {
    print('Week view: Duplicate event called for ${event.title}');
    // Create a duplicate event with the same time but on the same day
    final duplicatedEvent = CalendarEventData(
      title: '${event.title} (Copy)',
      description: event.description,
      date: event.date,
      startTime: event.startTime,
      endTime: event.endTime,
      color: event.color,
      titleStyle: event.titleStyle,
      descriptionStyle: event.descriptionStyle,
    );
    
    // Add the duplicated event
    CalendarControllerProvider.of(context).controller.add(duplicatedEvent);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event "${event.title}" duplicated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Handles delete event action
  void _handleEventDelete(BuildContext context, CalendarEventData event, DateTime date) {
    print('Week view: Delete event called for ${event.title}');
    // Remove the event
    CalendarControllerProvider.of(context).controller.remove(event);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event "${event.title}" deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
