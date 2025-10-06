import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import '../extension.dart';
import '../widgets/add_free_time_form.dart';

class CreateFreeTimePage extends StatelessWidget {
  const CreateFreeTimePage({super.key, this.event, this.specificDate});

  final CalendarEventData? event;
  final DateTime? specificDate; // The specific date of the occurrence being edited

  @override
  Widget build(BuildContext context) {
    final themeColor = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(event != null ? 'Edit Free Time' : 'Create Free Time'),
        backgroundColor: themeColor.primary,
        foregroundColor: themeColor.onPrimary,
      ),
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: AddOrEditFreeTimeForm(
            onFreeTimeAdd: (newEvent) {
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
