// Copyright (c) 2021 Simform Solutions. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

part of 'event_arrangers.dart';

/// Event arranger that ensures events always span the full width of the screen.
/// When multiple events conflict, they divide the width equally among themselves.
class FullWidthEventArranger<T extends Object?> extends EventArranger<T> {
  /// This class will provide method that will arrange
  /// all the events to span the full width, dividing equally when conflicts occur.
  const FullWidthEventArranger({
    this.includeEdges = false,
  });

  /// Decides whether events that are overlapping on edge
  /// (ex, event1 has the same end-time as the start-time of event 2)
  /// should be offset or not.
  ///
  /// If includeEdges is true, it will offset the events else it will not.
  final bool includeEdges;

  @override
  List<OrganizedCalendarEventData<T>> arrange({
    required List<CalendarEventData<T>> events,
    required double height,
    required double width,
    required double heightPerMinute,
    required int startHour,
    required DateTime calendarViewDate,
  }) {
    if (events.isEmpty) return [];

    final startHourInMinutes = startHour * 60;
    final arrangedEvents = <OrganizedCalendarEventData<T>>[];

    // Group events by their time slots
    final eventGroups = <List<CalendarEventData<T>>>[];
    final processedEvents = <CalendarEventData<T>>{};

    for (final event in events) {
      if (processedEvents.contains(event)) continue;

      final group = <CalendarEventData<T>>[event];
      processedEvents.add(event);

      // Find all events that overlap with this event
      for (final otherEvent in events) {
        if (processedEvents.contains(otherEvent)) continue;

        if (_eventsOverlap(event, otherEvent, includeEdges)) {
          group.add(otherEvent);
          processedEvents.add(otherEvent);
        }
      }

      eventGroups.add(group);
    }

    // Arrange each group
    for (final group in eventGroups) {
      final groupArranged = _arrangeEventGroup(
        group,
        width,
        height,
        heightPerMinute,
        startHourInMinutes,
        calendarViewDate,
      );
      arrangedEvents.addAll(groupArranged);
    }

    return arrangedEvents;
  }

  List<OrganizedCalendarEventData<T>> _arrangeEventGroup(
    List<CalendarEventData<T>> events,
    double width,
    double height,
    double heightPerMinute,
    int startHourInMinutes,
    DateTime calendarViewDate,
  ) {
    final arranged = <OrganizedCalendarEventData<T>>[];
    final eventCount = events.length;

    for (int i = 0; i < eventCount; i++) {
      final event = events[i];
      final startTime = event.startTime!;
      final endTime = event.endTime!;

      int eventStart;
      int eventEnd;

      if (event.isRangingEvent) {
        // Handle multi-day events differently based on which day is currently being viewed
        final isStartDate = calendarViewDate.isAtSameMomentAs(event.date.withoutTime);
        final isEndDate = calendarViewDate.isAtSameMomentAs(event.endDate.withoutTime);

        if (isStartDate && isEndDate) {
          // Single day event with start and end time
          eventStart = startTime.getTotalMinutes - startHourInMinutes;
          eventEnd = endTime.getTotalMinutes - startHourInMinutes <= 0
              ? Constants.minutesADay - startHourInMinutes
              : endTime.getTotalMinutes - startHourInMinutes;
        } else if (isStartDate) {
          // First day - show from start time to end of day
          eventStart = startTime.getTotalMinutes - startHourInMinutes;
          eventEnd = Constants.minutesADay - startHourInMinutes;
        } else if (isEndDate) {
          // Last day - show from start of day to end time
          eventStart = 0;
          eventEnd = endTime.getTotalMinutes - startHourInMinutes <= 0
              ? Constants.minutesADay - startHourInMinutes
              : endTime.getTotalMinutes - startHourInMinutes;
        } else {
          // Middle days - show full day
          eventStart = 0;
          eventEnd = Constants.minutesADay - startHourInMinutes;
        }
      } else {
        // Single day event - use normal start/end times
        eventStart = startTime.getTotalMinutes - startHourInMinutes;
        eventEnd = endTime.getTotalMinutes - startHourInMinutes <= 0
            ? Constants.minutesADay - startHourInMinutes
            : endTime.getTotalMinutes - startHourInMinutes;
      }

      // Ensure values are within valid range
      eventStart = math.max(0, eventStart);
      eventEnd = math.min(Constants.minutesADay - startHourInMinutes, eventEnd);

      final top = eventStart * heightPerMinute;

      // Calculate visibleMinutes (the total minutes displayed in the view)
      final visibleMinutes = Constants.minutesADay - startHourInMinutes;

      // Check if event ends at or beyond the visible area
      final bottom = eventEnd >= visibleMinutes
          ? 0.0 // Event extends to bottom of view
          : height - eventEnd * heightPerMinute;

      // Calculate width division for this event
      final eventWidth = width / eventCount;
      final left = i * eventWidth;
      final right = width - (left + eventWidth);

      arranged.add(OrganizedCalendarEventData<T>(
        left: left,
        right: right,
        top: top,
        bottom: bottom,
        startDuration: startTime.copyFromMinutes(eventStart),
        endDuration: endTime.copyFromMinutes(eventEnd),
        events: [event],
        calendarViewDate: calendarViewDate,
      ));
    }

    return arranged;
  }

  bool _eventsOverlap(
    CalendarEventData<T> event1,
    CalendarEventData<T> event2,
    bool includeEdges,
  ) {
    final start1 = event1.startTime!.getTotalMinutes;
    final end1 = event1.endTime!.getTotalMinutes;
    final start2 = event2.startTime!.getTotalMinutes;
    final end2 = event2.endTime!.getTotalMinutes;

    if (includeEdges) {
      return (start1 <= end2 && end1 >= start2);
    } else {
      return (start1 < end2 && end1 > start2);
    }
  }
}
