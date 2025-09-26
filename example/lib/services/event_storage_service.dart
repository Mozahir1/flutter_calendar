import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/event_model.dart';

/// Service for managing event storage using local JSON files
class EventStorageService {
  static const String _eventsFileName = 'events.json';
  static const String _collectionsFileName = 'event_collections.json';
  
  static EventStorageService? _instance;
  static EventStorageService get instance => _instance ??= EventStorageService._();
  
  EventStorageService._();

  /// Get the application documents directory
  Future<Directory> get _documentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get the events file path
  Future<File> get _eventsFile async {
    final directory = await _documentsDirectory;
    return File('${directory.path}/$_eventsFileName');
  }

  /// Get the collections file path
  Future<File> get _collectionsFile async {
    final directory = await _documentsDirectory;
    return File('${directory.path}/$_collectionsFileName');
  }

  /// Save all events to JSON file
  Future<void> saveEvents(List<EventModel> events) async {
    try {
      final file = await _eventsFile;
      final jsonString = jsonEncode(events.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving events: $e');
      rethrow;
    }
  }

  /// Load all events from JSON file
  Future<List<EventModel>> loadEvents() async {
    try {
      final file = await _eventsFile;
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => EventModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading events: $e');
      return [];
    }
  }

  /// Save all event collections to JSON file
  Future<void> saveCollections(List<EventCollection> collections) async {
    try {
      final file = await _collectionsFile;
      final jsonString = jsonEncode(collections.map((c) => c.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving collections: $e');
      rethrow;
    }
  }

  /// Load all event collections from JSON file
  Future<List<EventCollection>> loadCollections() async {
    try {
      final file = await _collectionsFile;
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
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

  /// Clear all data (for testing/reset purposes)
  Future<void> clearAllData() async {
    final eventsFile = await _eventsFile;
    final collectionsFile = await _collectionsFile;
    
    if (await eventsFile.exists()) {
      await eventsFile.delete();
    }
    if (await collectionsFile.exists()) {
      await collectionsFile.delete();
    }
  }

  /// Get storage statistics
  Future<Map<String, int>> getStorageStats() async {
    final events = await loadEvents();
    final collections = await loadCollections();
    
    return {
      'totalEvents': events.length,
      'recurringEvents': events.where((e) => e.recurrenceSettings != null).length,
      'singleEvents': events.where((e) => e.recurrenceSettings == null).length,
      'collections': collections.length,
    };
  }
}
