import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';

/// Custom event arranger that allows free time events to overlap with regular events
class FreeTimeEventArranger<T extends Object?> extends EventArranger<T> {
  const FreeTimeEventArranger({
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
    required double width,
    required double height,
    required double heightPerMinute,
    required int startHour,
    required DateTime calendarViewDate,
  }) {
    if (events.isEmpty) return [];

    final startHourInMinutes = startHour * 60;
    final arrangedEvents = <OrganizedCalendarEventData<T>>[];

    // Separate free time events from regular events
    final freeTimeEvents = <CalendarEventData<T>>[];
    final regularEvents = <CalendarEventData<T>>[];

    for (final event in events) {
      if (_isFreeTimeEvent(event)) {
        freeTimeEvents.add(event);
      } else {
        regularEvents.add(event);
      }
    }

    // First, arrange regular events using the standard logic
    final regularArranged = _arrangeRegularEvents(
      regularEvents,
      width,
      height,
      heightPerMinute,
      startHourInMinutes,
      calendarViewDate,
    );

    // Then, add free time events on top (they can overlap)
    final freeTimeArranged = _arrangeFreeTimeEvents(
      freeTimeEvents,
      width,
      height,
      heightPerMinute,
      startHourInMinutes,
      calendarViewDate,
    );

    arrangedEvents.addAll(regularArranged);
    arrangedEvents.addAll(freeTimeArranged);

    return arrangedEvents;
  }

  /// Check if an event is a free time event
  bool _isFreeTimeEvent(CalendarEventData<T> event) {
    // Free time events have the title "Free Time" and transparent green color
    return event.title == 'Free Time' && 
           event.color == Colors.green.withOpacity(0.3);
  }

  /// Arrange regular events using standard overlap detection
  List<OrganizedCalendarEventData<T>> _arrangeRegularEvents(
    List<CalendarEventData<T>> events,
    double width,
    double height,
    double heightPerMinute,
    int startHourInMinutes,
    DateTime calendarViewDate,
  ) {
    if (events.isEmpty) return [];

    // Group events by their time slots (standard logic)
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
    final arrangedEvents = <OrganizedCalendarEventData<T>>[];
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

  /// Arrange free time events (they can overlap with everything)
  List<OrganizedCalendarEventData<T>> _arrangeFreeTimeEvents(
    List<CalendarEventData<T>> events,
    double width,
    double height,
    double heightPerMinute,
    int startHourInMinutes,
    DateTime calendarViewDate,
  ) {
    final arrangedEvents = <OrganizedCalendarEventData<T>>[];

    for (final event in events) {
      final startTime = event.startTime!;
      final endTime = event.endTime!;

      int eventStart = startTime.getTotalMinutes - startHourInMinutes;
      int eventEnd = endTime.getTotalMinutes - startHourInMinutes;

      // Handle edge cases
      if (eventStart < 0) {
        eventStart = 0;
      }
      if (eventEnd <= 0) {
        eventEnd = endTime.getTotalMinutes == 0
            ? 1440 - startHourInMinutes
            : endTime.getTotalMinutes - startHourInMinutes;
      }

      // Ensure values are within valid range
      eventStart = math.max(0, eventStart);
      eventEnd = math.min(1440 - startHourInMinutes, eventEnd);

      final top = eventStart * heightPerMinute;

      // Calculate visibleMinutes (the total minutes displayed in the view)
      final visibleMinutes = 1440 - startHourInMinutes;

      // Check if event ends at or beyond the visible area
      final bottom = eventEnd >= visibleMinutes
          ? 0.0 // Event extends to bottom of view
          : height - eventEnd * heightPerMinute;

      // Free time events take full width and can overlap
      arrangedEvents.add(OrganizedCalendarEventData<T>(
        left: 0,
        right: 0,
        top: top,
        bottom: bottom,
        startDuration: startTime.copyFromMinutes(eventStart),
        endDuration: endTime.copyFromMinutes(eventEnd),
        events: [event],
        calendarViewDate: calendarViewDate,
      ));
    }

    return arrangedEvents;
  }

  /// Arrange a group of overlapping regular events
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

      int eventStart = startTime.getTotalMinutes - startHourInMinutes;
      int eventEnd = endTime.getTotalMinutes - startHourInMinutes;

      // Handle edge cases
      if (eventStart < 0) {
        eventStart = 0;
      }
      if (eventEnd <= 0) {
        eventEnd = endTime.getTotalMinutes == 0
            ? 1440 - startHourInMinutes
            : endTime.getTotalMinutes - startHourInMinutes;
      }

      // Ensure values are within valid range
      eventStart = math.max(0, eventStart);
      eventEnd = math.min(1440 - startHourInMinutes, eventEnd);

      final top = eventStart * heightPerMinute;

      // Calculate visibleMinutes (the total minutes displayed in the view)
      final visibleMinutes = 1440 - startHourInMinutes;

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

  /// Check if two events overlap (for regular events only)
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
