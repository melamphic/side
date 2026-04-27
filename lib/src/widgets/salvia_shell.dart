import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:side/src/bloc/workspace_bloc.dart';
import 'package:side/src/models/workspace_config_model.dart';
import 'package:side/src/widgets/activity_bar.dart';
import 'package:side/src/widgets/resizable_container.dart';
import 'package:side/src/widgets/sidebar.dart';
import 'package:side/src/widgets/split_editor.dart';

/// Main workspace shell widget providing a VS Code-like interface
///
/// This is the primary widget that creates a complete workspace environment
/// similar to Visual Studio Code, featuring:
///
/// - **Activity Bar**: Leftmost vertical bar with main activity icons
/// - **Sidebar**: Context-sensitive panel showing hierarchical content
/// - **Split Editor**: Main content area supporting vertical splits
/// - **Persistent State**: Maintains open tabs and layout across activity switches
///
/// ## Layout Structure
/// ```text
/// ┌─────────────┬──────────────┬─────────────────────────┐
/// │ Activity    │   Sidebar    │     Split Editor        │
/// │ Bar         │             │                         │
/// │ (48px)      │  (Variable)  │     (Remainder)         │
/// │             │             │                         │
/// │ • Explorer  │ - Main Item  │ ┌─────────┬─────────────┐ │
/// │ • Search    │   - Child    │ │ Tab Bar │   Tab Bar   │ │
/// │ • Git       │   - Child    │ ├─────────┼─────────────┤ │
/// │ • Debug     │ - Main Item  │ │         │             │ │
/// │ • Extensions│              │ │ Content │   Content   │ │
/// │             │              │ │         │             │ │
/// └─────────────┴──────────────┴─────────────────────────┘
/// ```
///
/// ## Usage Example
/// ```dart
/// WorkspaceShell(
///   config: WorkspaceConfig(
///     activityBarItems: [
///       ActivityBarItem(
///         id: 'explorer',
///         icon: Icons.folder_outlined,
///         label: 'Explorer',
///         sidebarView: SidebarView(/* ... */),
///       ),
///       // ... more items
///     ],
///   ),
/// )
/// ```
class WorkspaceShell extends StatelessWidget {
  /// Creates a [WorkspaceShell].
  ///
  /// Pass [bloc] to reuse an externally hoisted [WorkspaceBloc] (e.g. so a
  /// sibling widget above the shell can also dispatch events). When null
  /// the shell creates and owns its own bloc.
  const WorkspaceShell({required this.config, this.bloc, super.key});

  /// Configuration defining the workspace structure and content
  ///
  /// Contains activity bar items, sidebar views, theming, and behavior settings.
  final WorkspaceConfig config;

  /// Optional pre-existing bloc. When provided, the shell republishes it via
  /// [BlocProvider.value]; ownership stays with the caller.
  final WorkspaceBloc? bloc;

  @override
  Widget build(BuildContext context) {
    final external = bloc;
    if (external != null) {
      return BlocProvider<WorkspaceBloc>.value(
        value: external,
        child: _WorkspaceLayout(config: config),
      );
    }
    return BlocProvider(
      create: (context) {
        final owned = WorkspaceBloc(maxTabs: config.maxTabs);
        // Only set default activity if none was restored from hydrated state
        // and we have items in the config.
        if (owned.state.activeActivityId == null &&
            config.activityBarItems.isNotEmpty) {
          owned.add(SwitchActivity(config.activityBarItems.first.id));
        }
        return owned;
      },
      child: _WorkspaceLayout(config: config),
    );
  }
}

/// Internal layout widget that handles the actual UI structure
///
/// Separated for cleaner code organization and to ensure BLoC context
/// is properly available to all child widgets.
class _WorkspaceLayout extends StatelessWidget {
  const _WorkspaceLayout({required this.config});

  final WorkspaceConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<WorkspaceBloc, WorkspaceState>(
        builder: (context, state) {
          // Activities without a registered sidebarView render the editor
          // full-bleed (no sidebar, no resize handle). Used for "direct
          // page" activities like Home where there's no list to navigate.
          final hasSidebar = state.activeActivityId != null &&
              config.sidebarViews.containsKey(state.activeActivityId);
          return Row(
            children: [
              // Activity Bar - Using proper ActivityBar widget
              ActivityBar(items: config.activityBarItems, config: config),

              if (hasSidebar)
                Expanded(
                  child: ResizableContainer(
                    sidebarWidth: state.sidebarWidth ?? config.sidebarWidth,
                    onResize: (width) => context
                        .read<WorkspaceBloc>()
                        .add(ResizeSidebar(width)),
                    sidebar: WorkspaceSidebar(config: config),
                    content: const SplitEditor(),
                  ),
                )
              else
                const Expanded(child: SplitEditor()),
            ],
          );
        },
      ),
    );
  }
}
