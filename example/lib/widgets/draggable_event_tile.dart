import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

class DraggableEventTile<T> extends StatefulWidget {
  final DateTime date;
  final List<CalendarEventData<T>> events;
  final Rect boundary;
  final DateTime startDuration;
  final DateTime endDuration;
  final Function(CalendarEventData<T>, DateTime, DateTime)? onEventMoved;
  final Function(CalendarEventData<T>, DateTime, DateTime)? onEventResized;

  const DraggableEventTile({
    super.key,
    required this.date,
    required this.events,
    required this.boundary,
    required this.startDuration,
    required this.endDuration,
    this.onEventMoved,
    this.onEventResized,
  });

  @override
  State<DraggableEventTile<T>> createState() => _DraggableEventTileState<T>();
}

class _DraggableEventTileState<T> extends State<DraggableEventTile<T>> {
  bool _isDragging = false;
  bool _isResizing = false;
  Offset? _dragStartPosition;
  Offset? _currentDragPosition;
  DateTime? _dragStartTime;
  DateTime? _resizeStartTime;
  Offset? _currentResizePosition;

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    final event = widget.events.first;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onPanStart: (details) {
        _dragStartPosition = details.localPosition;
        _currentDragPosition = details.localPosition;
        _dragStartTime = widget.startDuration;
        setState(() {
          _isDragging = true;
        });
      },
      onPanUpdate: (details) {
        if (_isDragging && _dragStartPosition != null) {
          _currentDragPosition = details.localPosition;
          _handleDrag(details.localPosition);
        }
      },
      onPanEnd: (details) {
        if (_isDragging) {
          _finishDrag();
        }
      },
      child: Stack(
        children: [
          // Main event tile
          Container(
            width: widget.boundary.width,
            height: widget.boundary.height,
            decoration: BoxDecoration(
              color: _isDragging 
                  ? event.color.withValues(alpha: 0.7)
                  : event.color,
              borderRadius: BorderRadius.circular(8),
              border: _isDragging 
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
              boxShadow: _isDragging
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: event.titleStyle?.color ?? colorScheme.onPrimary,
                      fontSize: event.titleStyle?.fontSize ?? 14,
                      fontWeight: event.titleStyle?.fontWeight ?? FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.description != null && event.description!.isNotEmpty)
                    Text(
                      event.description!,
                      style: TextStyle(
                        color: event.descriptionStyle?.color ?? 
                               colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: event.descriptionStyle?.fontSize ?? 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          
          // Resize handle at the bottom
          if (widget.boundary.height > 30) // Only show resize handle for tall events
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onPanStart: (details) {
                  _resizeStartTime = widget.endDuration;
                  _currentResizePosition = details.localPosition;
                  setState(() {
                    _isResizing = true;
                  });
                },
                onPanUpdate: (details) {
                  if (_isResizing) {
                    _currentResizePosition = details.localPosition;
                    _handleResize(details.localPosition);
                  }
                },
                onPanEnd: (details) {
                  if (_isResizing) {
                    _finishResize();
                  }
                },
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isResizing 
                        ? colorScheme.primary
                        : colorScheme.onPrimary.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 2,
                      decoration: BoxDecoration(
                        color: _isResizing 
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleDrag(Offset currentPosition) {
    // Just update visual state, don't call the callback yet
    setState(() {
      // Visual feedback only - no event updates during drag
    });
  }

  void _handleResize(Offset currentPosition) {
    // Just update visual state, don't call the callback yet
    setState(() {
      // Visual feedback only - no event updates during resize
    });
  }

  void _finishDrag() {
    if (_dragStartPosition != null && _currentDragPosition != null && _dragStartTime != null) {
      // Calculate final position and update the event
      final deltaY = _currentDragPosition!.dy - _dragStartPosition!.dy;
      final minutesPerPixel = 1.0;
      final minutesDelta = (deltaY / minutesPerPixel).round();
      
      final newStartTime = _dragStartTime!.add(Duration(minutes: minutesDelta));
      final duration = widget.endDuration.difference(widget.startDuration);
      final newEndTime = newStartTime.add(duration);
      
      // Only call the callback once at the end
      widget.onEventMoved?.call(widget.events.first, newStartTime, newEndTime);
    }
    
    setState(() {
      _isDragging = false;
    });
    _dragStartPosition = null;
    _currentDragPosition = null;
    _dragStartTime = null;
  }

  void _finishResize() {
    if (_currentResizePosition != null && _resizeStartTime != null) {
      // Calculate final resize and update the event
      final deltaY = _currentResizePosition!.dy;
      final minutesPerPixel = 1.0;
      final minutesDelta = (deltaY / minutesPerPixel).round();
      
      final newEndTime = _resizeStartTime!.add(Duration(minutes: minutesDelta));
      
      // Ensure end time is after start time
      if (newEndTime.isAfter(widget.startDuration)) {
        // Only call the callback once at the end
        widget.onEventResized?.call(widget.events.first, widget.startDuration, newEndTime);
      }
    }
    
    setState(() {
      _isResizing = false;
    });
    _resizeStartTime = null;
    _currentResizePosition = null;
  }
}
