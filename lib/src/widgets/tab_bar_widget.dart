// `design` is provided transitively via the workspace; adding it to side's
// pubspec would couple the package to the host app's design system.
// ignore: depend_on_referenced_packages
import 'package:design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:side/side.dart';

/// Tab bar widget for the editor
///
/// Shows tabs with active state and close buttons. Supports drag-and-drop
/// reordering.
class WorkspaceTabBar extends StatelessWidget {
  /// Creates a [WorkspaceTabBar]
  const WorkspaceTabBar({
    required this.tabs,
    required this.activeTab,
    super.key,
  });

  /// Tabs to display
  final List<TabData> tabs;

  /// Currently active tab
  final TabData? activeTab;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: SalviaColors.canvas,
        border: Border(
          bottom: BorderSide(color: SalviaColors.hairline),
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < tabs.length; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 4, top: 16),
                  child: _DocumentTabChip(
                    tab: tabs[i],
                    isActive: tabs[i].id == activeTab?.id,
                    index: i,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabDragData {
  const _TabDragData({required this.tabId, required this.index});

  final String tabId;
  final int index;
}

class _DocumentTabChip extends StatefulWidget {
  const _DocumentTabChip({
    required this.tab,
    required this.isActive,
    required this.index,
  });

  final TabData tab;
  final bool isActive;
  final int index;

  @override
  State<_DocumentTabChip> createState() => _DocumentTabChipState();
}

class _DocumentTabChipState extends State<_DocumentTabChip> {
  bool _hoverClose = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_TabDragData>(
      onWillAcceptWithDetails: (details) => details.data.tabId != widget.tab.id,
      onAcceptWithDetails: (details) {
        context.read<WorkspaceBloc>().add(
          ReorderTab(oldIndex: details.data.index, newIndex: widget.index),
        );
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<_TabDragData>(
          data: _TabDragData(tabId: widget.tab.id, index: widget.index),
          feedback: Material(
            elevation: 4,
            color: Colors.transparent,
            child: _chip(isFeedback: true),
          ),
          childWhenDragging: Opacity(opacity: 0.5, child: _chip()),
          child: _chip(isTarget: candidateData.isNotEmpty),
        );
      },
    );
  }

  Widget _chip({bool isTarget = false, bool isFeedback = false}) {
    final bgColor = widget.isActive
        ? SalviaColors.canvas
        : (isTarget ? SalviaColors.primarySoft : const Color(0xFFF1F5F9));
    final textColor = widget.isActive ? SalviaColors.ink : SalviaColors.inkMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(SalviaRadius.md),
          topRight: Radius.circular(SalviaRadius.md),
        ),
        onTap: () {
          context.read<WorkspaceBloc>().add(SwitchTab(tabId: widget.tab.id));
        },
        onSecondaryTapUp: (details) async {
          await _showContextMenu(context, details.globalPosition);
        },
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 240),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: SalviaColors.hairline),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(SalviaRadius.md),
              topRight: Radius.circular(SalviaRadius.md),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.tab.icon != null) ...[
                Icon(widget.tab.icon, size: 14, color: textColor),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.tab.title,
                  overflow: TextOverflow.ellipsis,
                  style: SalviaTypography.captionStd.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (widget.tab.isDirty) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: SalviaColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              if (!isFeedback)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hoverClose = true),
                  onExit: (_) => setState(() => _hoverClose = false),
                  child: Material(
                    color: _hoverClose
                        ? SalviaColors.surfaceMuted
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        context
                            .read<WorkspaceBloc>()
                            .add(CloseTab(widget.tab.id));
                      },
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: _hoverClose
                              ? SalviaColors.ink
                              : SalviaColors.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
          onTap: () => bloc.add(CloseTab(widget.tab.id)),
          child: const Text('Close'),
        ),
        PopupMenuItem<String>(
          value: 'close_others',
          onTap: () => bloc.add(CloseOthers(tabId: widget.tab.id)),
          child: const Text('Close Others'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'close_all',
          onTap: () => bloc.add(const CloseAll()),
          child: const Text('Close All'),
        ),
      ],
    );
  }
}
