import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import '../extension.dart';
import '../widgets/add_event_form.dart';
import '../widgets/edit_recurring_event_dialog.dart';

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
            onEventAdd: (newEvent) {
              CalendarControllerProvider.of(context).controller.add(newEvent);
              context.pop(true);
            },
            event: event,
            specificDate: specificDate,
          ),
        ),
      ),
    );
  }

}
