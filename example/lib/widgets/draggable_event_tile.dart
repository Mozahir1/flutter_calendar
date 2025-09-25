import 'dart:async';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

class DraggableEventTile<T> extends StatefulWidget {
  final DateTime date;
  final List<CalendarEventData<T>> events;
  final Rect boundary;
  final DateTime startDuration;
  final DateTime endDuration;
  final double heightPerMinute;
  final Function(CalendarEventData<T>, DateTime, DateTime)? onEventMoved;
  final Function(CalendarEventData<T>, DateTime, DateTime)? onEventResized;
  final Function(CalendarEventData<T>, DateTime)? onEventTap;
  
  // Week view specific parameters for cross-day dragging
  final double? dayWidth; // Width of each day column in week view
  final List<DateTime>? weekDates; // List of dates in the current week
  final Function(CalendarEventData<T>, DateTime, DateTime, DateTime)? onEventMovedToDay; // Callback for cross-day moves

  const DraggableEventTile({
    super.key,
    required this.date,
    required this.events,
    required this.boundary,
    required this.startDuration,
    required this.endDuration,
    required this.heightPerMinute,
    this.onEventMoved,
    this.onEventResized,
    this.onEventTap,
    this.dayWidth,
    this.weekDates,
    this.onEventMovedToDay,
  });

  @override
  State<DraggableEventTile<T>> createState() => _DraggableEventTileState<T>();
}

class _DraggableEventTileState<T> extends State<DraggableEventTile<T>> {
  bool _isDragging = false;
  bool _isResizing = false;
  Offset? _dragStartPosition;
  DateTime? _dragStartTime;
  
  // Real-time drag state
  Offset? _dragOffset;
  
  // Drop preview state
  bool _showDropPreview = false;
  Offset? _previewPosition;
  DateTime? _previewStartTime;
  DateTime? _previewEndTime;
  DateTime? _previewDate;
  Timer? _hoverTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    final event = widget.events.first;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        // Tap opens edit menu
        widget.onEventTap?.call(widget.events.first, widget.date);
      },
      onLongPressStart: (details) {
        // Long press starts drag mode
        _dragStartPosition = details.localPosition;
        _dragStartTime = widget.startDuration;
        setState(() {
          _isDragging = true;
        });
      },
      onLongPressMoveUpdate: (details) {
        if (_isDragging && _dragStartPosition != null) {
          _handleDrag(details.localPosition);
        }
      },
      onLongPressEnd: (details) {
        if (_isDragging) {
          _finishDrag();
        }
      },
      child: Stack(
        clipBehavior: Clip.none, // Allow dragging outside bounds
        children: [
          // Drop preview outline
          if (_showDropPreview && _previewStartTime != null && _previewEndTime != null)
            _buildDropPreview(),
          
          // Main event tile
          Positioned(
            left: _isDragging ? (_dragOffset?.dx ?? 0) : 0,
            top: _isDragging ? (_dragOffset?.dy ?? 0) : 0,
            child: Container(
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
          ),
          
          // Resize handle at the bottom
          if (widget.boundary.height > 30) // Only show resize handle for tall events
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _isResizing = true;
                  });
                },
                onPanUpdate: (details) {
                  if (_isResizing) {
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
    if (_dragStartPosition == null) return;
    
    // Calculate the drag offset for real-time visual feedback
    final delta = currentPosition - _dragStartPosition!;
    
    setState(() {
      _dragOffset = delta;
    });
    
    // Calculate preview position and start hover timer
    _calculatePreviewPosition(delta);
  }

  void _handleResize(Offset currentPosition) {
    // Just update visual state, don't call the callback yet
    setState(() {
      // Visual feedback only - no event updates during resize
    });
  }

  void _calculatePreviewPosition(Offset dragOffset) {
    // Cancel any existing timer
    _hoverTimer?.cancel();
    
    // Calculate preview times
    final minutesDelta = (dragOffset.dy / widget.heightPerMinute).round();
    final previewStartTime = _dragStartTime!.add(Duration(minutes: minutesDelta));
    final duration = widget.endDuration.difference(widget.startDuration);
    final previewEndTime = previewStartTime.add(duration);
    
    // Calculate preview date (for week view cross-day dragging)
    DateTime previewDate = widget.date;
    if (widget.dayWidth != null && widget.weekDates != null && dragOffset.dx.abs() > 15) {
      final currentDayIndex = widget.weekDates!.indexWhere((d) => 
        d.year == widget.date.year && 
        d.month == widget.date.month && 
        d.day == widget.date.day
      );
      
      if (currentDayIndex != -1) {
        final dayOffset = (dragOffset.dx / (widget.dayWidth! / 2)).round();
        final newDayIndex = currentDayIndex + dayOffset;
        
        if (newDayIndex >= 0 && newDayIndex < widget.weekDates!.length) {
          previewDate = widget.weekDates![newDayIndex];
        }
      }
    }
    
    // Update preview state
    setState(() {
      _previewStartTime = previewStartTime;
      _previewEndTime = previewEndTime;
      _previewDate = previewDate;
    });
    
    // Start timer to show preview after hovering for a bit
    _hoverTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showDropPreview = true;
        });
      }
    });
  }

  void _finishDrag() {
    // Hide preview and cancel timer
    _hoverTimer?.cancel();
    setState(() {
      _showDropPreview = false;
    });
    
    if (_dragOffset != null && _dragStartTime != null) {
      // Calculate time change (vertical movement)
      final minutesDelta = (_dragOffset!.dy / widget.heightPerMinute).round();
      final newStartTime = _dragStartTime!.add(Duration(minutes: minutesDelta));
      final duration = widget.endDuration.difference(widget.startDuration);
      final newEndTime = newStartTime.add(duration);
      
      // Check if this is a cross-day drag (horizontal movement in week view)
      if (widget.dayWidth != null && widget.weekDates != null && _dragOffset!.dx.abs() > 15) {
        // Find the current day index in the week
        final currentDayIndex = widget.weekDates!.indexWhere((d) => 
          d.year == widget.date.year && 
          d.month == widget.date.month && 
          d.day == widget.date.day
        );
        
        if (currentDayIndex != -1) {
          // Calculate how many day widths the drag represents
          // Use a more sensitive calculation - if we drag more than half a day width, move to next day
          final dayOffset = (_dragOffset!.dx / (widget.dayWidth! / 2)).round();
          final newDayIndex = currentDayIndex + dayOffset;
          
          // Debug information
          print('Cross-day drag: dx=${_dragOffset!.dx}, dayWidth=${widget.dayWidth}');
          print('Day offset calculation: ${_dragOffset!.dx} / ${widget.dayWidth! / 2} = ${_dragOffset!.dx / (widget.dayWidth! / 2)}');
          print('Rounded day offset: $dayOffset, currentDay=$currentDayIndex, newDay=$newDayIndex');
          
          // Ensure the new day index is within bounds
          if (newDayIndex >= 0 && newDayIndex < widget.weekDates!.length) {
            final newDate = widget.weekDates![newDayIndex];
            
            // Only proceed if we're actually moving to a different day
            if (newDate.day != widget.date.day || newDate.month != widget.date.month || newDate.year != widget.date.year) {
              // Create new start and end times with the new date
              final newStartTimeWithDate = DateTime(
                newDate.year,
                newDate.month,
                newDate.day,
                newStartTime.hour,
                newStartTime.minute,
              );
              final newEndTimeWithDate = DateTime(
                newDate.year,
                newDate.month,
                newDate.day,
                newEndTime.hour,
                newEndTime.minute,
              );
              
              // Call the cross-day move callback
              widget.onEventMovedToDay?.call(
                widget.events.first, 
                newStartTimeWithDate, 
                newEndTimeWithDate, 
                newDate
              );
              
              setState(() {
                _isDragging = false;
                _dragOffset = null;
              });
              _dragStartPosition = null;
              _dragStartTime = null;
              return;
            }
          }
        }
      }
      
      // Regular time-only move (same day)
      widget.onEventMoved?.call(widget.events.first, newStartTime, newEndTime);
    }
    
    setState(() {
      _isDragging = false;
      _dragOffset = null;
    });
    _dragStartPosition = null;
    _dragStartTime = null;
  }

  void _finishResize() {
    // Placeholder for resize functionality
    setState(() {
      _isResizing = false;
    });
  }

  Widget _buildDropPreview() {
    if (_previewStartTime == null || _previewEndTime == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate preview position relative to the original event position
    double previewLeft = 0;
    double previewTop = 0;

    // For week view cross-day dragging, calculate horizontal offset
    if (widget.dayWidth != null && widget.weekDates != null && _previewDate != null) {
      final currentDayIndex = widget.weekDates!.indexWhere((d) => 
        d.year == widget.date.year && 
        d.month == widget.date.month && 
        d.day == widget.date.day
      );
      
      final previewDayIndex = widget.weekDates!.indexWhere((d) => 
        d.year == _previewDate!.year && 
        d.month == _previewDate!.month && 
        d.day == _previewDate!.day
      );
      
      if (currentDayIndex != -1 && previewDayIndex != -1) {
        final dayOffset = previewDayIndex - currentDayIndex;
        previewLeft = dayOffset * widget.dayWidth!;
      }
    }

    // Calculate vertical position based on time difference
    final timeDelta = _previewStartTime!.difference(widget.startDuration);
    final minutesDelta = timeDelta.inMinutes;
    previewTop = minutesDelta * widget.heightPerMinute;

    // Debug information
    print('Preview calculation: currentDay=${widget.date.day}, previewDay=${_previewDate?.day}, dayOffset=${previewLeft / (widget.dayWidth ?? 1)}');
    print('Time calculation: startTime=${widget.startDuration.hour}:${widget.startDuration.minute}, previewTime=${_previewStartTime!.hour}:${_previewStartTime!.minute}, topOffset=$previewTop');
    
    return Positioned(
      left: previewLeft,
      top: previewTop,
      child: Container(
        width: widget.boundary.width,
        height: widget.boundary.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.8),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            color: colorScheme.primary,
            size: 16,
          ),
        ),
      ),
    );
  }
}