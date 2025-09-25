import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

class DraggableMonthCell<T extends Object?> extends StatelessWidget {
  /// Date of cell.
  final DateTime date;

  /// List of events on for current date.
  final List<CalendarEventData<T>> events;

  /// defines date string for current date.
  final StringProvider? dateStringBuilder;

  /// Defines if cell should be highlighted or not.
  /// If true it will display date title in a circle.
  final bool shouldHighlight;

  /// Defines background color of cell.
  final Color backgroundColor;

  /// Defines highlight color.
  final Color highlightColor;

  /// Color for event tile.
  final Color tileColor;

  /// Called when user taps on any event tile.
  final TileTapCallback<T>? onTileTap;

  /// Called when user long press on any event tile.
  final TileTapCallback<T>? onTileLongTap;

  /// Called when user double tap on any event tile.
  final TileTapCallback<T>? onTileDoubleTap;

  /// Similar to [onTileTap] with additional tap details callback.
  final TileTapDetailsCallback<T>? onTileTapDetails;

  /// Similar to [onTileDoubleTap] with additional tap details callback.
  final TileDoubleTapDetailsCallback<T>? onTileDoubleTapDetails;

  /// Similar to [onTileLongTap] with additional tap details callback.
  final TileLongTapDetailsCallback<T>? onTileLongTapDetails;

  /// defines that [date] is in current month or not.
  final bool isInMonth;

  /// defines radius of highlighted date.
  final double highlightRadius;

  /// color of cell title
  final Color titleColor;

  /// color of highlighted cell title
  final Color highlightedTitleColor;

  /// defines that show and hide cell not is in current month
  final bool hideDaysNotInMonth;

  /// Callback when event is moved to a different date
  final Function(CalendarEventData<T>, DateTime)? onEventMovedToDate;

  /// Callback when drag starts
  final Function(CalendarEventData<T>, DateTime)? onDragStart;

  /// Callback when drag ends
  final Function(CalendarEventData<T>, DateTime)? onDragEnd;

  const DraggableMonthCell({
    Key? key,
    required this.date,
    required this.events,
    this.isInMonth = false,
    this.hideDaysNotInMonth = true,
    this.shouldHighlight = false,
    this.backgroundColor = Colors.blue,
    this.highlightColor = Colors.blue,
    this.onTileTap,
    this.onTileLongTap,
    this.onTileDoubleTap,
    this.onTileTapDetails,
    this.onTileDoubleTapDetails,
    this.onTileLongTapDetails,
    this.tileColor = Colors.blue,
    this.highlightRadius = 11,
    this.titleColor = Colors.black,
    this.highlightedTitleColor = Colors.white,
    this.dateStringBuilder,
    this.onEventMovedToDate,
    this.onDragStart,
    this.onDragEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          const SizedBox(height: 5.0),
          if (!(!isInMonth && hideDaysNotInMonth))
            CircleAvatar(
              radius: highlightRadius,
              backgroundColor: shouldHighlight ? highlightColor : Colors.transparent,
              child: Text(
                dateStringBuilder?.call(date) ?? "${date.day}",
                style: TextStyle(
                  color: shouldHighlight ? highlightedTitleColor : titleColor,
                  fontSize: 12,
                ),
              ),
            ),
          if (events.isNotEmpty)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 5.0),
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      events.length,
                      (index) => _buildDraggableEventTile(events[index]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDraggableEventTile(CalendarEventData<T> event) {
    return LongPressDraggable<CalendarEventData<T>>(
      data: event,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(4.0),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: event.color,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            event.title,
            style: event.titleStyle ??
                TextStyle(
                  color: event.color.accent,
                  fontSize: 12,
                ),
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: event.color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 3.0),
        padding: const EdgeInsets.all(2.0),
        alignment: Alignment.center,
        child: Row(
          children: [
            Expanded(
              child: Text(
                event.title,
                overflow: TextOverflow.clip,
                maxLines: 1,
                style: event.titleStyle ??
                    TextStyle(
                      color: event.color.accent,
                      fontSize: 12,
                    ),
              ),
            ),
          ],
        ),
      ),
      onDragStarted: () {
        onDragStart?.call(event, date);
      },
      onDragEnd: (details) {
        onDragEnd?.call(event, date);
      },
      child: GestureDetector(
        onTap: onTileTap.safeVoidCall(event, date),
        child: Container(
          decoration: BoxDecoration(
            color: event.color,
            borderRadius: BorderRadius.circular(4.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 3.0),
          padding: const EdgeInsets.all(2.0),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                  style: event.titleStyle ??
                      TextStyle(
                        color: event.color.accent,
                        fontSize: 12,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
