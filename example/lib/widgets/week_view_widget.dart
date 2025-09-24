import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import '../pages/event_details_page.dart';
import '../pages/create_event_page.dart';
import '../extension.dart';

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
      timeLineWidth: 65,
      scrollPhysics: const BouncingScrollPhysics(),
      liveTimeIndicatorSettings: LiveTimeIndicatorSettings(
        color: Colors.redAccent,
        showTime: true,
      ),
      onTimestampTap: (date) {
        SnackBar snackBar = SnackBar(
          content: Text("On tap: ${date.hour} Hr : ${date.minute} Min"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      onEventTap: (events, date) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailsPage(
              event: events.first,
              date: date,
            ),
          ),
        );
      },
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
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Event', style: TextStyle(color: Colors.red)),
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
              onPressed: () {
                CalendarControllerProvider.of(context).controller.remove(event);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Event "${event.title}" deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
