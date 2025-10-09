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
  
  // Resize state
  Offset? _resizeStartPosition;
  DateTime? _resizeStartTime;
  DateTime? _resizeStartEndTime;
  double? _resizeOffset;
  bool _isResizingFromTop = false;
  bool _isHoveringTopResize = false;
  bool _isHoveringBottomResize = false;
  
  // Context menu state
  Offset? _contextMenuPosition;
  Timer? _longPressTimer;

  @override
  void dispose() {
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
        // Only handle tap if not in resize zone
        if (!_isInResizeZone(Offset.zero)) {
          widget.onEventTap?.call(widget.events.first, widget.date);
        }
      },
      onLongPressStart: (details) {
        // Check if the touch is in a resize zone
        if (_isInResizeZone(details.localPosition)) {
          return; // Don't start drag or context menu in resize zones
        }
        
        // Only start long press timer if the touch is stationary
        // This prevents interference with scrolling gestures
        _contextMenuPosition = details.globalPosition;
        _longPressTimer = Timer(const Duration(milliseconds: 800), () {
          if (mounted && !_isDragging && !_isResizing) {
            _showContextMenuOverlay();
          }
        });
      },
      onLongPressMoveUpdate: (details) {
        // Check if the touch is in a resize zone
        if (_isInResizeZone(details.localPosition)) {
          return; // Don't start drag in resize zones
        }
        
        // Cancel context menu timer if user starts moving (scrolling)
        if (_longPressTimer?.isActive == true) {
          _longPressTimer?.cancel();
          return; // Don't start dragging on long press move - let scroll handle it
        }
        
        // Only handle drag if we're already in a drag state
        if (_isDragging && _dragStartPosition != null) {
          _handleDrag(details.localPosition);
        }
      },
      onLongPressEnd: (details) {
        _longPressTimer?.cancel();
        if (_isDragging) {
          _finishDrag();
        }
      },
      // Add pan gesture detector for deliberate dragging
      onPanStart: (details) {
        // Only start drag if not in resize zone and not already in a long press
        if (!_isInResizeZone(details.localPosition) && _longPressTimer?.isActive != true) {
          _dragStartPosition = details.localPosition;
          _dragStartTime = widget.startDuration;
          setState(() {
            _isDragging = true;
          });
        }
      },
      onPanUpdate: (details) {
        if (_isDragging && _dragStartPosition != null) {
          _handleDrag(details.localPosition);
        }
      },
      onPanEnd: (details) {
        if (_isDragging) {
          _finishDrag();
        }
      },
      child: Stack(
        clipBehavior: Clip.none, // Allow context menu to extend outside bounds
        children: [
          // Main event tile
          Positioned(
            left: _isDragging ? (_dragOffset?.dx ?? 0) : 0,
            top: _isDragging ? (_dragOffset?.dy ?? 0) : 
                 (_isResizing && _isResizingFromTop && _resizeOffset != null) ? _resizeOffset! : 0,
            child: Container(
              width: widget.boundary.width,
              height: _isResizing && _resizeOffset != null 
                  ? widget.boundary.height + (_isResizingFromTop ? -_resizeOffset! : _resizeOffset!)
                  : widget.boundary.height,
              decoration: BoxDecoration(
                color: (_isDragging || _isResizing)
                    ? event.color.withValues(alpha: 0.7)
                    : event.color,
                borderRadius: BorderRadius.circular(8),
                border: (_isDragging || _isResizing)
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
                boxShadow: (_isDragging || _isResizing)
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
                        color: Colors.white,
                        fontSize: event.titleStyle?.fontSize ?? 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0.5, 0.5),
                            blurRadius: 1.0,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
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
          
          // Top resize zone - 10% of event height for easy interaction
          if (widget.boundary.height > 60) // Only show for events tall enough
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onPanStart: (details) {
                  _resizeStartPosition = details.localPosition;
                  _resizeStartTime = widget.startDuration;
                  _resizeStartEndTime = widget.endDuration;
                  setState(() {
                    _isResizing = true;
                    _resizeOffset = 0;
                    _isResizingFromTop = true;
                    _isHoveringTopResize = true;
                  });
                },
                onPanUpdate: (details) {
                  if (_isResizing && _resizeStartPosition != null) {
                    _handleResize(details.localPosition);
                  }
                },
                onPanEnd: (details) {
                  if (_isResizing) {
                    _finishResize();
                  }
                  setState(() {
                    _isHoveringTopResize = false;
                  });
                },
                onPanCancel: () {
                  setState(() {
                    _isHoveringTopResize = false;
                  });
                },
                child: MouseRegion(
                  onEnter: (_) {
                    if (!_isResizing) {
                      setState(() {
                        _isHoveringTopResize = true;
                      });
                    }
                  },
                  onExit: (_) {
                    if (!_isResizing) {
                      setState(() {
                        _isHoveringTopResize = false;
                      });
                    }
                  },
                  child: Container(
                    height: (widget.boundary.height * 0.1).clamp(20.0, 40.0), // 10% of height, min 20px, max 40px
                    decoration: BoxDecoration(
                      color: _isResizing 
                          ? _getDarkerColor(event.color).withValues(alpha: 0.4)
                          : _isHoveringTopResize 
                              ? _getDarkerColor(event.color).withValues(alpha: 0.2)
                              : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: _isHoveringTopResize || _isResizing
                          ? Border.all(
                              color: _getDarkerColor(event.color).withValues(alpha: 0.8),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _isResizing 
                              ? _getDarkerColor(event.color)
                              : _isHoveringTopResize
                                  ? _getDarkerColor(event.color).withValues(alpha: 0.8)
                                  : _getDarkerColor(event.color).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: _isHoveringTopResize || _isResizing
                              ? [
                                  BoxShadow(
                                    color: _getDarkerColor(event.color).withValues(alpha: 0.3),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Bottom resize zone - 10% of event height for easy interaction
          if (widget.boundary.height > 60) // Only show for events tall enough
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onPanStart: (details) {
                  _resizeStartPosition = details.localPosition;
                  _resizeStartTime = widget.startDuration;
                  _resizeStartEndTime = widget.endDuration;
                  setState(() {
                    _isResizing = true;
                    _resizeOffset = 0;
                    _isResizingFromTop = false;
                    _isHoveringBottomResize = true;
                  });
                },
                onPanUpdate: (details) {
                  if (_isResizing && _resizeStartPosition != null) {
                    _handleResize(details.localPosition);
                  }
                },
                onPanEnd: (details) {
                  if (_isResizing) {
                    _finishResize();
                  }
                  setState(() {
                    _isHoveringBottomResize = false;
                  });
                },
                onPanCancel: () {
                  setState(() {
                    _isHoveringBottomResize = false;
                  });
                },
                child: MouseRegion(
                  onEnter: (_) {
                    if (!_isResizing) {
                      setState(() {
                        _isHoveringBottomResize = true;
                      });
                    }
                  },
                  onExit: (_) {
                    if (!_isResizing) {
                      setState(() {
                        _isHoveringBottomResize = false;
                      });
                    }
                  },
                  child: Container(
                    height: (widget.boundary.height * 0.1).clamp(20.0, 40.0), // 10% of height, min 20px, max 40px
                    decoration: BoxDecoration(
                      color: _isResizing 
                          ? _getDarkerColor(event.color).withValues(alpha: 0.4)
                          : _isHoveringBottomResize 
                              ? _getDarkerColor(event.color).withValues(alpha: 0.2)
                              : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: _isHoveringBottomResize || _isResizing
                          ? Border.all(
                              color: _getDarkerColor(event.color).withValues(alpha: 0.8),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _isResizing 
                              ? _getDarkerColor(event.color)
                              : _isHoveringBottomResize
                                  ? _getDarkerColor(event.color).withValues(alpha: 0.8)
                                  : _getDarkerColor(event.color).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: _isHoveringBottomResize || _isResizing
                              ? [
                                  BoxShadow(
                                    color: _getDarkerColor(event.color).withValues(alpha: 0.3),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
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
  }

  void _handleResize(Offset currentPosition) {
    if (_resizeStartPosition == null || _resizeStartEndTime == null) return;
    
    // Calculate the vertical movement for resize
    final deltaY = currentPosition.dy - _resizeStartPosition!.dy;
    
    setState(() {
      _resizeOffset = deltaY;
    });
  }


  void _finishDrag() {
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
    if (_resizeOffset != null && _resizeStartEndTime != null) {
      // Calculate time change (vertical movement for resize)
      final minutesDelta = (_resizeOffset! / widget.heightPerMinute).round();
      
      if (_isResizingFromTop) {
        // Resizing from top - adjust start time
        // Negative deltaY (upward drag) should move start time earlier (subtract minutes)
        // Positive deltaY (downward drag) should move start time later (add minutes)
        final newStartTime = _resizeStartTime!.add(Duration(minutes: minutesDelta));
        
        // Ensure the new start time is not after the end time (minimum 15 minutes)
        final maximumStartTime = _resizeStartEndTime!.subtract(const Duration(minutes: 15));
        final finalStartTime = newStartTime.isAfter(maximumStartTime) ? maximumStartTime : newStartTime;
        
        // Call the resize callback with updated start time
        widget.onEventResized?.call(widget.events.first, finalStartTime, _resizeStartEndTime!);
      } else {
        // Resizing from bottom - adjust end time
        // Positive deltaY (downward drag) should move end time later (add minutes)
        // Negative deltaY (upward drag) should move end time earlier (subtract minutes)
        final newEndTime = _resizeStartEndTime!.add(Duration(minutes: minutesDelta));
        
        // Ensure the new end time is not before the start time (minimum 15 minutes)
        final minimumEndTime = _resizeStartTime!.add(const Duration(minutes: 15));
        final finalEndTime = newEndTime.isBefore(minimumEndTime) ? minimumEndTime : newEndTime;
        
        // Call the resize callback with updated end time
        widget.onEventResized?.call(widget.events.first, _resizeStartTime!, finalEndTime);
      }
    }
    
    setState(() {
      _isResizing = false;
      _resizeOffset = null;
      _isHoveringTopResize = false;
      _isHoveringBottomResize = false;
    });
    _resizeStartPosition = null;
    _resizeStartTime = null;
    _resizeStartEndTime = null;
    _isResizingFromTop = false;
  }

  bool _isInResizeZone(Offset position) {
    // Check if the touch is in the top or bottom resize zones (10% of height each)
    final resizeZoneHeight = (widget.boundary.height * 0.1).clamp(20.0, 40.0);
    final topResizeZone = Rect.fromLTWH(0, 0, widget.boundary.width, resizeZoneHeight);
    final bottomResizeZone = Rect.fromLTWH(0, widget.boundary.height - resizeZoneHeight, widget.boundary.width, resizeZoneHeight);
    
    return topResizeZone.contains(position) || bottomResizeZone.contains(position);
  }

  Color _getDarkerColor(Color color) {
    // Create a darker shade by reducing brightness and saturation
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0))
              .withSaturation((hsl.saturation * 1.2).clamp(0.0, 1.0))
              .toColor();
  }

  void _showContextMenuOverlay() {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => EventContextMenu<T>(
        event: widget.events.first,
        date: widget.date,
        position: _contextMenuPosition!,
        onDismiss: () {
          overlayEntry.remove();
        },
        onDuplicate: widget.onEventDuplicate,
        onDelete: widget.onEventDelete,
      ),
    );
    
    overlay.insert(overlayEntry);
  }

}