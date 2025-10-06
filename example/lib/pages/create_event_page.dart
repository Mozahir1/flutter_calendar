import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extension.dart';
import '../widgets/add_event_form.dart';
import '../widgets/edit_recurring_event_dialog.dart';
import '../controllers/enhanced_event_controller.dart';

class CreateEventPage extends StatelessWidget {
  const CreateEventPage({super.key, this.event, this.editType, this.specificDate});

  final CalendarEventData? event;
  final EditRecurringEventType? editType;
  final DateTime? specificDate; // The specific date of the occurrence being edited

  @override
  Widget build(BuildContext context) {
    final themeColor = context.appColors;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: context.pop,
          icon: Icon(
            Icons.arrow_back,
            color: themeColor.onPrimary,
          ),
        ),
        title: Text(
          event == null ? "Create New Event" : "Update Event",
          style: TextStyle(
            color: themeColor.onPrimary,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: AddOrEditEventForm(
            onEventAdd: (newEvent) async {
              final enhancedController = Provider.of<EnhancedEventController>(context, listen: false);
              final calendarController = CalendarControllerProvider.of(context).controller;
              
              if (this.event != null) {
                await _handleEventUpdate(context, newEvent, enhancedController, calendarController);
              } else {
                // Add to both enhanced controller (JSON storage) and calendar controller (display)
                await enhancedController.addEvent(newEvent);
                calendarController.add(newEvent);
              }

              context.pop(true);
            },
            event: event,
            specificDate: specificDate,
          ),
        ),
      ),
    );
  }

  /// Handles updating an event based on the edit type for recurring events
  Future<void> _handleEventUpdate(BuildContext context, CalendarEventData newEvent, 
      EnhancedEventController enhancedController, EventController calendarController) async {
    if (editType != null) {
      // Handle recurring event edit based on type
      switch (editType!) {
        case EditRecurringEventType.thisEvent:
          // Edit only this occurrence - create a new single event
          // Use the specific date of the occurrence being edited
          final singleEvent = CalendarEventData(
            date: specificDate ?? event!.date,  // Use specific date if available
            endDate: newEvent.endDate,
            startTime: newEvent.startTime,
            endTime: newEvent.endTime,
            title: newEvent.title,
            description: newEvent.description,
            color: newEvent.color,
            // No recurrence settings for single event
          );
          
          // Add to both controllers
          await enhancedController.addEvent(singleEvent);
          calendarController.add(singleEvent);
          
          // Delete the original occurrence from both controllers
          calendarController.deleteRecurrenceEvent(
            date: specificDate ?? event!.date,  // Use specific date if available
            event: event!,
            deleteEventType: DeleteEvent.current,
          );
          // Note: Enhanced controller doesn't have deleteRecurrenceEvent, 
          // so we'll need to implement that or handle it differently
          break;
          
        case EditRecurringEventType.thisAndFollowing:
          // Edit this and all following events
          // For now, we'll update the entire series and then delete past events
          // This is a simplified approach - in a real app you'd want more sophisticated logic
          await enhancedController.updateEventByProperties(event!, newEvent);
          calendarController.update(event!, newEvent);
          break;
          
        case EditRecurringEventType.allEvents:
          // Edit all events in the series
          await enhancedController.updateEventByProperties(event!, newEvent);
          calendarController.update(event!, newEvent);
          break;
      }
    } else {
      // Non-recurring event or no edit type specified
      await enhancedController.updateEventByProperties(event!, newEvent);
      calendarController.update(event!, newEvent);
    }
  }
}
