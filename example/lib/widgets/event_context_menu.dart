import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

class EventContextMenu<T extends Object?> extends StatelessWidget {
  final CalendarEventData<T> event;
  final DateTime date;
  final Offset position;
  final VoidCallback onDismiss;
  final Function(CalendarEventData<T>, DateTime)? onCut;
  final Function(CalendarEventData<T>, DateTime)? onCopy;
  final Function(CalendarEventData<T>, DateTime)? onDuplicate;
  final Function(CalendarEventData<T>, DateTime)? onDelete;

  const EventContextMenu({
    super.key,
    required this.event,
    required this.date,
    required this.position,
    required this.onDismiss,
    this.onCut,
    this.onCopy,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        print('Context menu background tapped - dismissing');
        onDismiss();
      },
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Full screen transparent overlay to catch taps outside
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            // Context menu positioned at the tap location
            Positioned(
              left: position.dx - 100, // Center the menu around the tap position
              top: position.dy - 60,   // Position above the tap
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.surface,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.content_cut,
                        label: 'Cut',
                        onTap: () {
                          print('Cut button tapped');
                          onCut?.call(event, date);
                          onDismiss();
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.content_copy,
                        label: 'Copy',
                        onTap: () {
                          print('Copy button tapped');
                          onCopy?.call(event, date);
                          onDismiss();
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.content_copy,
                        label: 'Duplicate',
                        onTap: () {
                          print('Duplicate button tapped');
                          onDuplicate?.call(event, date);
                          onDismiss();
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.delete,
                        label: 'Delete',
                        onTap: () {
                          print('Delete button tapped');
                          onDelete?.call(event, date);
                          onDismiss();
                        },
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDestructive 
                  ? colorScheme.error 
                  : colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDestructive 
                    ? colorScheme.error 
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
