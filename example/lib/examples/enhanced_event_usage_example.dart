import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import '../controllers/enhanced_event_controller.dart';
import '../models/event_model.dart';
import '../widgets/edit_recurring_event_dialog.dart';
import '../pages/json_viewer_page.dart';

/// Example of how to use the new enhanced event system
class EnhancedEventUsageExample extends StatefulWidget {
  const EnhancedEventUsageExample({super.key});

  @override
  State<EnhancedEventUsageExample> createState() => _EnhancedEventUsageExampleState();
}

class _EnhancedEventUsageExampleState extends State<EnhancedEventUsageExample> {
  final EnhancedEventController _controller = EnhancedEventController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Event System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showStorageStats,
          ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: _openJsonViewer,
          ),
        ],
      ),
      body: Column(
        children: [
          // Storage stats
          Container(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<Map<String, int>>(
              future: _controller.getStorageStats(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Storage Statistics', 
                            style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('Total Events: ${stats['totalEvents']}'),
                          Text('Recurring Events: ${stats['recurringEvents']}'),
                          Text('Single Events: ${stats['singleEvents']}'),
                          Text('Collections: ${stats['collections']}'),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          
          // Event list
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ListView.builder(
                  itemCount: _controller.events.length,
                  itemBuilder: (context, index) {
                    final event = _controller.events[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(event.title),
                        subtitle: Text('${event.date.day}/${event.date.month}/${event.date.year}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (event.recurrenceSettings != null)
                              const Icon(Icons.repeat, size: 16),
                            if (event.parentEventId != null)
                              const Icon(Icons.link, size: 16),
                            PopupMenuButton<String>(
                              onSelected: (value) => _handleEventAction(value, event),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSampleEvent,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showStorageStats() {
    _controller.getStorageStats().then((stats) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Events: ${stats['totalEvents']}'),
              Text('Recurring Events: ${stats['recurringEvents']}'),
              Text('Single Events: ${stats['singleEvents']}'),
              Text('Collections: ${stats['collections']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }

  void _openJsonViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const JsonViewerPage(),
      ),
    );
  }

  void _handleEventAction(String action, EventModel event) {
    switch (action) {
      case 'edit':
        _editEvent(event);
        break;
      case 'delete':
        _deleteEvent(event);
        break;
    }
  }

  void _editEvent(EventModel event) {
    if (event.recurrenceSettings != null) {
      // Show recurring event edit dialog
      showDialog<EditRecurringEventType>(
        context: context,
        builder: (context) => EditRecurringEventDialog(
          event: event.toCalendarEvent(),
        ),
      ).then((editType) {
        if (editType != null) {
          _handleRecurringEventEdit(event, editType);
        }
      });
    } else {
      // Edit single event
      _editSingleEvent(event);
    }
  }

  void _handleRecurringEventEdit(EventModel event, EditRecurringEventType editType) {
    // In a real app, you would open an edit form here
    // For this example, we'll just show a message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Recurring Event'),
        content: Text('Edit type: ${editType.name}\nEvent: ${event.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editSingleEvent(EventModel event) {
    // In a real app, you would open an edit form here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Event'),
        content: Text('Event: ${event.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteEvent(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _controller.deleteEvent(event.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addSampleEvent() {
    final sampleEvent = CalendarEventData(
      title: 'Sample Event ${DateTime.now().millisecondsSinceEpoch}',
      description: 'This is a sample event created at ${DateTime.now()}',
      date: DateTime.now(),
      endDate: DateTime.now(),
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      color: Colors.blue,
    );

    _controller.addEvent(sampleEvent);
  }
}
