import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

/// Represents a single event occurrence with all its properties
class EventModel {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime endDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String colorHex;
  final String? parentEventId; // For recurring events - links to the parent series
  final RecurrenceSettings? recurrenceSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.endDate,
    this.startTime,
    this.endTime,
    required this.colorHex,
    this.parentEventId,
    this.recurrenceSettings,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from CalendarEventData
  factory EventModel.fromCalendarEvent(CalendarEventData event, {String? parentEventId}) {
    return EventModel(
      id: _generateId(),
      title: event.title,
      description: event.description,
      date: event.date,
      endDate: event.endDate,
      startTime: event.startTime,
      endTime: event.endTime,
      colorHex: event.color.toARGB32().toRadixString(16).padLeft(8, '0'),
      parentEventId: parentEventId,
      recurrenceSettings: event.recurrenceSettings,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to CalendarEventData
  CalendarEventData toCalendarEvent() {
    return CalendarEventData(
      title: title,
      description: description,
      date: date,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      color: Color(int.parse(colorHex, radix: 16)),
      recurrenceSettings: recurrenceSettings,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'colorHex': colorHex,
      'parentEventId': parentEventId,
      'recurrenceSettings': recurrenceSettings != null ? {
        'frequency': recurrenceSettings!.frequency.index,
        'weekdays': recurrenceSettings!.weekdays,
        'endDate': recurrenceSettings!.endDate?.toIso8601String(),
        'occurrences': recurrenceSettings!.occurrences,
        'recurrenceEndOn': recurrenceSettings!.recurrenceEndOn.index,
        'excludeDates': recurrenceSettings!.excludeDates?.map((d) => d.toIso8601String()).toList(),
      } : null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      endDate: DateTime.parse(json['endDate']),
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      colorHex: json['colorHex'],
      parentEventId: json['parentEventId'],
      recurrenceSettings: json['recurrenceSettings'] != null ? RecurrenceSettings.withCalculatedEndDate(
        startDate: DateTime.parse(json['date']),
        frequency: RepeatFrequency.values[json['recurrenceSettings']['frequency']],
        weekdays: List<int>.from(json['recurrenceSettings']['weekdays']),
        endDate: json['recurrenceSettings']['endDate'] != null 
            ? DateTime.parse(json['recurrenceSettings']['endDate']) 
            : null,
        occurrences: json['recurrenceSettings']['occurrences'],
        recurrenceEndOn: RecurrenceEnd.values[json['recurrenceSettings']['recurrenceEndOn']],
      ) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Create a copy with updated fields
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? endDate,
    DateTime? startTime,
    DateTime? endTime,
    String? colorHex,
    String? parentEventId,
    RecurrenceSettings? recurrenceSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorHex: colorHex ?? this.colorHex,
      parentEventId: parentEventId ?? this.parentEventId,
      recurrenceSettings: recurrenceSettings ?? this.recurrenceSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Generate a unique ID
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
}

/// Represents a collection of events (for recurring events with modifications)
class EventCollection {
  final String id;
  final String name;
  final List<String> eventIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventCollection({
    required this.id,
    required this.name,
    required this.eventIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'eventIds': eventIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory EventCollection.fromJson(Map<String, dynamic> json) {
    return EventCollection(
      id: json['id'],
      name: json['name'],
      eventIds: List<String>.from(json['eventIds']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Create a copy with updated fields
  EventCollection copyWith({
    String? id,
    String? name,
    List<String>? eventIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      eventIds: eventIds ?? this.eventIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
