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
/// Handles tab management across multiple split panes, activity bar navigation,
/// sidebar state, and split view configuration. Follows BLoC pattern for
/// reactive state management.
class WorkspaceBloc extends HydratedBloc<WorkspaceEvent, WorkspaceState> {
  /// Creates a [WorkspaceBloc] with workspace configuration
  ///
  /// [maxTabs] - Maximum number of tabs that can be open simultaneously
  /// [maxVerticalSplits] - Maximum number of vertical editor splits allowed
  WorkspaceBloc({required this.maxTabs, this.maxVerticalSplits = 2})
    : super(WorkspaceState()) {
    on<OpenTab>(_onOpenTab);
    on<CloseTab>(_onCloseTab);
    on<SwitchTab>(_onSwitchTab);
    on<MarkTabDirty>(_onMarkTabDirty);
    on<SwitchActivity>(_onSwitchActivity);
    on<ToggleSidebarGroup>(_onToggleSidebarGroup);
    on<ResizeSidebar>(_onResizeSidebar);
    on<ReorderTab>(_onReorderTab);
    on<MoveTabToPane>(_onMoveTabToPane);
    on<CloseOthers>(_onCloseOthers);
    on<CloseAll>(_onCloseAll);
    on<SplitView>(_onSplitEditor);
    on<CloseSplit>(_onCloseSplit);
    on<ResizeSplit>(_onResizeSplit);
    on<SetActivePane>(_onSetActivePane);
  }

  /// The maximum number of tabs allowed to be open simultaneously
  ///
  /// Prevents memory issues by limiting the number of active page widgets.
  final int maxTabs;

  /// Maximum number of vertical splits allowed
  ///
  /// Limits UI complexity and maintains usability.
  final int maxVerticalSplits;

  /// UUID generator for creating unique tab IDs
  final _uuid = const Uuid();

  @override
  WorkspaceState? fromJson(Map<String, dynamic> json) {
    try {
      return WorkspaceState.fromJson(json);

      ///
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(WorkspaceState state) {
    try {
      return state.toJson();

      ///
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  /// Handles opening a new tab or focusing an existing one
  ///
  /// Checks for existing tabs with the same pageId to prevent duplicates.
  /// Respects the maximum tab limit and split pane configuration.
  Future<void> _onOpenTab(OpenTab event, Emitter<WorkspaceState> emit) async {
    // Check if tab with same pageId AND same args already exists
    final existingTab = state.openTabs.cast<TabData?>().firstWhere(
      (tab) =>
          tab?.pageId == event.pageId &&
          mapEquals(tab?.pageArgs, event.pageArgs),
      orElse: () => null,
    );

    if (existingTab != null) {
      // Focus existing tab
      final paneIndex = state.getPaneForTab(existingTab.id) ?? 0;

      // Update per-pane active tab
      final updatedActiveTabByPane = Map<int, String>.from(
        state.activeTabByPane,
      );
      updatedActiveTabByPane[paneIndex] = existingTab.id;

      emit(
        state.copyWith(
          activeTabId: existingTab.id,
          activePaneIndex: paneIndex,
          activeTabByPane: updatedActiveTabByPane,
        ),
      );
      return;
    }

    // Check tab limit
    if (state.openTabs.length >= maxTabs) {
      emit(
        state.copyWith(error: 'Maximum $maxTabs tabs open. Close a tab first.'),
      );
      return;
    }

    // Create new tab
    final newTab = TabData(
      id: _uuid.v4(),
      pageId: event.pageId,
      title: event.title,
      icon: event.icon,
      pageArgs: event.pageArgs,
    );

    // Add to specified pane or active pane
    final targetPane = (event.paneIndex ?? state.activePaneIndex).clamp(
      0,
      state.splitConfiguration.splitCount - 1,
    );
    final updatedTabsByPane = Map<int, List<String>>.from(state.tabsByPane);
    updatedTabsByPane[targetPane] = [
      ...(updatedTabsByPane[targetPane] ?? []),
      newTab.id,
    ];

    // Update per-pane active tab
    final updatedActiveTabByPane = Map<int, String>.from(state.activeTabByPane);
    updatedActiveTabByPane[targetPane] = newTab.id;

    emit(
      state.copyWith(
        openTabs: [...state.openTabs, newTab],
        activeTabId: newTab.id,
        activePaneIndex: targetPane,
        tabsByPane: updatedTabsByPane,
        activeTabByPane: updatedActiveTabByPane,
      ),
    );
  }

  /// Handles setting the active pane index
  Future<void> _onSetActivePane(
    SetActivePane event,
    Emitter<WorkspaceState> emit,
  ) async {
    // Only update if index is valid
    if (event.paneIndex >= 0 &&
        event.paneIndex < state.splitConfiguration.splitCount) {
      emit(state.copyWith(activePaneIndex: event.paneIndex));
    }
  }

  /// Handles closing a specific tab
  ///
  /// Removes the tab from all panes and updates the active tab if necessary.
  Future<void> _onCloseTab(CloseTab event, Emitter<WorkspaceState> emit) async {
    final updatedTabs = state.openTabs
        .where((tab) => tab.id != event.tabId)
        .toList();

    // Remove from all panes
    final updatedTabsByPane = <int, List<String>>{};
    for (final entry in state.tabsByPane.entries) {
      updatedTabsByPane[entry.key] = entry.value
          .where((id) => id != event.tabId)
          .toList();
    }

    // Update per-pane active tabs
    final updatedActiveTabByPane = Map<int, String>.from(state.activeTabByPane);
    for (final entry in updatedActiveTabByPane.entries.toList()) {
      if (entry.value == event.tabId) {
        // This pane's active tab was closed, pick the last remaining tab
        final remaining = updatedTabsByPane[entry.key] ?? [];
        if (remaining.isNotEmpty) {
          updatedActiveTabByPane[entry.key] = remaining.last;
        } else {
          updatedActiveTabByPane.remove(entry.key);
        }
      }
    }

    // Update global active tab if the closed tab was active
    var newActiveId = state.activeTabId;
    var newActivePaneIndex = state.activePaneIndex;

    if (event.tabId == state.activeTabId) {
      final currentPaneTabs = updatedTabsByPane[state.activePaneIndex] ?? [];

      if (currentPaneTabs.isNotEmpty) {
        newActiveId = currentPaneTabs.last;
      } else {
        newActiveId = null;
        for (final entry in updatedTabsByPane.entries) {
          if (entry.value.isNotEmpty) {
            newActiveId = entry.value.last;
            newActivePaneIndex = entry.key;
            break;
          }
        }
      }
    }

    emit(
      state.copyWith(
        openTabs: updatedTabs,
        activeTabId: newActiveId,
        activePaneIndex: newActivePaneIndex,
        tabsByPane: updatedTabsByPane,
        activeTabByPane: updatedActiveTabByPane,
      ),
    );
  }

  /// Handles switching focus to a specific tab
  ///
  /// Updates the active tab and potentially the active pane.
  Future<void> _onSwitchTab(
    SwitchTab event,
    Emitter<WorkspaceState> emit,
  ) async {
    // Find which pane contains this tab
    final paneIndex = state.getPaneForTab(event.tabId) ?? state.activePaneIndex;
    final targetPaneIndex = event.paneIndex ?? paneIndex;

    // Update per-pane active tab
    final updatedActiveTabByPane = Map<int, String>.from(state.activeTabByPane);
    updatedActiveTabByPane[targetPaneIndex] = event.tabId;

    emit(
      state.copyWith(
        activeTabId: event.tabId,
        activePaneIndex: targetPaneIndex,
        activeTabByPane: updatedActiveTabByPane,
      ),
    );
  }

  /// Handles marking a tab as dirty or clean
  ///
  /// Updates the visual indicator for unsaved changes.
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
  ///
  /// Changes the sidebar content without affecting open tabs.
  Future<void> _onSwitchActivity(
    SwitchActivity event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(state.copyWith(activeActivityId: event.activityId));
  }

  /// Handles toggling the expansion state of a sidebar group
  ///
  /// Supports nested groups and sub-groups.
  Future<void> _onToggleSidebarGroup(
    ToggleSidebarGroup event,
    Emitter<WorkspaceState> emit,
  ) async {
    final updatedGroups = Map<String, bool>.from(state.expandedGroups);
    updatedGroups[event.groupId] = !(updatedGroups[event.groupId] ?? false);

    emit(state.copyWith(expandedGroups: updatedGroups));
  }

  /// Handles splitting the editor vertically
  ///
  /// Creates a new pane for side-by-side tab viewing.
  Future<void> _onSplitEditor(
    SplitView event,
    Emitter<WorkspaceState> emit,
  ) async {
    final currentSplitCount = state.splitConfiguration.splitCount;

    // Check split limit
    if (currentSplitCount >= maxVerticalSplits) {
      emit(state.copyWith(error: 'Maximum $maxVerticalSplits splits allowed.'));
      return;
    }

    final newSplitCount = currentSplitCount + 1;
    final newRatios = List.generate(
      newSplitCount,
      (index) => 1.0 / newSplitCount,
    );

    final newSplitConfig = state.splitConfiguration.copyWith(
      splitCount: newSplitCount,
      splitRatios: newRatios,
    );

    // Initialize new pane in tabsByPane
    final updatedTabsByPane = Map<int, List<String>>.from(state.tabsByPane);
    updatedTabsByPane[newSplitCount - 1] = [];

    emit(
      state.copyWith(
        splitConfiguration: newSplitConfig,
        tabsByPane: updatedTabsByPane,
      ),
    );
  }

  /// Handles closing a split pane
  ///
  /// Merges tabs from the closing pane into the primary pane (index 0)
  /// to avoid data loss.
  Future<void> _onCloseSplit(
    CloseSplit event,
    Emitter<WorkspaceState> emit,
  ) async {
    if (state.splitConfiguration.splitCount <= 1) {
      return; // Can't close the last pane
    }

    // Tabs in the pane being closed
    final closingPaneTabs = state.tabsByPane[event.paneIndex] ?? [];

    // Rebuild tabsByPane without the closing pane
    final updatedTabsByPane = <int, List<String>>{};
    final tempPanes = <List<String>>[];

    for (final entry in state.tabsByPane.entries) {
      if (entry.key != event.paneIndex) {
        tempPanes.add(entry.value);
      }
    }

    // Merge tabs from closed pane into the FIRST remaining pane to avoid loss
    if (tempPanes.isNotEmpty) {
      tempPanes[0] = [...tempPanes[0], ...closingPaneTabs];
    }

    for (var i = 0; i < tempPanes.length; i++) {
      updatedTabsByPane[i] = tempPanes[i];
    }

    // Rebuild activeTabByPane without the closing pane
    final updatedActiveTabByPane = <int, String>{};
    var newIndex = 0;
    for (final entry in state.activeTabByPane.entries) {
      if (entry.key != event.paneIndex) {
        updatedActiveTabByPane[newIndex] = entry.value;
        newIndex++;
      }
    }

    final newSplitCount = state.splitConfiguration.splitCount - 1;

    // Adjust ratios - if going back to 1, it's just [1.0]
    final List<double> newRatios;
    if (newSplitCount == 1) {
      newRatios = [1.0];
    } else {
      // For more than 2 splits (if supported in future), we'd need more complex logic
      // For now, since max is 2, it's always [1.0]
      newRatios = List.generate(newSplitCount, (index) => 1.0 / newSplitCount);
    }

    final newActivePaneIndex = state.activePaneIndex >= newSplitCount
        ? 0
        : state.activePaneIndex;

    // Update global activeTabId
    // If the closed pane was active, or its active tab was the global active tab
    var newActiveTabId = state.activeTabId;
    if (event.paneIndex == state.activePaneIndex ||
        closingPaneTabs.contains(state.activeTabId)) {
      newActiveTabId =
          updatedActiveTabByPane[newActivePaneIndex] ??
          (updatedTabsByPane[newActivePaneIndex]?.isNotEmpty ?? false
              ? updatedTabsByPane[newActivePaneIndex]!.first
              : null);
    }

    emit(
      state.copyWith(
        splitConfiguration: state.splitConfiguration.copyWith(
          splitCount: newSplitCount,
          splitRatios: newRatios,
          activePane: newActivePaneIndex,
        ),
        tabsByPane: updatedTabsByPane,
        activeTabByPane: updatedActiveTabByPane,
        activePaneIndex: newActivePaneIndex,
        activeTabId: newActiveTabId,
      ),
    );
  }

  /// Handles resizing split panes
  ///
  /// Updates the width ratios for each pane.
  Future<void> _onResizeSplit(
    ResizeSplit event,
    Emitter<WorkspaceState> emit,
  ) async {
    if (event.splitRatios.length != state.splitConfiguration.splitCount) {
      return; // Invalid ratio count
    }

    // Ensure ratios sum to approximately 1.0
    final sum = event.splitRatios.reduce((a, b) => a + b);
    if ((sum - 1.0).abs() > 0.01) {
      return; // Ratios don't sum to 1.0
    }

    final newSplitConfig = state.splitConfiguration.copyWith(
      splitRatios: event.splitRatios,
    );

    emit(state.copyWith(splitConfiguration: newSplitConfig));
  }

  /// Handles resizing the sidebar
  Future<void> _onResizeSidebar(
    ResizeSidebar event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(state.copyWith(sidebarWidth: event.width));
  }

  /// Handles reordering a tab within a pane
  Future<void> _onReorderTab(
    ReorderTab event,
    Emitter<WorkspaceState> emit,
  ) async {
    final currentTabs = List<String>.from(
      state.tabsByPane[event.paneIndex] ?? [],
    );
    if (event.oldIndex < 0 ||
        event.oldIndex >= currentTabs.length ||
        event.newIndex < 0 ||
        event.newIndex > currentTabs.length) {
      return;
    }

    final tabId = currentTabs.removeAt(event.oldIndex);
    final insertIndex = event.newIndex > event.oldIndex
        ? event.newIndex - 1
        : event.newIndex;
    currentTabs.insert(insertIndex, tabId);

    final newTabsByPane = Map<int, List<String>>.from(state.tabsByPane);
    newTabsByPane[event.paneIndex] = currentTabs;

    emit(state.copyWith(tabsByPane: newTabsByPane));
  }

  /// Handles moving a tab to a different pane
  Future<void> _onMoveTabToPane(
    MoveTabToPane event,
    Emitter<WorkspaceState> emit,
  ) async {
    int? sourcePaneIndex;
    for (final entry in state.tabsByPane.entries) {
      if (entry.value.contains(event.tabId)) {
        sourcePaneIndex = entry.key;
        break;
      }
    }

    if (sourcePaneIndex == null || sourcePaneIndex == event.targetPaneIndex) {
      return;
    }

    final newTabsByPane = Map<int, List<String>>.from(state.tabsByPane);

    // Remove from source
    final sourceTabs = List<String>.from(newTabsByPane[sourcePaneIndex]!)
      ..remove(event.tabId);
    newTabsByPane[sourcePaneIndex] = sourceTabs;

    // Add to target
    final targetTabs = List<String>.from(
      newTabsByPane[event.targetPaneIndex] ?? [],
    )..add(event.tabId);
    newTabsByPane[event.targetPaneIndex] = targetTabs;

    emit(
      state.copyWith(
        tabsByPane: newTabsByPane,
        activePaneIndex: event.targetPaneIndex,
        activeTabId: event.tabId,
      ),
    );
  }

  /// Handles closing all other tabs in a pane
  Future<void> _onCloseOthers(
    CloseOthers event,
    Emitter<WorkspaceState> emit,
  ) async {
    final paneTabs = state.tabsByPane[event.paneIndex] ?? [];
    if (!paneTabs.contains(event.tabId)) return;

    final tabsToRemove = paneTabs.where((id) => id != event.tabId).toList();
    if (tabsToRemove.isEmpty) return;

    final newOpenTabs = List<TabData>.from(state.openTabs)
      ..removeWhere((tab) => tabsToRemove.contains(tab.id));

    final newTabsByPane = Map<int, List<String>>.from(state.tabsByPane);
    newTabsByPane[event.paneIndex] = [event.tabId];

    // If active tab was one of the removed ones, switch to the kept tab
    var newActiveTabId = state.activeTabId;
    if (tabsToRemove.contains(state.activeTabId)) {
      newActiveTabId = event.tabId;
    }

    emit(
      state.copyWith(
        openTabs: newOpenTabs,
        tabsByPane: newTabsByPane,
        activeTabId: newActiveTabId,
      ),
    );
  }

  /// Handles closing all tabs in a pane
  Future<void> _onCloseAll(
    CloseAll event,
    Emitter<WorkspaceState> emit,
  ) async {
    final paneTabs = state.tabsByPane[event.paneIndex] ?? [];
    if (paneTabs.isEmpty) return;

    final newOpenTabs = List<TabData>.from(state.openTabs)
      ..removeWhere((tab) => paneTabs.contains(tab.id));

    final newTabsByPane = Map<int, List<String>>.from(state.tabsByPane);
    newTabsByPane[event.paneIndex] = [];

    // Validating active tab
    var newActiveTabId = state.activeTabId;
    if (paneTabs.contains(state.activeTabId)) {
      newActiveTabId =
          null; // No active tab if we closed the pane containing it
      // Logic could be improved to find another tab in another pane, but null is safe
    }

    emit(
      state.copyWith(
        openTabs: newOpenTabs,
        tabsByPane: newTabsByPane,
        activeTabId: newActiveTabId,
      ),
    );
  }
}
