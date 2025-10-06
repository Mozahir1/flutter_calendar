import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/universal_storage_service.dart';

/// Simple page for viewing raw JSON data as text
class SimpleJsonViewerPage extends StatefulWidget {
  const SimpleJsonViewerPage({super.key});

  @override
  State<SimpleJsonViewerPage> createState() => _SimpleJsonViewerPageState();
}

class _SimpleJsonViewerPageState extends State<SimpleJsonViewerPage> {
  final UniversalStorageService _storage = UniversalStorageService.instance;
  
  bool _isLoading = true;
  String _eventsJson = '';
  String _collectionsJson = '';

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
      // Load events and convert to pretty JSON
      final eventModels = await _storage.loadEvents();
      final eventsJsonList = eventModels.map((e) => e.toJson()).toList();
      _eventsJson = const JsonEncoder.withIndent('  ').convert(eventsJsonList);

      // Load collections and convert to pretty JSON
      final collectionModels = await _storage.loadCollections();
      final collectionsJsonList = collectionModels.map((c) => c.toJson()).toList();
      _collectionsJson = const JsonEncoder.withIndent('  ').convert(collectionsJsonList);
    } catch (e) {
      _eventsJson = 'Error loading events: $e';
      _collectionsJson = 'Error loading collections: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Database'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'Events'),
                      Tab(text: 'Collections'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Events Tab
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Events (${_eventsJson == '[]' ? 0 : _eventsJson.split('\n').length} lines)',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => _copyToClipboard(_eventsJson),
                                    icon: const Icon(Icons.copy),
                                    tooltip: 'Copy to clipboard',
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(16.0),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade50,
                                ),
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    _eventsJson.isEmpty ? 'No events found' : _eventsJson,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Collections Tab
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Collections (${_collectionsJson == '[]' ? 0 : _collectionsJson.split('\n').length} lines)',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => _copyToClipboard(_collectionsJson),
                                    icon: const Icon(Icons.copy),
                                    tooltip: 'Copy to clipboard',
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(16.0),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade50,
                                ),
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    _collectionsJson.isEmpty ? 'No collections found' : _collectionsJson,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
