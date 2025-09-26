# Enhanced Event Storage System

This document describes the new JSON-based event storage system that provides better management of recurring events and individual event modifications.

## Overview

The enhanced event system consists of:

1. **EventModel** - A data model that represents individual events with full JSON serialization
2. **EventCollection** - A model for grouping related events (useful for recurring events with modifications)
3. **EventStorageService** - A service that handles local JSON file storage
4. **EnhancedEventController** - A controller that manages events using the new storage system

## Key Benefits

- **Proper Recurring Event Handling**: Each occurrence can be individually modified
- **JSON Storage**: Events are stored in human-readable JSON format
- **Collections Support**: Related events can be grouped together
- **Isolated Properties**: Individual event properties can be modified without affecting the entire series
- **Persistent Storage**: Events are saved locally and persist between app sessions

## File Structure

```
lib/
├── models/
│   └── event_model.dart          # Event and collection data models
├── services/
│   └── event_storage_service.dart # JSON storage service
├── controllers/
│   └── enhanced_event_controller.dart # Enhanced event controller
└── examples/
    └── enhanced_event_usage_example.dart # Usage example
```

## Usage

### 1. Initialize the Controller

```dart
final controller = EnhancedEventController();
await controller.initialize();
```

### 2. Add Events

```dart
final event = CalendarEventData(
  title: 'Meeting',
  date: DateTime.now(),
  endDate: DateTime.now(),
  startTime: DateTime.now(),
  endTime: DateTime.now().add(Duration(hours: 1)),
  color: Colors.blue,
);

await controller.addEvent(event);
```

### 3. Edit Recurring Events

```dart
await controller.editRecurringEvent(
  eventId: 'event_id',
  updatedEvent: updatedCalendarEvent,
  editType: EditRecurringEventType.thisEvent, // or .thisAndFollowing, .allEvents
  specificDate: DateTime(2024, 3, 15), // The specific occurrence date
);
```

### 4. Query Events

```dart
// Get events for a specific date
final eventsForDate = controller.getEventsForDate(DateTime(2024, 3, 15));

// Get events in a date range
final eventsInRange = controller.getEventsInRange(
  DateTime(2024, 3, 1),
  DateTime(2024, 3, 31),
);
```

## Recurring Event Handling

The system handles recurring events in three ways:

### 1. Edit Single Occurrence (`EditRecurringEventType.thisEvent`)

- Creates a new single event for the specific occurrence
- Links it to the original recurring event via `parentEventId`
- Adds the specific date to the original event's `excludeDates`
- The original recurring event continues for all other dates

### 2. Edit This and Following (`EditRecurringEventType.thisAndFollowing`)

- Updates the original recurring event with new settings
- Modifies the recurrence pattern from the specific date forward
- Previous occurrences remain unchanged

### 3. Edit All Occurrences (`EditRecurringEventType.allEvents`)

- Updates the entire recurring event series
- All occurrences are modified with the new settings

## Data Storage

Events are stored in two JSON files:

- `events.json` - Contains all individual events
- `event_collections.json` - Contains event collections (for grouping related events)

### Example Event JSON

```json
{
  "id": "1234567890123",
  "title": "Team Meeting",
  "description": "Weekly team sync",
  "date": "2024-03-15T00:00:00.000Z",
  "endDate": "2024-03-15T00:00:00.000Z",
  "startTime": "2024-03-15T10:00:00.000Z",
  "endTime": "2024-03-15T11:00:00.000Z",
  "colorHex": "ff2196f3",
  "parentEventId": "1234567890000",
  "recurrenceSettings": {
    "frequency": 2,
    "weekdays": [1, 3, 5],
    "endDate": "2024-12-31T00:00:00.000Z",
    "occurrences": null,
    "recurrenceEndOn": 1
  },
  "createdAt": "2024-03-15T09:00:00.000Z",
  "updatedAt": "2024-03-15T09:00:00.000Z"
}
```

## Migration from Old System

To migrate from the old event system:

1. Replace `EventController` with `EnhancedEventController`
2. Update event creation/editing to use the new methods
3. The new system is backward compatible with `CalendarEventData`

## Example Integration

See `enhanced_event_usage_example.dart` for a complete example of how to integrate the new system into your app.

## Benefits for Recurring Event Editing

- **Isolated Changes**: Modifying one occurrence doesn't affect others
- **Clear Data Structure**: Each event has a unique ID and clear relationships
- **Flexible Editing**: Support for editing single occurrences, ranges, or entire series
- **Persistent Storage**: All changes are automatically saved to JSON files
- **Easy Debugging**: JSON files can be inspected and modified manually if needed
