import 'dart:async';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import 'event_context_menu.dart';

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
  
  // Context menu callbacks
  final Function(CalendarEventData<T>, DateTime)? onEventCut;
  final Function(CalendarEventData<T>, DateTime)? onEventCopy;
  final Function(CalendarEventData<T>, DateTime)? onEventDuplicate;
  final Function(CalendarEventData<T>, DateTime)? onEventDelete;

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
    this.onEventCut,
    this.onEventCopy,
    this.onEventDuplicate,
    this.onEventDelete,
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
  
  // Context menu state
  bool _showContextMenu = false;
  Offset? _contextMenuPosition;
  Timer? _longPressTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _longPressTimer?.cancel();
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
        // Hide context menu if showing
        if (_showContextMenu) {
          setState(() {
            _showContextMenu = false;
          });
          return;
        }
        // Tap opens edit menu
        widget.onEventTap?.call(widget.events.first, widget.date);
      },
      onLongPressStart: (details) {
        // Start long press timer for context menu
        _contextMenuPosition = details.globalPosition;
        _longPressTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted && !_isDragging) {
            setState(() {
              _showContextMenu = true;
            });
          }
        });
      },
      onLongPressMoveUpdate: (details) {
        // If user starts moving, cancel context menu and start dragging
        if (_longPressTimer?.isActive == true) {
          _longPressTimer?.cancel();
          _dragStartPosition = details.localPosition;
          _dragStartTime = widget.startDuration;
          setState(() {
            _isDragging = true;
            _showContextMenu = false;
          });
        } else if (_isDragging && _dragStartPosition != null) {
          _handleDrag(details.localPosition);
        }
      },
      onLongPressEnd: (details) {
        _longPressTimer?.cancel();
        if (_isDragging) {
          _finishDrag();
        }
      },
      child: Stack(
        clipBehavior: Clip.none, // Allow context menu to extend outside bounds
        children: [
          // Context menu
          if (_showContextMenu && _contextMenuPosition != null)
            EventContextMenu<T>(
              event: event,
              date: widget.date,
              position: _contextMenuPosition!,
              onDismiss: () {
                setState(() {
                  _showContextMenu = false;
                });
              },
              onCut: widget.onEventCut,
              onCopy: widget.onEventCopy,
              onDuplicate: widget.onEventDuplicate,
              onDelete: widget.onEventDelete,
            ),
          
          // Debug: Always show a test context menu for debugging
          if (false) // Set to true for debugging
            EventContextMenu<T>(
              event: event,
              date: widget.date,
              position: Offset.zero,
              onDismiss: () {},
              onCut: widget.onEventCut,
              onCopy: widget.onEventCopy,
              onDuplicate: widget.onEventDuplicate,
              onDelete: widget.onEventDelete,
            ),
          
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
    _hoverTimer = Timer(const Duration(milliseconds: 200), () {
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
          // Use the same calculation as the preview for consistency
          final dayOffset = (_dragOffset!.dx / widget.dayWidth!).round();
          final newDayIndex = currentDayIndex + dayOffset;
          
          // Debug information
          print('Cross-day drag: dx=${_dragOffset!.dx}, dayWidth=${widget.dayWidth}');
          print('Day offset calculation: ${_dragOffset!.dx} / ${widget.dayWidth} = ${_dragOffset!.dx / widget.dayWidth!}');
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
    if (_previewStartTime == null || _previewEndTime == null || _dragOffset == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate the actual drop position based on the drag offset
    // This is where the event will actually be placed when dropped
    double previewLeft = _dragOffset!.dx;
    double previewTop = _dragOffset!.dy;

    // For week view, we need to snap to the grid
    if (widget.dayWidth != null && widget.weekDates != null) {
      // Snap horizontal position to day boundaries
      final dayOffset = (_dragOffset!.dx / widget.dayWidth!).round();
      previewLeft = dayOffset * widget.dayWidth!;
      
      // Debug information for day calculation
      print('Day calculation: dragOffset.dx=${_dragOffset!.dx}, dayWidth=${widget.dayWidth}, dayOffset=$dayOffset, previewLeft=$previewLeft');
    }

    // Snap vertical position to time grid (every 15 minutes)
    final timeSnapMinutes = 15;
    final minutesDelta = (_dragOffset!.dy / widget.heightPerMinute).round();
    final snappedMinutes = (minutesDelta / timeSnapMinutes).round() * timeSnapMinutes;
    previewTop = snappedMinutes * widget.heightPerMinute;

    // Debug information
    print('Preview position: dragOffset=(${_dragOffset!.dx}, ${_dragOffset!.dy}), preview=($previewLeft, $previewTop)');
    print('Preview time: ${_previewStartTime!.hour}:${_previewStartTime!.minute}, preview date: ${_previewDate?.day}');
    
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