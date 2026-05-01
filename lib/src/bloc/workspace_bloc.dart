import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:side/src/models/models.dart';
import 'package:uuid/uuid.dart';

part 'workspace_event.dart';
part 'workspace_state.dart';

/// Bloc to manage VS Code-like workspace state
///
/// Handles tab management, activity bar navigation, and sidebar state.
/// Follows BLoC pattern for reactive state management.
class WorkspaceBloc extends HydratedBloc<WorkspaceEvent, WorkspaceState> {
  /// Creates a [WorkspaceBloc] with workspace configuration
  ///
  /// [maxTabs] - Maximum number of tabs that can be open simultaneously
  WorkspaceBloc({required this.maxTabs}) : super(WorkspaceState()) {
    on<OpenTab>(_onOpenTab);
    on<CloseTab>(_onCloseTab);
    on<SwitchTab>(_onSwitchTab);
    on<MarkTabDirty>(_onMarkTabDirty);
    on<SwitchActivity>(_onSwitchActivity);
    on<ToggleSidebarGroup>(_onToggleSidebarGroup);
    on<ResizeSidebar>(_onResizeSidebar);
    on<ReorderTab>(_onReorderTab);
    on<CloseOthers>(_onCloseOthers);
    on<CloseAll>(_onCloseAll);
  }

  /// The maximum number of tabs allowed to be open simultaneously
  ///
  /// Prevents memory issues by limiting the number of active page widgets.
  final int maxTabs;

  /// UUID generator for creating unique tab IDs
  final _uuid = const Uuid();

  @override
  WorkspaceState? fromJson(Map<String, dynamic> json) {
    try {
      return WorkspaceState.fromJson(json);
      // Persisted state can be from a prior schema; ignore and start fresh.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(WorkspaceState state) {
    try {
      return state.toJson();
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  /// Handles opening a new tab or focusing an existing one
  ///
  /// Checks for existing tabs with the same pageId + args to prevent
  /// duplicates. Respects the maximum tab limit.
  Future<void> _onOpenTab(OpenTab event, Emitter<WorkspaceState> emit) async {
    final existingTab = state.openTabs.cast<TabData?>().firstWhere(
      (tab) =>
          tab?.pageId == event.pageId &&
          mapEquals(tab?.pageArgs, event.pageArgs),
      orElse: () => null,
    );

    if (existingTab != null) {
      emit(state.copyWith(activeTabId: existingTab.id));
      return;
    }

    if (state.openTabs.length >= maxTabs) {
      emit(
        state.copyWith(error: 'Maximum $maxTabs tabs open. Close a tab first.'),
      );
      return;
    }

    final newTab = TabData(
      id: _uuid.v4(),
      pageId: event.pageId,
      title: event.title,
      icon: event.icon,
      pageArgs: event.pageArgs,
    );

    emit(
      state.copyWith(
        openTabs: [...state.openTabs, newTab],
        activeTabId: newTab.id,
      ),
    );
  }

  /// Handles closing a specific tab
  Future<void> _onCloseTab(CloseTab event, Emitter<WorkspaceState> emit) async {
    final updatedTabs = state.openTabs
        .where((tab) => tab.id != event.tabId)
        .toList();

    var newActiveId = state.activeTabId;
    if (event.tabId == state.activeTabId) {
      newActiveId = updatedTabs.isNotEmpty ? updatedTabs.last.id : null;
    }

    emit(
      WorkspaceState(
        openTabs: updatedTabs,
        activeTabId: newActiveId,
        activeActivityId: state.activeActivityId,
        expandedGroups: state.expandedGroups,
        sidebarWidth: state.sidebarWidth,
      ),
    );
  }

  /// Handles switching focus to a specific tab
  Future<void> _onSwitchTab(
    SwitchTab event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(state.copyWith(activeTabId: event.tabId));
  }

  /// Handles marking a tab as dirty or clean
  Future<void> _onMarkTabDirty(
    MarkTabDirty event,
    Emitter<WorkspaceState> emit,
  ) async {
    final updatedTabs = state.openTabs.map((tab) {
      if (tab.id == event.tabId) {
        return tab.copyWith(isDirty: event.isDirty);
      }
      return tab;
    }).toList();

    emit(state.copyWith(openTabs: updatedTabs));
  }

  /// Handles switching the active activity bar item
  Future<void> _onSwitchActivity(
    SwitchActivity event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(state.copyWith(activeActivityId: event.activityId));
  }

  /// Handles toggling the expansion state of a sidebar group
  Future<void> _onToggleSidebarGroup(
    ToggleSidebarGroup event,
    Emitter<WorkspaceState> emit,
  ) async {
    final updatedGroups = Map<String, bool>.from(state.expandedGroups);
    updatedGroups[event.groupId] = !(updatedGroups[event.groupId] ?? false);

    emit(state.copyWith(expandedGroups: updatedGroups));
  }

  /// Handles resizing the sidebar
  Future<void> _onResizeSidebar(
    ResizeSidebar event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(state.copyWith(sidebarWidth: event.width));
  }

  /// Handles reordering a tab
  Future<void> _onReorderTab(
    ReorderTab event,
    Emitter<WorkspaceState> emit,
  ) async {
    final tabs = List<TabData>.from(state.openTabs);
    if (event.oldIndex < 0 ||
        event.oldIndex >= tabs.length ||
        event.newIndex < 0 ||
        event.newIndex > tabs.length) {
      return;
    }

    final tab = tabs.removeAt(event.oldIndex);
    final insertIndex = event.newIndex > event.oldIndex
        ? event.newIndex - 1
        : event.newIndex;
    tabs.insert(insertIndex, tab);

    emit(state.copyWith(openTabs: tabs));
  }

  /// Handles closing all other tabs except the specified one
  Future<void> _onCloseOthers(
    CloseOthers event,
    Emitter<WorkspaceState> emit,
  ) async {
    final keep = state.openTabs.where((t) => t.id == event.tabId).toList();
    if (keep.isEmpty) return;

    emit(state.copyWith(openTabs: keep, activeTabId: event.tabId));
  }

  /// Handles closing all tabs
  Future<void> _onCloseAll(
    CloseAll event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(
      WorkspaceState(
        activeActivityId: state.activeActivityId,
        expandedGroups: state.expandedGroups,
        sidebarWidth: state.sidebarWidth,
      ),
    );
  }
}
