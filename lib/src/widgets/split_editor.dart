import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:side/side.dart';

/// Editor area widget that shows the active tab's content
///
/// Hosts the tab bar above and the content of the active tab below.
/// Tabs are displayed in an [IndexedStack] so each tab's state is
/// preserved when switching between them.
class WorkspaceEditor extends StatelessWidget {
  /// Creates a [WorkspaceEditor]
  const WorkspaceEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceBloc, WorkspaceState>(
      builder: (context, state) {
        return Column(
          children: [
            WorkspaceTabBar(
              tabs: state.openTabs,
              activeTab: state.getActiveTab(),
            ),
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
                      ),
                    );
                  } else if (data is String) {
                    context.read<WorkspaceBloc>().add(
                      OpenTab(pageId: data, title: data),
                    );
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  final activeIndex = state.activeTabId == null
                      ? -1
                      : state.openTabs.indexWhere(
                          (t) => t.id == state.activeTabId,
                        );
                  return ColoredBox(
                    color: candidateData.isNotEmpty
                        ? Theme.of(context).colorScheme.primaryContainer
                              .withValues(alpha: .3)
                        : Theme.of(context).colorScheme.surface,
                    child: state.openTabs.isEmpty || activeIndex < 0
                        ? const _EmptyEditor()
                        : IndexedStack(
                            sizing: StackFit.expand,
                            index: activeIndex,
                            children: [
                              for (final tab in state.openTabs)
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
}

/// Widget shown when no tab is open
class _EmptyEditor extends StatelessWidget {
  const _EmptyEditor();

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
