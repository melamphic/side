import 'dart:async';

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
class _WorkspaceLayout extends StatefulWidget {
  const _WorkspaceLayout({required this.config});

  final WorkspaceConfig config;

  @override
  State<_WorkspaceLayout> createState() => _WorkspaceLayoutState();
}

class _WorkspaceLayoutState extends State<_WorkspaceLayout> {
  // Tracked only when [WorkspaceConfig.collapsibleSidebar] is on. The dock
  // sits to the left of the editor in a Row; AnimatedContainer animates
  // the sidebar's width and the editor reflows naturally.
  //
  // Starts open: Flutter's MouseRegion only fires onEnter on actual pointer
  // movement, so if the user's cursor is already over the activity bar
  // when this widget mounts, no synthetic enter event fires until the
  // first pointer move. Starting expanded shows the dock immediately on
  // load — the moment the user moves the cursor into the editor area the
  // exit handler collapses it, and from then on hover-driven open / close
  // behaves normally.
  bool _hover = true;

  // Debounce the close so the dock doesn't flicker when the cursor briefly
  // exits and re-enters (e.g. when crossing the activity bar's right edge
  // before the open animation has caught up to it). Without the delay the
  // sidebar opens, slams shut, opens again — common dock-UX flicker.
  Timer? _closeDebounce;

  static const _hoverCloseDelay = Duration(milliseconds: 140);

  void _onHoverEnter() {
    _closeDebounce?.cancel();
    if (!_hover) setState(() => _hover = true);
  }

  void _onHoverExit() {
    _closeDebounce?.cancel();
    _closeDebounce = Timer(_hoverCloseDelay, () {
      if (!mounted) return;
      if (_hover) setState(() => _hover = false);
    });
  }

  @override
  void dispose() {
    _closeDebounce?.cancel();
    super.dispose();
  }

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
              widget.config.sidebarViews.containsKey(state.activeActivityId);
          final activityBar = ActivityBar(
            items: widget.config.activityBarItems,
            config: widget.config,
          );
          final sidebarWidth = state.sidebarWidth ?? widget.config.sidebarWidth;

          if (!widget.config.collapsibleSidebar) {
            return Row(
              children: [
                activityBar,
                if (hasSidebar)
                  Expanded(
                    child: ResizableContainer(
                      sidebarWidth: sidebarWidth,
                      onResize: (width) => context
                          .read<WorkspaceBloc>()
                          .add(ResizeSidebar(width)),
                      sidebar: WorkspaceSidebar(config: widget.config),
                      content: const SplitEditor(),
                    ),
                  )
                else
                  const Expanded(child: SplitEditor()),
              ],
            );
          }

          // Collapsible / dock mode: activity bar is always visible; the
          // sidebar lives in the same Row as the editor and animates its
          // width in and out. The editor naturally reflows (and so do the
          // tabs above it) because Expanded takes the remaining space.
          //
          // The MouseRegion wraps ONLY the activity bar + sidebar block —
          // not the editor — so editor pointer events (tab clicks, body
          // clicks) are never intercepted. Inner Row uses MainAxisSize.min
          // so the MouseRegion's bounds line up exactly with the activity
          // bar + sidebar block; the moment the cursor crosses past the
          // sidebar's right edge into the editor it triggers onExit and
          // the dock collapses.
          final showSidebar = hasSidebar && _hover;
          return Row(
            children: [
              MouseRegion(
                opaque: false,
                // onHover fires on every pointer move within bounds — a
                // redundant trigger that fixes the first-load case where
                // onEnter would otherwise miss because Flutter web only
                // synthesizes a real enter event on actual movement.
                // Every subsequent move re-asserts the open state, so
                // even if onEnter misfires the cursor's next pixel of
                // travel inside the region opens the dock.
                onHover: (_) => _onHoverEnter(),
                onEnter: (_) => _onHoverEnter(),
                onExit: (_) => _onHoverExit(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    activityBar,
                    // ClipRect prevents the sidebar's natural contents from
                    // bleeding past the animated bounds while collapsing.
                    // OverflowBox + fixed-width SizedBox keep the sidebar
                    // rendering at its full natural width regardless of
                    // the parent constraint, so widgets inside don't
                    // re-layout to a 0-width column mid-animation.
                    ClipRect(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOutCubic,
                        width: showSidebar ? sidebarWidth : 0,
                        child: hasSidebar
                            ? OverflowBox(
                                alignment: Alignment.centerLeft,
                                minWidth: sidebarWidth,
                                maxWidth: sidebarWidth,
                                child: SizedBox(
                                  width: sidebarWidth,
                                  child:
                                      WorkspaceSidebar(config: widget.config),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: SplitEditor()),
            ],
          );
        },
      ),
    );
  }
}
