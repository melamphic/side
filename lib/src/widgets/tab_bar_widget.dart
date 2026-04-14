import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:side/side.dart';

/// Tab bar widget for a specific split pane
///
/// Shows tabs for the specified pane with proper active state and close buttons.
/// Supports drag-and-drop for tab reordering (future enhancement).
class WorkspaceTabBar extends StatelessWidget {
  /// Creates a [WorkspaceTabBar]
  const WorkspaceTabBar({
    required this.paneIndex,
    required this.tabs,
    required this.activeTab,
    this.canSplit = false,
    this.canClose = false,
    super.key,
  });

  /// Index of the split pane this tab bar represents
  final int paneIndex;

  /// Tabs to display in this pane
  final List<TabData> tabs;

  /// Currently active tab in this pane
  final TabData? activeTab;

  /// Whether the editor can be split further
  final bool canSplit;

  /// Whether this split pane can be closed
  final bool canClose;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty && !canClose && !canSplit) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 36,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          // Tab scroll view
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = tab.id == activeTab?.id;

                return _TabWidget(
                  tab: tab,
                  isActive: isActive,
                  paneIndex: paneIndex,
                  index: index,
                );
              },
            ),
          ),

          // Split controls
          if (canSplit || canClose) ...[
            const VerticalDivider(width: 1),
            _SplitControls(
              paneIndex: paneIndex,
              canSplit: canSplit,
              canClose: canClose,
            ),
          ],
        ],
      ),
    );
  }
}

class _TabDragData {
  const _TabDragData({
    required this.tabId,
    required this.paneIndex,
    required this.index,
  });

  final String tabId;
  final int paneIndex;
  final int index;
}

/// Individual tab widget within the tab bar
class _TabWidget extends StatelessWidget {
  const _TabWidget({
    required this.tab,
    required this.isActive,
    required this.paneIndex,
    required this.index,
  });

  final TabData tab;
  final bool isActive;
  final int paneIndex;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DragTarget<_TabDragData>(
      onWillAcceptWithDetails: (details) => details.data.tabId != tab.id,
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data.paneIndex == paneIndex) {
          context.read<WorkspaceBloc>().add(
            ReorderTab(
              paneIndex: paneIndex,
              oldIndex: data.index,
              newIndex: index,
            ),
          );
        } else {
          context.read<WorkspaceBloc>().add(
            MoveTabToPane(
              tabId: data.tabId,
              targetPaneIndex: paneIndex,
            ),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<_TabDragData>(
          data: _TabDragData(
            tabId: tab.id,
            paneIndex: paneIndex,
            index: index,
          ),
          feedback: Material(
            elevation: 4,
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab.icon != null) ...[
                    Icon(tab.icon, size: 16, color: colorScheme.onSurface),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    tab.title,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildValues(context, colorScheme),
          ),
          child: _buildValues(
            context,
            colorScheme,
            isTarget: candidateData.isNotEmpty,
          ),
        );
      },
    );
  }

  Widget _buildValues(
    BuildContext context,
    ColorScheme colorScheme, {
    bool isTarget = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.surface
            : (isTarget
                  ? colorScheme.surfaceContainerHighest
                  : Colors.transparent),
        border: isActive
            ? Border(bottom: BorderSide(color: colorScheme.primary, width: 2))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<WorkspaceBloc>().add(
              SwitchTab(tabId: tab.id, paneIndex: paneIndex),
            );
          },
          onSecondaryTapUp: (details) async {
            await _showContextMenu(context, details.globalPosition);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tab icon
                if (tab.icon != null) ...[
                  Icon(
                    tab.icon,
                    size: 16,
                    color: isActive
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                ],

                // Tab title
                Flexible(
                  child: Text(
                    tab.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: isActive
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // Dirty indicator
                if (tab.isDirty) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],

                const SizedBox(width: 8),

                // Close button
                InkWell(
                  onTap: () {
                    context.read<WorkspaceBloc>().add(CloseTab(tab.id));
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final bloc = context.read<WorkspaceBloc>();
    await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'close',
          onTap: () => bloc.add(CloseTab(tab.id)),
          child: const Text('Close'),
        ),
        PopupMenuItem<String>(
          value: 'close_others',
          onTap: () =>
              bloc.add(CloseOthers(tabId: tab.id, paneIndex: paneIndex)),
          child: const Text('Close Others'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'close_all',
          onTap: () => bloc.add(CloseAll(paneIndex)),
          child: const Text('Close All'),
        ),
      ],
    );
  }
}

/// Controls for split pane operations
///
/// Provides buttons for splitting, closing splits, and other pane operations.
class _SplitControls extends StatelessWidget {
  const _SplitControls({
    required this.paneIndex,
    required this.canSplit,
    required this.canClose,
  });

  final int paneIndex;
  final bool canSplit;
  final bool canClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Split button
        if (canSplit)
          Tooltip(
            message: 'Split Editor Right',
            child: IconButton(
              icon: const Icon(Icons.call_split, size: 16),
              onPressed: () {
                context.read<WorkspaceBloc>().add(const SplitView());
              },
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: const EdgeInsets.all(4),
            ),
          ),

        // Close split button
        if (canClose)
          Tooltip(
            message: 'Close Split',
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {
                context.read<WorkspaceBloc>().add(CloseSplit(paneIndex));
              },
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: const EdgeInsets.all(4),
            ),
          ),

        const SizedBox(width: 4),
      ],
    );
  }
}
