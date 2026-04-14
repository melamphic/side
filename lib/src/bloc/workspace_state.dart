part of 'workspace_bloc.dart';

/// State of the VS Code-like workspace
///
/// Manages all workspace-level state including activity bar selection,
/// open tabs across multiple panes, sidebar expansion state, and split configuration.
class WorkspaceState extends Equatable {
  /// Creates a [WorkspaceState] with default configuration
  WorkspaceState({
    this.openTabs = const [],
    this.activeTabId,
    this.activeActivityId,
    this.activePaneIndex = 0,
    this.expandedGroups = const {},
    this.splitConfiguration = const SplitConfiguration(),
    this.tabsByPane = const {0: []},
    this.activeTabByPane = const {},
    this.error,
    this.sidebarWidth,
  }) : _tabMap = {for (final tab in openTabs) tab.id: tab};

  /// Creates a [WorkspaceState] instance from a JSON map
  factory WorkspaceState.fromJson(Map<String, dynamic> json) {
    return WorkspaceState(
      openTabs:
          (json['openTabs'] as List<dynamic>?)
              ?.map((e) => TabData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeTabId: json['activeTabId'] as String?,
      activeActivityId: json['activeActivityId'] as String?,
      activePaneIndex: json['activePaneIndex'] as int? ?? 0,
      expandedGroups:
          (json['expandedGroups'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          const {},
      splitConfiguration: json['splitConfiguration'] != null
          ? SplitConfiguration.fromJson(
              json['splitConfiguration'] as Map<String, dynamic>,
            )
          : const SplitConfiguration(),
      tabsByPane:
          (json['tabsByPane'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              int.parse(k),
              (v as List<dynamic>).cast<String>(),
            ),
          ) ??
          const {0: []},
      activeTabByPane:
          (json['activeTabByPane'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), v as String),
          ) ??
          const {},
      sidebarWidth: json['sidebarWidth'] as double?,
    );
  }

  /// All currently open tabs across all panes
  ///
  /// Tabs persist even when switching between activity bar items,
  /// maintaining the user's workspace state.
  final List<TabData> openTabs;

  /// ID of the currently focused tab
  ///
  /// Used to highlight the active tab and determine which content to show.
  final String? activeTabId;

  /// ID of the currently selected activity bar item
  ///
  /// Determines which sidebar view is displayed.
  final String? activeActivityId;

  /// Index of the currently focused split pane
  ///
  /// Used for tab operations and keyboard navigation.
  final int activePaneIndex;

  /// Expansion state of sidebar groups and sub-groups
  ///
  /// Key format: "groupId" or "groupId.subGroupId" for nested items.
  final Map<String, bool> expandedGroups;

  /// Configuration for split editor panes
  ///
  /// Defines how many panes are open and their size ratios.
  final SplitConfiguration splitConfiguration;

  /// Tab organization by split pane
  ///
  /// Key is pane index, value is list of tab IDs in that pane.
  final Map<int, List<String>> tabsByPane;

  /// Active tab ID for each pane index
  final Map<int, String> activeTabByPane;

  /// Width of the sidebar (if resized by user)
  final double? sidebarWidth;

  /// Current error message, if any
  ///
  /// Displayed to the user via snackbar or error dialog.
  final String? error;

  /// Creates a copy of this state with modified values
  WorkspaceState copyWith({
    List<TabData>? openTabs,
    String? activeTabId,
    String? activeActivityId,
    int? activePaneIndex,
    Map<String, bool>? expandedGroups,
    SplitConfiguration? splitConfiguration,
    Map<int, List<String>>? tabsByPane,
    Map<int, String>? activeTabByPane,
    double? sidebarWidth,
    String? error,
  }) {
    return WorkspaceState(
      openTabs: openTabs ?? this.openTabs,
      activeTabId: activeTabId ?? this.activeTabId,
      activeActivityId: activeActivityId ?? this.activeActivityId,
      activePaneIndex: activePaneIndex ?? this.activePaneIndex,
      expandedGroups: expandedGroups ?? this.expandedGroups,
      splitConfiguration: splitConfiguration ?? this.splitConfiguration,
      tabsByPane: tabsByPane ?? this.tabsByPane,
      activeTabByPane: activeTabByPane ?? this.activeTabByPane,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      error: error,
    );
  }

  /// internal cache for id lookups
  final Map<String, TabData> _tabMap;

  Map<String, TabData> get _tabsById => _tabMap;

  /// Gets the currently active tab, if any
  ///
  /// Returns null if no tab is active or the active tab doesn't exist.
  TabData? getActiveTab() {
    if (activeTabId == null) return null;
    return _tabsById[activeTabId];
  }

  /// Gets all tabs in a specific pane
  ///
  /// Returns the actual TabData objects for the given pane index.
  /// Respects the order defined in tabsByPane.
  List<TabData> getTabsInPane(int paneIndex) {
    final tabIds = tabsByPane[paneIndex];
    if (tabIds == null || tabIds.isEmpty) return const [];

    final tabMap = _tabsById;
    return tabIds.map((id) => tabMap[id]).whereType<TabData>().toList();
  }

  /// Gets the pane index containing a specific tab
  ///
  /// Returns null if the tab is not found in any pane.
  int? getPaneForTab(String tabId) {
    for (final entry in tabsByPane.entries) {
      if (entry.value.contains(tabId)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Checks if a sidebar group is expanded
  ///
  /// Supports nested groups with dot notation (e.g., "group.subgroup").
  bool isGroupExpanded(String groupId) {
    return expandedGroups[groupId] ?? false;
  }

  /// Gets the active tab for a specific pane
  ///
  /// Each pane independently tracks its own active tab.
  TabData? getActiveTabInPane(int paneIndex) {
    // Use per-pane active tab
    final paneActiveId = activeTabByPane[paneIndex];
    if (paneActiveId != null && _tabsById.containsKey(paneActiveId)) {
      return _tabsById[paneActiveId];
    }

    // Fallback: if pane has tabs but no recorded active, show the last one
    final paneTabs = tabsByPane[paneIndex];
    if (paneTabs != null && paneTabs.isNotEmpty) {
      return _tabsById[paneTabs.last];
    }

    return null;
  }

  /// Converts the [WorkspaceState] instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'openTabs': openTabs.map((e) => e.toJson()).toList(),
      'activeTabId': activeTabId,
      'activeActivityId': activeActivityId,
      'activePaneIndex': activePaneIndex,
      'expandedGroups': expandedGroups,
      'splitConfiguration': splitConfiguration.toJson(),
      'tabsByPane': tabsByPane.map((k, v) => MapEntry(k.toString(), v)),
      'activeTabByPane': activeTabByPane.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    };
  }

  @override
  List<Object?> get props => [
    openTabs,
    activeTabId,
    activeActivityId,
    activePaneIndex,
    expandedGroups,
    splitConfiguration,
    tabsByPane,
    activeTabByPane,
    error,
  ];
}
