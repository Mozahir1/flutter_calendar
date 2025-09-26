import 'dart:convert';
import 'package:flutter/material.dart';

/// A widget for displaying JSON data in a formatted, readable way
class JsonViewer extends StatefulWidget {
  final Map<String, dynamic> jsonData;
  final String title;
  final bool isExpanded;

  const JsonViewer({
    super.key,
    required this.jsonData,
    required this.title,
    this.isExpanded = false,
  });

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.jsonData.length} items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  _formatJson(widget.jsonData),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}

/// A widget for displaying a list of JSON objects
class JsonListViewer extends StatefulWidget {
  final List<Map<String, dynamic>> jsonList;
  final String title;

  const JsonListViewer({
    super.key,
    required this.jsonList,
    required this.title,
  });

  @override
  State<JsonListViewer> createState() => _JsonListViewerState();
}

class _JsonListViewerState extends State<JsonListViewer> {
  final Map<int, bool> _expandedItems = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('${widget.jsonList.length} items'),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.jsonList.length,
            itemBuilder: (context, index) {
              final item = widget.jsonList[index];
              final isExpanded = _expandedItems[index] ?? false;
              
              return Column(
                children: [
                  ListTile(
                    title: Text('Item ${index + 1}'),
                    subtitle: Text(_getItemSummary(item)),
                    trailing: IconButton(
                      icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () {
                        setState(() {
                          _expandedItems[index] = !isExpanded;
                        });
                      },
                    ),
                  ),
                  if (isExpanded) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SelectableText(
                        _formatJson(item),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getItemSummary(Map<String, dynamic> item) {
    // Try to get a meaningful summary from common fields
    if (item.containsKey('title')) {
      return item['title'].toString();
    } else if (item.containsKey('name')) {
      return item['name'].toString();
    } else if (item.containsKey('id')) {
      return 'ID: ${item['id']}';
    } else {
      return '${item.keys.length} fields';
    }
  }

  String _formatJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
