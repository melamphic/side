import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:side/src/bloc/workspace_bloc.dart';
import 'package:side/src/models/models.dart';

/// Widget that displays the main content for the active tab
class WorkspaceContentArea extends StatelessWidget {
  /// Creates a [WorkspaceContentArea]
  const WorkspaceContentArea({required this.config, super.key});

  /// The workspace configuration containing the page registry
  final WorkspaceConfig config;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceBloc, WorkspaceState>(
      builder: (context, state) {
        if (state.openTabs.isEmpty) {
          return Center(
            child: Text(
              'No tabs open',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          );
        }

        final activeIndex = state.openTabs.indexWhere(
          (tab) => tab.id == state.activeTabId,
        );

        if (activeIndex == -1) {
          return const Center(child: Text('Tab not found'));
        }

        return IndexedStack(
          index: activeIndex,
          children: state.openTabs.map((tab) {
            return _KeepAliveWrapper(
              key: ValueKey(tab.id),
              child: _buildPage(context, tab),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPage(BuildContext context, TabData tab) {
    final builder = config.pageRegistry[tab.pageId];

    if (builder == null) {
      return Center(child: Text('Page "${tab.pageId}" not found in registry'));
    }

    return builder(context, tab.pageArgs);
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  const _KeepAliveWrapper({required this.child, super.key});

  final Widget child;

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
