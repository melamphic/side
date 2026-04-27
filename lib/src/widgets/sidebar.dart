import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:side/src/bloc/workspace_bloc.dart';
import 'package:side/src/models/models.dart';

/// VS Code-like sidebar widget
///
/// Displays hierarchical navigation content based on the active activity bar item.
/// Supports three levels of nesting: groups > sub-groups > items.
class WorkspaceSidebar extends StatelessWidget {
  /// Creates a [WorkspaceSidebar]
  const WorkspaceSidebar({required this.config, super.key});

  /// Workspace configuration containing sidebar views
  final WorkspaceConfig config;

  @override
  Widget build(BuildContext context) {
    // efficient selector to only rebuild when active activity changes
    return BlocSelector<WorkspaceBloc, WorkspaceState, String?>(
      selector: (state) => state.activeActivityId,
      builder: (context, activeActivity) {
        final sidebarView = activeActivity != null
            ? config.sidebarViews[activeActivity]
            : null;

        final colorScheme = Theme.of(context).colorScheme;
        if (sidebarView == null) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                right: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Center(
              child: Text(
                'Select an activity',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              right: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SidebarHeader(view: sidebarView, config: config),
              Expanded(
                child: sidebarView.childBuilder != null
                    ? sidebarView.childBuilder!(context)
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                          // Flat top-level items render first — used when an
                          // activity has no real grouping, so we don't wrap a
                          // single child list in a meaningless "Overview"
                          // collapsible.
                          for (final item in sidebarView.items)
                            _MenuItemWidget(
                              item: item,
                              config: config,
                              indentLevel: 0,
                            ),
                          for (final group in sidebarView.groups)
                            _MenuGroupWidget(group: group, config: config),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Header section of the sidebar
///
/// Shows the title and action buttons for the current sidebar view.
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.view, required this.config});

  final SidebarView view;
  final WorkspaceConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              view.title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: 1.4,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ...view.actions.map(
            (action) => IconButton(
              icon: Icon(action.icon, size: 16),
              onPressed: action.onTap,
              tooltip: action.tooltip,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              padding: const EdgeInsets.all(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget representing a top-level menu group
///
/// Can contain direct menu items and nested sub-groups.
/// Supports expand/collapse functionality.
class _MenuGroupWidget extends StatelessWidget {
  const _MenuGroupWidget({required this.group, required this.config});

  final MenuGroup group;
  final WorkspaceConfig config;

  @override
  Widget build(BuildContext context) {
    // Only rebuild this specific group when its expansion state changes
    return BlocSelector<WorkspaceBloc, WorkspaceState, bool>(
      selector: (state) => state.isGroupExpanded(group.id),
      builder: (context, isExpanded) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Expand/Collapse Toggle
                  InkWell(
                    onTap: () => context.read<WorkspaceBloc>().add(
                      ToggleSidebarGroup(group.id),
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 16,
                      ),
                    ),
                  ),
                  if (group.icon != null) ...[
                    const SizedBox(width: 4),
                    Icon(group.icon, size: 16),
                  ],
                  const SizedBox(width: 8),

                  // Group Label
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (group.pageId != null) {
                          context.read<WorkspaceBloc>().add(
                            OpenTab(
                              pageId: group.pageId!,
                              title: group.label,
                              icon: group.icon,
                              pageArgs: group.pageArgs,
                            ),
                          );
                        } else {
                          // Default behavior: Toggle expansion if not a page
                          context.read<WorkspaceBloc>().add(
                            ToggleSidebarGroup(group.id),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          group.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Group content (when expanded)
            if (isExpanded) ...[
              // Direct items in this group
              ...group.items.map(
                (item) =>
                    _MenuItemWidget(item: item, config: config, indentLevel: 1),
              ),

              // Sub-groups in this group
              ...group.subGroups.map(
                (subGroup) => _MenuSubGroupWidget(
                  subGroup: subGroup,
                  parentGroupId: group.id,
                  config: config,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Widget representing a nested sub-group within a menu group
///
/// Third level of hierarchy - can only contain menu items.
class _MenuSubGroupWidget extends StatelessWidget {
  const _MenuSubGroupWidget({
    required this.subGroup,
    required this.parentGroupId,
    required this.config,
  });

  final MenuSubGroup subGroup;
  final String parentGroupId;
  final WorkspaceConfig config;

  @override
  Widget build(BuildContext context) {
    // Optimization: Use BlocSelector to rebuild only when this specific subgroup expands/collapses
    final subGroupKey = '$parentGroupId.${subGroup.id}';

    return BlocSelector<WorkspaceBloc, WorkspaceState, bool>(
      selector: (state) => state.isGroupExpanded(subGroupKey),
      builder: (context, isExpanded) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-group header
            Container(
              padding: const EdgeInsets.only(
                left: 32,
                right: 12,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  // Expand/Collapse Toggle
                  InkWell(
                    onTap: () => context.read<WorkspaceBloc>().add(
                      ToggleSidebarGroup(subGroupKey),
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 14,
                      ),
                    ),
                  ),
                  if (subGroup.icon != null) ...[
                    const SizedBox(width: 4),
                    Icon(subGroup.icon, size: 14),
                  ],
                  const SizedBox(width: 6),

                  // Sub-group Label
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (subGroup.pageId != null) {
                          context.read<WorkspaceBloc>().add(
                            OpenTab(
                              pageId: subGroup.pageId!,
                              title: subGroup.label,
                              icon: subGroup.icon,
                              pageArgs: subGroup.pageArgs,
                            ),
                          );
                        } else {
                          // Default behavior: Toggle expansion
                          context.read<WorkspaceBloc>().add(
                            ToggleSidebarGroup(subGroupKey),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          subGroup.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sub-group items (when expanded)
            if (isExpanded)
              ...subGroup.items.map(
                (item) =>
                    _MenuItemWidget(item: item, config: config, indentLevel: 2),
              ),
          ],
        );
      },
    );
  }
}

/// Widget representing a clickable menu item
///
/// Opens the associated page in a new tab when clicked.
/// Supports different indentation levels based on hierarchy.
class _MenuItemWidget extends StatelessWidget {
  const _MenuItemWidget({
    required this.item,
    required this.config,
    required this.indentLevel,
  });

  final MenuItem item;
  final WorkspaceConfig config;
  final int indentLevel;

  @override
  Widget build(BuildContext context) {
    final leftPadding = 12.0 + (indentLevel * 20.0);

    return Draggable<WorkspaceDragData>(
      data: WorkspaceDragData(
        pageId: item.pageId,
        title: item.label,
        icon: item.icon,
        pageArgs: item.pageArgs,
      ),
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 16),
                const SizedBox(width: 8),
              ],
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      child: BlocSelector<WorkspaceBloc, WorkspaceState, bool>(
        selector: (state) => state.activeTabId != null &&
            state.openTabs.any(
              (t) => t.id == state.activeTabId && t.pageId == item.pageId,
            ),
        builder: (context, isActive) {
          final colorScheme = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _handleItemTap(context),
                child: Ink(
                  decoration: BoxDecoration(
                    color: isActive ? colorScheme.primaryContainer : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: leftPadding - 4,
                      right: 12,
                      top: 8,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          Icon(
                            item.icon,
                            size: 18,
                            color: isActive
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isActive
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (item.shortcut != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            item.shortcut!,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Handles tapping on a menu item
  ///
  /// Opens the associated page in a new tab, or focuses existing tab.
  void _handleItemTap(BuildContext context) {
    context.read<WorkspaceBloc>().add(
      OpenTab(
        pageId: item.pageId,
        title: item.label,
        icon: item.icon,
        pageArgs: item.pageArgs,
      ),
    );
  }
}
