import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';

/// Universal storage service that works on both web (localStorage) and mobile (file system)
class UniversalStorageService {
  static const String _eventsKey = 'calendar_events';
  static const String _collectionsKey = 'calendar_collections';
  static const String _eventsFileName = 'events.json';
  static const String _collectionsFileName = 'event_collections.json';
  
  static UniversalStorageService? _instance;
  static UniversalStorageService get instance => _instance ??= UniversalStorageService._();
  
  UniversalStorageService._();

  /// Save all events
  Future<void> saveEvents(List<EventModel> events) async {
    final jsonString = jsonEncode(events.map((e) => e.toJson()).toList());
    
    if (kIsWeb) {
      html.window.localStorage[_eventsKey] = jsonString;
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_eventsFileName');
        await file.writeAsString(jsonString);
      } catch (e) {
        print('Error saving events to file: $e');
        rethrow;
      }
    }
  }

  /// Load all events
  Future<List<EventModel>> loadEvents() async {
    try {
      String? jsonString;
      
      if (kIsWeb) {
        jsonString = html.window.localStorage[_eventsKey];
      } else {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$_eventsFileName');
          if (await file.exists()) {
            jsonString = await file.readAsString();
          }
        } catch (e) {
          print('Error loading events from file: $e');
          return [];
        }
      }
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => EventModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading events: $e');
      return [];
    }
  }

  /// Save all event collections
  Future<void> saveCollections(List<EventCollection> collections) async {
    final jsonString = jsonEncode(collections.map((c) => c.toJson()).toList());
    
    if (kIsWeb) {
      html.window.localStorage[_collectionsKey] = jsonString;
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_collectionsFileName');
        await file.writeAsString(jsonString);
      } catch (e) {
        print('Error saving collections to file: $e');
        rethrow;
      }
    }
  }

  /// Load all event collections
  Future<List<EventCollection>> loadCollections() async {
    try {
      String? jsonString;
      
      if (kIsWeb) {
        jsonString = html.window.localStorage[_collectionsKey];
      } else {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$_collectionsFileName');
          if (await file.exists()) {
            jsonString = await file.readAsString();
          }
        } catch (e) {
          print('Error loading collections from file: $e');
          return [];
        }
      }
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => EventCollection.fromJson(json)).toList();
    } catch (e) {
      print('Error loading collections: $e');
      return [];
    }
  }

  /// Add a new event
  Future<void> addEvent(EventModel event) async {
    final events = await loadEvents();
    events.add(event);
    await saveEvents(events);
  }

  /// Update an existing event
  Future<void> updateEvent(EventModel event) async {
    final events = await loadEvents();
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      events[index] = event.copyWith(updatedAt: DateTime.now());
      await saveEvents(events);
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    final events = await loadEvents();
    events.removeWhere((e) => e.id == eventId);
    await saveEvents(events);
  }

  /// Get an event by ID
  Future<EventModel?> getEvent(String eventId) async {
    final events = await loadEvents();
    try {
      return events.firstWhere((e) => e.id == eventId);
    } catch (e) {
      return null;
    }
  }

  /// Get all events for a specific date
  Future<List<EventModel>> getEventsForDate(DateTime date) async {
    final events = await loadEvents();
    return events.where((e) => 
      e.date.year == date.year && 
      e.date.month == date.month && 
      e.date.day == date.day
    ).toList();
  }

  /// Get all events in a date range
  Future<List<EventModel>> getEventsInRange(DateTime startDate, DateTime endDate) async {
    final events = await loadEvents();
    return events.where((e) => 
      e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
      e.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  /// Get all events that are part of a recurring series
  Future<List<EventModel>> getRecurringEvents(String parentEventId) async {
    final events = await loadEvents();
    return events.where((e) => e.parentEventId == parentEventId).toList();
  }

  /// Add a new event collection
  Future<void> addCollection(EventCollection collection) async {
    final collections = await loadCollections();
    collections.add(collection);
    await saveCollections(collections);
  }

  /// Update an existing event collection
  Future<void> updateCollection(EventCollection collection) async {
    final collections = await loadCollections();
    final index = collections.indexWhere((c) => c.id == collection.id);
    if (index != -1) {
      collections[index] = collection.copyWith(updatedAt: DateTime.now());
      await saveCollections(collections);
    }
  }

  /// Delete an event collection
  Future<void> deleteCollection(String collectionId) async {
    final collections = await loadCollections();
    collections.removeWhere((c) => c.id == collectionId);
    await saveCollections(collections);
  }

  /// Get an event collection by ID
  Future<EventCollection?> getCollection(String collectionId) async {
    final collections = await loadCollections();
    try {
      return collections.firstWhere((c) => c.id == collectionId);
    } catch (e) {
      return null;
    }
  }

  /// Get storage statistics
  Future<Map<String, int>> getStorageStats() async {
    final events = await loadEvents();
    final collections = await loadCollections();
    
    return {
      'totalEvents': events.length,
      'totalCollections': collections.length,
      'recurringEvents': events.where((e) => e.recurrenceSettings != null).length,
      'fullDayEvents': events.where((e) => e.startTime == null).length,
    };
  }

  /// Clear all data (for testing/reset purposes)
  Future<void> clearAllData() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_eventsKey);
      html.window.localStorage.remove(_collectionsKey);
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final eventsFile = File('${directory.path}/$_eventsFileName');
        final collectionsFile = File('${directory.path}/$_collectionsFileName');
        
        if (await eventsFile.exists()) {
          await eventsFile.delete();
        }
        if (await collectionsFile.exists()) {
          await collectionsFile.delete();
        }
      } catch (e) {
        print('Error clearing data: $e');
      }
    }
  }

  /// Export all data as JSON string
  Future<String> exportAllData() async {
    final events = await loadEvents();
    final collections = await loadCollections();
    
    final exportData = {
      'events': events.map((e) => e.toJson()).toList(),
      'collections': collections.map((c) => c.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Import data from JSON string
  Future<void> importData(String jsonString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      if (data['events'] != null) {
        final List<EventModel> events = (data['events'] as List)
            .map((json) => EventModel.fromJson(json))
            .toList();
        await saveEvents(events);
      }
      
      if (data['collections'] != null) {
        final List<EventCollection> collections = (data['collections'] as List)
            .map((json) => EventCollection.fromJson(json))
            .toList();
        await saveCollections(collections);
      }
    } catch (e) {
      print('Error importing data: $e');
      rethrow;
    }
  }
}
