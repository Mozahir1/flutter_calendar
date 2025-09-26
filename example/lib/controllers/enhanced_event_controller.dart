import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_storage_service.dart';
import '../widgets/edit_recurring_event_dialog.dart';

/// Enhanced event controller that uses JSON storage for better event management
class EnhancedEventController extends ChangeNotifier {
  final EventStorageService _storage = EventStorageService.instance;
  
  List<EventModel> _events = [];
  List<EventCollection> _collections = [];
  bool _isLoading = false;

  List<EventModel> get events => List.unmodifiable(_events);
  List<EventCollection> get collections => List.unmodifiable(_collections);
  bool get isLoading => _isLoading;

  /// Initialize the controller by loading events from storage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _events = await _storage.loadEvents();
      _collections = await _storage.loadCollections();
    } catch (e) {
      print('Error initializing event controller: $e');
      _events = [];
      _collections = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new event
  Future<void> addEvent(CalendarEventData event) async {
    try {
      final eventModel = EventModel.fromCalendarEvent(event);
      await _storage.addEvent(eventModel);
      _events.add(eventModel);
      notifyListeners();
    } catch (e) {
      print('Error adding event: $e');
      rethrow;
    }
  }

  /// Update an existing event
  Future<void> updateEvent(String eventId, CalendarEventData updatedEvent) async {
    try {
      final existingEvent = _events.firstWhere((e) => e.id == eventId);
      final updatedModel = existingEvent.copyWith(
        title: updatedEvent.title,
        description: updatedEvent.description,
        date: updatedEvent.date,
        endDate: updatedEvent.endDate,
        startTime: updatedEvent.startTime,
        endTime: updatedEvent.endTime,
        colorHex: updatedEvent.color.toARGB32().toRadixString(16).padLeft(8, '0'),
        recurrenceSettings: updatedEvent.recurrenceSettings,
        updatedAt: DateTime.now(),
      );
      
      await _storage.updateEvent(updatedModel);
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        _events[index] = updatedModel;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _storage.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  /// Get events for a specific date
  List<CalendarEventData> getEventsForDate(DateTime date) {
    final eventsForDate = _events.where((e) => 
      e.date.year == date.year && 
      e.date.month == date.month && 
      e.date.day == date.day
    ).toList();
    
    return eventsForDate.map((e) => e.toCalendarEvent()).toList();
  }

  /// Get events in a date range
  List<CalendarEventData> getEventsInRange(DateTime startDate, DateTime endDate) {
    final eventsInRange = _events.where((e) => 
      e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
      e.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
    
    return eventsInRange.map((e) => e.toCalendarEvent()).toList();
  }

  /// Handle recurring event editing
  Future<void> editRecurringEvent({
    required String eventId,
    required CalendarEventData updatedEvent,
    required EditRecurringEventType editType,
    required DateTime specificDate,
  }) async {
    try {
      final originalEvent = _events.firstWhere((e) => e.id == eventId);
      
      switch (editType) {
        case EditRecurringEventType.thisEvent:
          await _editSingleOccurrence(originalEvent, updatedEvent, specificDate);
          break;
        case EditRecurringEventType.thisAndFollowing:
          await _editThisAndFollowing(originalEvent, updatedEvent, specificDate);
          break;
        case EditRecurringEventType.allEvents:
          await _editAllOccurrences(originalEvent, updatedEvent);
          break;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error editing recurring event: $e');
      rethrow;
    }
  }

  /// Edit only a single occurrence of a recurring event
  Future<void> _editSingleOccurrence(
    EventModel originalEvent, 
    CalendarEventData updatedEvent, 
    DateTime specificDate
  ) async {
    // Create a new single event for this specific occurrence
    final singleEvent = EventModel(
      id: _generateId(),
      title: updatedEvent.title,
      description: updatedEvent.description,
      date: specificDate, // Use the specific date, not the updated event's date
      endDate: updatedEvent.endDate,
      startTime: updatedEvent.startTime,
      endTime: updatedEvent.endTime,
        colorHex: updatedEvent.color.toARGB32().toRadixString(16).padLeft(8, '0'),
      parentEventId: originalEvent.id, // Link to the original recurring event
      recurrenceSettings: null, // No recurrence for single occurrence
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Add the new single event
    await _storage.addEvent(singleEvent);
    _events.add(singleEvent);
    
    // Add the specific date to the original event's exclude dates
    final excludeDates = originalEvent.recurrenceSettings?.excludeDates ?? [];
    excludeDates.add(specificDate);
    
    final updatedOriginal = originalEvent.copyWith(
      recurrenceSettings: originalEvent.recurrenceSettings?.copyWith(
        excludeDates: excludeDates,
      ),
      updatedAt: DateTime.now(),
    );
    
    await _storage.updateEvent(updatedOriginal);
    final index = _events.indexWhere((e) => e.id == originalEvent.id);
    if (index != -1) {
      _events[index] = updatedOriginal;
    }
  }

  /// Edit this occurrence and all following occurrences
  Future<void> _editThisAndFollowing(
    EventModel originalEvent, 
    CalendarEventData updatedEvent, 
    DateTime specificDate
  ) async {
    // Update the original event with new settings
    final updatedOriginal = originalEvent.copyWith(
      title: updatedEvent.title,
      description: updatedEvent.description,
      startTime: updatedEvent.startTime,
      endTime: updatedEvent.endTime,
        colorHex: updatedEvent.color.toARGB32().toRadixString(16).padLeft(8, '0'),
      recurrenceSettings: updatedEvent.recurrenceSettings,
      updatedAt: DateTime.now(),
    );
    
    await _storage.updateEvent(updatedOriginal);
    final index = _events.indexWhere((e) => e.id == originalEvent.id);
    if (index != -1) {
      _events[index] = updatedOriginal;
    }
    
    // TODO: Implement logic to handle "this and following" properly
    // This might involve creating a new recurring series starting from the specific date
  }

  /// Edit all occurrences of a recurring event
  Future<void> _editAllOccurrences(
    EventModel originalEvent, 
    CalendarEventData updatedEvent
  ) async {
    final updatedOriginal = originalEvent.copyWith(
      title: updatedEvent.title,
      description: updatedEvent.description,
      date: updatedEvent.date,
      endDate: updatedEvent.endDate,
      startTime: updatedEvent.startTime,
      endTime: updatedEvent.endTime,
        colorHex: updatedEvent.color.toARGB32().toRadixString(16).padLeft(8, '0'),
      recurrenceSettings: updatedEvent.recurrenceSettings,
      updatedAt: DateTime.now(),
    );
    
    await _storage.updateEvent(updatedOriginal);
    final index = _events.indexWhere((e) => e.id == originalEvent.id);
    if (index != -1) {
      _events[index] = updatedOriginal;
    }
  }

  /// Create an event collection for related events
  Future<void> createEventCollection(String name, List<String> eventIds) async {
    try {
      final collection = EventCollection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        eventIds: eventIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _storage.addCollection(collection);
      _collections.add(collection);
      notifyListeners();
    } catch (e) {
      print('Error creating event collection: $e');
      rethrow;
    }
  }

  /// Get events in a collection
  List<CalendarEventData> getEventsInCollection(String collectionId) {
    final collection = _collections.firstWhere((c) => c.id == collectionId);
    final eventsInCollection = _events.where((e) => collection.eventIds.contains(e.id)).toList();
    return eventsInCollection.map((e) => e.toCalendarEvent()).toList();
  }

  /// Get storage statistics
  Future<Map<String, int>> getStorageStats() async {
    return await _storage.getStorageStats();
  }

  /// Clear all data (for testing/reset purposes)
  Future<void> clearAllData() async {
    await _storage.clearAllData();
    _events.clear();
    _collections.clear();
    notifyListeners();
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
}
