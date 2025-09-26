import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/event_storage_service.dart';
import '../widgets/json_viewer.dart';
import '../models/event_model.dart';

/// Page for viewing JSON storage data
class JsonViewerPage extends StatefulWidget {
  const JsonViewerPage({super.key});

  @override
  State<JsonViewerPage> createState() => _JsonViewerPageState();
}

class _JsonViewerPageState extends State<JsonViewerPage> {
  final EventStorageService _storage = EventStorageService.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _collections = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load events and convert to JSON
      final eventModels = await _storage.loadEvents();
      _events = eventModels.map((e) => e.toJson()).toList();

      // Load collections and convert to JSON
      final collectionModels = await _storage.loadCollections();
      _collections = collectionModels.map((c) => c.toJson()).toList();

      // Get storage stats
      _stats = await _storage.getStorageStats();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Storage Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addMockEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage Statistics
                    Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Storage Statistics',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard('Total Events', _stats['totalEvents'] ?? 0),
                                _buildStatCard('Recurring Events', _stats['recurringEvents'] ?? 0),
                                _buildStatCard('Single Events', _stats['singleEvents'] ?? 0),
                                _buildStatCard('Collections', _stats['collections'] ?? 0),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Events JSON
                    if (_events.isNotEmpty)
                      JsonListViewer(
                        jsonList: _events,
                        title: 'Events (${_events.length} items)',
                      )
                    else
                      Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.event_note, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                'No Events Found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _addMockEvents,
                                child: const Text('Add Mock Events'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Collections JSON
                    if (_collections.isNotEmpty)
                      JsonListViewer(
                        jsonList: _collections,
                        title: 'Collections (${_collections.length} items)',
                      )
                    else
                      Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.folder, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                'No Collections Found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Raw JSON Export
                    Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: const Text('Export All Data'),
                            subtitle: const Text('Copy all JSON data to clipboard'),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: _exportAllData,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _addMockEvents() async {
    try {
      // Add some mock events
      final mockEvents = [
        {
          'title': 'Team Meeting',
          'description': 'Weekly team sync meeting',
          'date': DateTime.now().toIso8601String(),
          'endDate': DateTime.now().toIso8601String(),
          'startTime': DateTime.now().toIso8601String(),
          'endTime': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          'colorHex': 'ff2196f3',
          'recurrenceSettings': {
            'frequency': 2, // Weekly
            'weekdays': [1, 3, 5], // Mon, Wed, Fri
            'endDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            'occurrences': null,
            'recurrenceEndOn': 1,
          },
        },
        {
          'title': 'Doctor Appointment',
          'description': 'Annual checkup',
          'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'endDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'startTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'endTime': DateTime.now().add(const Duration(days: 1, hours: 1)).toIso8601String(),
          'colorHex': 'ff4caf50',
          'recurrenceSettings': null,
        },
        {
          'title': 'Project Deadline',
          'description': 'Final project submission',
          'date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'endDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'startTime': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'endTime': DateTime.now().add(const Duration(days: 7, hours: 2)).toIso8601String(),
          'colorHex': 'ffff5722',
          'recurrenceSettings': null,
        },
      ];

      for (final eventData in mockEvents) {
        final event = {
          'id': DateTime.now().millisecondsSinceEpoch.toString() + 
                 (DateTime.now().microsecond % 1000).toString().padLeft(3, '0'),
          'title': eventData['title'],
          'description': eventData['description'],
          'date': eventData['date'],
          'endDate': eventData['endDate'],
          'startTime': eventData['startTime'],
          'endTime': eventData['endTime'],
          'colorHex': eventData['colorHex'],
          'parentEventId': null,
          'recurrenceSettings': eventData['recurrenceSettings'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final eventModel = EventModel.fromJson(event);
        await _storage.addEvent(eventModel);
      }

      // Reload data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mock events added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding mock events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAllData() async {
    try {
      final allData = {
        'events': _events,
        'collections': _collections,
        'stats': _stats,
        'exportedAt': DateTime.now().toIso8601String(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(allData);
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
