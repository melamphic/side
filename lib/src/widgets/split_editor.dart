import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:side/side.dart';

/// Split editor widget that manages multiple split panes
///
/// This widget handles the layout and management of split editor panes,
/// allowing users to view and edit multiple tabs simultaneously in a
/// VS Code-like interface. Currently supports vertical splitting only.
///
/// Features:
/// - Vertical split panes (up to 2 panes currently)
/// - Resizable split dividers
/// - Independent tab bars for each pane
/// - Persistent tab state across panes
class SplitEditor extends StatefulWidget {
  /// Creates a [SplitEditor]
  const SplitEditor({super.key});

  @override
  State<SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends State<SplitEditor> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceBloc, WorkspaceState>(
      builder: (context, state) {
        final splitConfig = state.splitConfiguration;

        if (splitConfig.splitCount == 1) {
          // Single pane - show traditional tab bar + content
          return const _SinglePane(paneIndex: 0);
        } else {
          // Multiple panes - show split layout
          return _SplitLayout(splitConfiguration: splitConfig, state: state);
        }
      },
    );
  }
}

/// Widget for displaying a single editor pane
///
/// Used both for non-split mode and as individual panes within splits.
/// State used to optimize pane rebuilds
class _PaneSelectorState extends Equatable {
  const _PaneSelectorState({
    required this.tabs,
    required this.activeTab,
    required this.canSplit,
    required this.canClose,
    required this.isActivePane,
  });

  final List<TabData> tabs;
  final TabData? activeTab;
  final bool canSplit;
  final bool canClose;
  final bool isActivePane;

  @override
  List<Object?> get props => [
    tabs,
    activeTab,
    canSplit,
    canClose,
    isActivePane,
  ];
}

/// Widget for displaying a single editor pane
///
/// Used both for non-split mode and as individual panes within splits.
class _SinglePane extends StatelessWidget {
  const _SinglePane({required this.paneIndex});

  /// Index of this pane (0 for first pane, 1 for second, etc.)
  final int paneIndex;

  @override
  Widget build(BuildContext context) {
    // Optimization: Use BlocSelector to select ONLY the data needed for this pane.
    // This prevents rebuilds when other panes change or unrelated state updates.
    return BlocSelector<WorkspaceBloc, WorkspaceState, _PaneSelectorState>(
      selector: (state) {
        return _PaneSelectorState(
          tabs: state.getTabsInPane(paneIndex),
          activeTab: state.getActiveTabInPane(paneIndex),
          canSplit: state.splitConfiguration.splitCount < 2,
          canClose: state.splitConfiguration.splitCount > 1,
          isActivePane: state.activePaneIndex == paneIndex,
        );
      },
      builder: (context, state) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) {
            context.read<WorkspaceBloc>().add(SetActivePane(paneIndex));
          },
          child: Container(
            decoration: BoxDecoration(
              border: state.isActivePane
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    )
                  : null,
            ),
            child: Column(
              children: [
                // Tab bar for this pane
                WorkspaceTabBar(
                  paneIndex: paneIndex,
                  tabs: state.tabs,
                  activeTab: state.activeTab,
                  canSplit: state.canSplit,
                  canClose: state.canClose,
                ),

                // Content area
                Expanded(
                  child: DragTarget<Object>(
                    onWillAcceptWithDetails: (details) =>
                        details.data is WorkspaceDragData ||
                        (details.data is String &&
                            (details.data as String).isNotEmpty),
                    onAcceptWithDetails: (details) {
                      final dynamic data = details.data;
                      if (data is WorkspaceDragData) {
                        context.read<WorkspaceBloc>().add(
                          OpenTab(
                            pageId: data.pageId,
                            title: data.title,
                            icon: data.icon,
                            pageArgs: data.pageArgs,
                            paneIndex: paneIndex,
                          ),
                        );
                      } else if (data is String) {
                        context.read<WorkspaceBloc>().add(
                          OpenTab(
                            pageId: data,
                            title: data,
                            paneIndex: paneIndex,
                          ),
                        );
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      final activeIndex = state.activeTab == null
                          ? -1
                          : state.tabs.indexWhere(
                              (t) => t.id == state.activeTab!.id,
                            );
                      return ColoredBox(
                        color: candidateData.isNotEmpty
                            ? Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: .3)
                            : Theme.of(context).colorScheme.surface,
                        child: state.tabs.isEmpty || activeIndex < 0
                            ? _buildEmptyPane(context, paneIndex)
                            : IndexedStack(
                                sizing: StackFit.expand,
                                index: activeIndex,
                                children: [
                                  for (final tab in state.tabs)
                                    KeyedSubtree(
                                      key: ValueKey(tab.id),
                                      child: _buildPageContent(context, tab),
                                    ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build the page content using the config's pageRegistry
  Widget _buildPageContent(BuildContext context, TabData tab) {
    final config = context
        .findAncestorWidgetOfExactType<WorkspaceShell>()
        ?.config;

    if (config == null) {
      return const Center(child: Text('Configuration not found'));
    }

    final pageBuilder = config.pageRegistry[tab.pageId];

    if (pageBuilder == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${tab.pageId}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return pageBuilder(context, tab.pageArgs);
  }

  /// Build the empty pane content using config's emptyPaneBuilder or default
  Widget _buildEmptyPane(BuildContext context, int paneIdx) {
    final config = context
        .findAncestorWidgetOfExactType<WorkspaceShell>()
        ?.config;

    if (config?.emptyPaneBuilder != null) {
      return config!.emptyPaneBuilder!(context, paneIdx);
    }

    return _EmptyPane(paneIndex: paneIdx);
  }
}

/// Layout widget for managing multiple split panes
///
/// Handles the arrangement and resizing of split panes with dividers.
class _SplitLayout extends StatefulWidget {
  const _SplitLayout({required this.splitConfiguration, required this.state});

  final SplitConfiguration splitConfiguration;
  final WorkspaceState state;

  @override
  State<_SplitLayout> createState() => _SplitLayoutState();
}

class _SplitLayoutState extends State<_SplitLayout> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // First pane
        Expanded(
          flex: (widget.splitConfiguration.splitRatios[0] * 1000).round(),
          child: const _SinglePane(paneIndex: 0),
        ),

        // Split divider
        _SplitDivider(
          onResize: (delta) {
            final newRatios = _calculateNewSplitRatios(delta);
            context.read<WorkspaceBloc>().add(ResizeSplit(newRatios));
          },
        ),

        // Second pane (if exists)
        if (widget.splitConfiguration.splitCount > 1)
          Expanded(
            flex: (widget.splitConfiguration.splitRatios[1] * 1000).round(),
            child: const _SinglePane(paneIndex: 1),
          ),
      ],
    );
  }

  /// Calculate new split ratios based on resize delta
  List<double> _calculateNewSplitRatios(double delta) {
    final config =
        context.findAncestorWidgetOfExactType<WorkspaceShell>()?.config;

    final currentSizes = widget.splitConfiguration.splitRatios;

    final activityBarWidth = config?.activityBarWidth ?? 48.0;
    final sidebarWidth =
        widget.state.sidebarWidth ?? config?.sidebarWidth ?? 250.0;

    final totalWidth =
        MediaQuery.of(context).size.width - activityBarWidth - sidebarWidth;

    final deltaRatio = delta / totalWidth;

    return [
      (currentSizes[0] + deltaRatio).clamp(0.2, 0.8),
      (currentSizes[1] - deltaRatio).clamp(0.2, 0.8),
    ];
  }
}

/// Draggable divider between split panes
///
/// Allows users to resize split panes by dragging the divider.
class _SplitDivider extends StatefulWidget {
  const _SplitDivider({required this.onResize});

  final ValueChanged<double> onResize;

  @override
  State<_SplitDivider> createState() => _SplitDividerState();
}

class _SplitDividerState extends State<_SplitDivider> {
  bool _isDragging = false;
  double _lastPanPosition = 0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
            _lastPanPosition = details.globalPosition.dx;
          });
        },
        onPanUpdate: (details) {
          if (_isDragging) {
            final delta = details.globalPosition.dx - _lastPanPosition;
            _lastPanPosition = details.globalPosition.dx;
            widget.onResize(delta);
          }
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Container(
          width: 4,
          color: _isDragging
              ? Theme.of(context).colorScheme.primary.withValues(alpha: .3)
              : Theme.of(context).dividerColor,
          child: Center(
            child: Container(width: 1, color: Theme.of(context).dividerColor),
          ),
        ),
      ),
    );
  }
}

/// Widget shown when a pane has no active content
///
/// Provides helpful information and actions for empty panes.
class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.paneIndex});

  final int paneIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tab,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: .5),
          ),
          const SizedBox(height: 16),

          Text(
            'No editor open',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Select an item from the sidebar to open it here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
