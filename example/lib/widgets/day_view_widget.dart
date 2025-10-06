import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/event_details_page.dart';
import '../pages/create_event_page.dart';
import '../extension.dart';
import 'draggable_event_tile.dart';
import '../controllers/enhanced_event_controller.dart';

class DayViewWidget extends StatelessWidget {
  final GlobalKey<DayViewState>? state;
  final double? width;

  const DayViewWidget({
    super.key,
    this.state,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return DayView(
      key: state,
      width: width,
      startDuration: Duration(hours: 8),
      showHalfHours: true,
      heightPerMinute: 3,
      timeLineBuilder: _timeLineBuilder,
      eventTileBuilder: (date, events, boundary, startDuration, endDuration) => 
          _buildDraggableEventTile(context, date, events, boundary, startDuration, endDuration),
      scrollPhysics: const BouncingScrollPhysics(),
      eventArranger: FullWidthEventArranger(),
      showQuarterHours: false,
      hourIndicatorSettings: HourIndicatorSettings(
        color: Theme.of(context).dividerColor,
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
      halfHourIndicatorSettings: HourIndicatorSettings(
        color: CalendarThemeProvider.of(context)
            .calendarTheme
            .dayViewTheme
            .hourLineColor,
        lineStyle: LineStyle.dashed,
      ),
      verticalLineOffset: 0,
      timeLineWidth: 65,
      showLiveTimeLineInAllDays: true,
      liveTimeIndicatorSettings: LiveTimeIndicatorSettings(
        color: Colors.blueAccent,
        showBullet: false,
        showTime: true,
        showTimeBackgroundView: true,
      ),
    );
  }

  Widget _timeLineBuilder(DateTime date) {
    if (date.minute != 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: -8,
            right: 8,
            child: Text(
              "${date.hour}:${date.minute}",
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    final hour = ((date.hour - 1) % 12) + 1;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: -8,
          right: 8,
          child: Text(
            "$hour ${date.hour ~/ 12 == 0 ? "am" : "pm"}",
            textAlign: TextAlign.right,
          ),
        ),
      ],
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
    return DraggableEventTile(
      date: date,
      events: events,
      boundary: boundary,
      startDuration: startDuration,
      endDuration: endDuration,
      heightPerMinute: 3.0, // Match the DayView's heightPerMinute
      onEventMoved: (event, start, end) => _handleEventMoved(context, event, start, end),
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

  /// Handles when an event is moved to a new time
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
    print('Day view: Duplicate event called for ${event.title}');
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
    print('Day view: Delete event called for ${event.title}');
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
