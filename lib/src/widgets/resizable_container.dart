import 'package:flutter/material.dart';

/// A container that displays a sidebar and main content with a resizable handle
class ResizableContainer extends StatefulWidget {
  /// Creates a [ResizableContainer]
  const ResizableContainer({
    required this.sidebar,
    required this.content,
    required this.sidebarWidth,
    required this.onResize,
    this.minSidebarWidth = 150.0,
    this.maxSidebarWidth = 600.0,
    super.key,
  });

  /// The sidebar widget (left side)
  final Widget sidebar;

  /// The main content widget (right side)
  final Widget content;

  /// Current width of the sidebar
  final double sidebarWidth;

  /// Callback when the sidebar is resized
  final ValueChanged<double> onResize;

  /// Minimum allowed width for the sidebar
  final double minSidebarWidth;

  /// Maximum allowed width for the sidebar
  final double maxSidebarWidth;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        SizedBox(
          width: widget.sidebarWidth,
          child: widget.sidebar,
        ),

        // Resize Handle
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onPanStart: (_) {
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              final newWidth = widget.sidebarWidth + details.delta.dx;
              if (newWidth >= widget.minSidebarWidth &&
                  newWidth <= widget.maxSidebarWidth) {
                widget.onResize(newWidth);
              }
            },
            onPanEnd: (_) {
              setState(() {
                _isDragging = false;
              });
            },
            child: Container(
              width: 5,
              color: _isDragging
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .5)
                  : Colors.transparent,
              child: Center(
                child: Container(
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ),
        ),

        // Main Content
        Expanded(
          child: widget.content,
        ),
      ],
    );
  }
}
