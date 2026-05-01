part of 'workspace_bloc.dart';

/// State of the VS Code-like workspace
///
/// Manages all workspace-level state including activity bar selection,
/// open tabs, and sidebar expansion state.
class WorkspaceState extends Equatable {
  /// Creates a [WorkspaceState] with default configuration
  WorkspaceState({
    this.openTabs = const [],
    this.activeTabId,
    this.activeActivityId,
    this.expandedGroups = const {},
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
      expandedGroups:
          (json['expandedGroups'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          const {},
      sidebarWidth: json['sidebarWidth'] as double?,
    );
  }

  /// All currently open tabs
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

  /// Expansion state of sidebar groups and sub-groups
  ///
  /// Key format: "groupId" or "groupId.subGroupId" for nested items.
  final Map<String, bool> expandedGroups;

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
    Map<String, bool>? expandedGroups,
    double? sidebarWidth,
    String? error,
  }) {
    return WorkspaceState(
      openTabs: openTabs ?? this.openTabs,
      activeTabId: activeTabId ?? this.activeTabId,
      activeActivityId: activeActivityId ?? this.activeActivityId,
      expandedGroups: expandedGroups ?? this.expandedGroups,
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

  /// Checks if a sidebar group is expanded
  ///
  /// Supports nested groups with dot notation (e.g., "group.subgroup").
  bool isGroupExpanded(String groupId) {
    return expandedGroups[groupId] ?? false;
  }

  /// Converts the [WorkspaceState] instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'openTabs': openTabs.map((e) => e.toJson()).toList(),
      'activeTabId': activeTabId,
      'activeActivityId': activeActivityId,
      'expandedGroups': expandedGroups,
      'sidebarWidth': sidebarWidth,
    };
  }

  @override
  List<Object?> get props => [
    openTabs,
    activeTabId,
    activeActivityId,
    expandedGroups,
    sidebarWidth,
    error,
  ];
}
