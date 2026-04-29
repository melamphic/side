// `design` is provided transitively via the workspace; adding it to side's
// pubspec would couple the package to the host app's design system.
// ignore: depend_on_referenced_packages
import 'package:design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:side/src/bloc/workspace_bloc.dart';
import 'package:side/src/models/models.dart';

/// VS Code-like activity bar widget
///
/// Displays the main navigation items as icon buttons in a vertical column.
/// Clicking an item switches the sidebar content and maintains tab state.
class ActivityBar extends StatelessWidget {
  /// Creates an [ActivityBar]
  const ActivityBar({required this.items, required this.config, super.key});

  /// List of activity bar items to display
  final List<ActivityBarItem> items;

  /// Workspace configuration
  final WorkspaceConfig config;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceBloc, WorkspaceState>(
      builder: (context, state) {
        return Container(
          width: config.activityBarWidth,
          decoration: const BoxDecoration(
            color: SalviaColors.canvas,
            border: Border(
              right: BorderSide(color: SalviaColors.hairline),
            ),
          ),
          child: Column(
            children: [
              const _BrandMark(),
              Expanded(
                child: Column(
                  children: [
                    for (final item in items)
                      _ActivityBarButton(
                        width: config.activityBarWidth,
                        item: item,
                        isActive: state.activeActivityId == item.id,
                        onTap: () => context.read<WorkspaceBloc>().add(
                          SwitchActivity(item.id),
                        ),
                      ),
                  ],
                ),
              ),
              const _BottomAvatar(),
            ],
          ),
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24, bottom: 32),
      child: Icon(
        PhosphorIconsFill.heartbeat,
        size: 28,
        color: SalviaColors.primary,
      ),
    );
  }
}

class _BottomAvatar extends StatelessWidget {
  const _BottomAvatar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: SalviaColors.surfaceMuted,
          borderRadius: BorderRadius.circular(SalviaRadius.full),
          border: Border.all(color: SalviaColors.hairline),
        ),
        alignment: Alignment.center,
        child: const Icon(
          PhosphorIconsRegular.user,
          size: 16,
          color: SalviaColors.inkMuted,
        ),
      ),
    );
  }
}

class _ActivityBarButton extends StatefulWidget {
  const _ActivityBarButton({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.width,
  });

  final ActivityBarItem item;
  final bool isActive;
  final VoidCallback onTap;
  final double width;

  @override
  State<_ActivityBarButton> createState() => _ActivityBarButtonState();
}

class _ActivityBarButtonState extends State<_ActivityBarButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isActive
        ? SalviaColors.primary
        : (_hovering ? SalviaColors.inkMuted : SalviaColors.inkDim);

    return Tooltip(
      message: widget.item.tooltip ?? widget.item.label,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: SizedBox(
              width: widget.width,
              height: 24,
              child: Stack(
                children: [
                  if (widget.isActive)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: const BoxDecoration(
                          color: SalviaColors.primary,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(SalviaRadius.full),
                            bottomRight: Radius.circular(SalviaRadius.full),
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: widget.item.itemContentBuilder != null
                        ? widget.item.itemContentBuilder!(
                            context,
                            isActive: widget.isActive,
                          )
                        : Icon(
                            widget.item.icon,
                            size: 22,
                            color: iconColor,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
