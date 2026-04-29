// `design` is provided transitively via the workspace; adding it to side's
// pubspec would couple the package to the host app's design system.
// ignore: depend_on_referenced_packages
import 'package:design/design.dart';
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
    return BlocSelector<WorkspaceBloc, WorkspaceState, String?>(
      selector: (state) => state.activeActivityId,
      builder: (context, activeActivity) {
        final sidebarView = activeActivity != null
            ? config.sidebarViews[activeActivity]
            : null;

        if (sidebarView == null) {
          return const _SidebarShell(
            child: Center(
              child: Text(
                'Select an activity',
                style: TextStyle(color: SalviaColors.inkMuted),
              ),
            ),
          );
        }

        return _SidebarShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SidebarHeader(view: sidebarView),
              const SizedBox(height: 12),
              Expanded(
                child: sidebarView.childBuilder != null
                    ? sidebarView.childBuilder!(context)
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
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

class _SidebarShell extends StatelessWidget {
  const _SidebarShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: SalviaColors.canvas,
        border: Border(
          right: BorderSide(color: SalviaColors.hairline),
        ),
      ),
      child: child,
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.view});

  final SidebarView view;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              view.title,
              style: SalviaTypography.bodyStrong.copyWith(
                color: SalviaColors.ink,
              ),
            ),
          ),
          for (final action in view.actions)
            IconButton(
              icon: Icon(action.icon, size: 16),
              color: SalviaColors.inkMuted,
              onPressed: action.onTap,
              tooltip: action.tooltip,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: const EdgeInsets.all(4),
              hoverColor: SalviaColors.surfaceMuted,
            ),
        ],
      ),
    );
  }
}

class _MenuGroupWidget extends StatelessWidget {
  const _MenuGroupWidget({required this.group, required this.config});

  final MenuGroup group;
  final WorkspaceConfig config;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkspaceBloc, WorkspaceState, bool>(
      selector: (state) => state.isGroupExpanded(group.id),
      builder: (context, isExpanded) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupHeader(
              group: group,
              isExpanded: isExpanded,
              onToggle: () => context.read<WorkspaceBloc>().add(
                ToggleSidebarGroup(group.id),
              ),
              onOpen: () {
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
                  context.read<WorkspaceBloc>().add(
                    ToggleSidebarGroup(group.id),
                  );
                }
              },
            ),
            if (isExpanded) ...[
              ...group.items.map(
                (item) =>
                    _MenuItemWidget(item: item, config: config, indentLevel: 1),
              ),
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

class _GroupHeader extends StatefulWidget {
  const _GroupHeader({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
    required this.onOpen,
  });
  final MenuGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  State<_GroupHeader> createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<_GroupHeader> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: _hovering ? SalviaColors.surfaceMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(SalviaRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(SalviaRadius.md),
          onTap: widget.onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                InkWell(
                  onTap: widget.onToggle,
                  borderRadius: BorderRadius.circular(SalviaRadius.xs),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      widget.isExpanded
                          ? PhosphorIconsRegular.caretDown
                          : PhosphorIconsRegular.caretRight,
                      size: 14,
                      color: SalviaColors.inkMuted,
                    ),
                  ),
                ),
                if (widget.group.icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    widget.group.icon,
                    size: 16,
                    color: SalviaColors.inkMuted,
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.group.label,
                    style: SalviaTypography.bodyStrong.copyWith(
                      color: SalviaColors.inkMuted,
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
}

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
    final subGroupKey = '$parentGroupId.${subGroup.id}';

    return BlocSelector<WorkspaceBloc, WorkspaceState, bool>(
      selector: (state) => state.isGroupExpanded(subGroupKey),
      builder: (context, isExpanded) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.read<WorkspaceBloc>().add(
                      ToggleSidebarGroup(subGroupKey),
                    ),
                    borderRadius: BorderRadius.circular(SalviaRadius.xs),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        isExpanded
                            ? PhosphorIconsRegular.caretDown
                            : PhosphorIconsRegular.caretRight,
                        size: 12,
                        color: SalviaColors.inkMuted,
                      ),
                    ),
                  ),
                  if (subGroup.icon != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      subGroup.icon,
                      size: 14,
                      color: SalviaColors.inkMuted,
                    ),
                  ],
                  const SizedBox(width: 8),
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
                          context.read<WorkspaceBloc>().add(
                            ToggleSidebarGroup(subGroupKey),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          subGroup.label,
                          style: SalviaTypography.bodyMain.copyWith(
                            color: SalviaColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

class _MenuItemWidget extends StatefulWidget {
  const _MenuItemWidget({
    required this.item,
    required this.config,
    required this.indentLevel,
  });

  final MenuItem item;
  final WorkspaceConfig config;
  final int indentLevel;

  @override
  State<_MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<_MenuItemWidget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final extraIndent = widget.indentLevel * 16.0;

    return Draggable<WorkspaceDragData>(
      data: WorkspaceDragData(
        pageId: widget.item.pageId,
        title: widget.item.label,
        icon: widget.item.icon,
        pageArgs: widget.item.pageArgs,
      ),
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(SalviaRadius.md),
        color: SalviaColors.canvas,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: 16, color: SalviaColors.ink),
                const SizedBox(width: 8),
              ],
              Text(
                widget.item.label,
                style: SalviaTypography.bodyMain.copyWith(
                  color: SalviaColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
      child: BlocSelector<WorkspaceBloc, WorkspaceState, bool>(
        selector: (state) =>
            state.activeTabId != null &&
            state.openTabs.any(
              (t) =>
                  t.id == state.activeTabId && t.pageId == widget.item.pageId,
            ),
        builder: (context, isActive) {
          final bg = isActive
              ? SalviaColors.primarySoft
              : (_hovering ? SalviaColors.surfaceMuted : Colors.transparent);
          final fg = isActive ? SalviaColors.primary : SalviaColors.inkMuted;
          final fontWeight = isActive ? FontWeight.w600 : FontWeight.w500;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovering = true),
              onExit: (_) => setState(() => _hovering = false),
              child: Material(
                color: bg,
                borderRadius: BorderRadius.circular(SalviaRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(SalviaRadius.md),
                  onTap: () => _handleItemTap(context),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      12 + extraIndent,
                      8,
                      12,
                      8,
                    ),
                    child: Row(
                      children: [
                        if (widget.item.icon != null) ...[
                          Icon(widget.item.icon, size: 18, color: fg),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            widget.item.label,
                            style: SalviaTypography.bodyMain.copyWith(
                              color: fg,
                              fontWeight: fontWeight,
                            ),
                          ),
                        ),
                        if (widget.item.shortcut != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            widget.item.shortcut!,
                            style: SalviaTypography.captionStd.copyWith(
                              color: SalviaColors.inkDim,
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

  void _handleItemTap(BuildContext context) {
    context.read<WorkspaceBloc>().add(
      OpenTab(
        pageId: widget.item.pageId,
        title: widget.item.label,
        icon: widget.item.icon,
        pageArgs: widget.item.pageArgs,
      ),
    );
  }
}
