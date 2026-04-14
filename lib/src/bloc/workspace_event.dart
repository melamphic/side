part of 'workspace_bloc.dart';

/// Base class for all workspace-related events
abstract class WorkspaceEvent extends Equatable {
  /// Abstract constructor for [WorkspaceEvent]
  const WorkspaceEvent();

  @override
  List<Object?> get props => [];
}

/// Event to open a new tab or focus an existing one
///
/// If a tab with the same [pageId] already exists, it will be focused
/// instead of creating a duplicate tab.
class OpenTab extends WorkspaceEvent {
  /// Creates an [OpenTab] event
  const OpenTab({
    required this.pageId,
    required this.title,
    this.icon,
    this.pageArgs,
    this.paneIndex,
  });

  /// Unique identifier for the page type
  ///
  /// Used to prevent duplicate tabs and look up the page builder.
  final String pageId;

  /// Display title for the tab
  ///
  /// Shown in the tab bar and used for user reference.
  final String title;

  /// Optional icon displayed in the tab
  final IconData? icon;

  /// Optional arguments passed to the page builder
  ///
  /// Useful for parameterized pages (e.g., user profile with user ID).
  final Map<String, dynamic>? pageArgs;

  /// Optional index of the split pane where this tab should be opened
  ///
  /// If null, opens in the currently active pane.
  /// 0 = first pane (left), 1 = second pane (right), etc.
  final int? paneIndex;

  @override
  List<Object?> get props => [pageId, title, icon, pageArgs, paneIndex];
}

/// Event to set the active pane index
///
/// Used when a user clicks on a pane to focus it.
class SetActivePane extends WorkspaceEvent {
  /// Creates a [SetActivePane] event
  const SetActivePane(this.paneIndex);

  /// Index of the pane to activate
  final int paneIndex;

  @override
  List<Object> get props => [paneIndex];
}

/// Event to close a specific tab
///
/// Removes the tab from the workspace and cleans up its state.
class CloseTab extends WorkspaceEvent {
  /// Creates a [CloseTab] event
  const CloseTab(this.tabId);

  /// Unique identifier of the tab to close
  ///
  /// Note: This is the tab's ID, not the pageId.
  final String tabId;

  @override
  List<Object> get props => [tabId];
}

/// Event to switch focus to a specific tab
///
/// Changes the active tab without opening or closing any tabs.
class SwitchTab extends WorkspaceEvent {
  /// Creates a [SwitchTab] event
  const SwitchTab({required this.tabId, this.paneIndex});

  /// Unique identifier of the tab to focus
  final String tabId;

  /// Optional pane index to focus along with the tab
  ///
  /// If not provided, focuses the pane containing the tab.
  final int? paneIndex;

  @override
  List<Object?> get props => [tabId, paneIndex];
}

/// Event to mark a tab as having unsaved changes
///
/// Updates the visual indicator (dot) showing dirty state.
class MarkTabDirty extends WorkspaceEvent {
  /// Creates a [MarkTabDirty] event
  const MarkTabDirty({required this.tabId, required this.isDirty});

  /// Unique identifier of the tab to mark
  final String tabId;

  /// Whether the tab has unsaved changes
  ///
  /// true = show dirty indicator, false = hide indicator
  final bool isDirty;

  @override
  List<Object> get props => [tabId, isDirty];
}

/// Event to switch the active activity bar item
///
/// Changes which sidebar view is displayed without affecting open tabs.
class SwitchActivity extends WorkspaceEvent {
  /// Creates a [SwitchActivity] event
  const SwitchActivity(this.activityId);

  /// Unique identifier of the activity to activate
  ///
  /// Must match an [ActivityBarItem.id] in the workspace config.
  final String activityId;

  @override
  List<Object> get props => [activityId];
}

/// Event to toggle the expansion state of a sidebar group
///
/// Expands collapsed groups or collapses expanded groups.
class ToggleSidebarGroup extends WorkspaceEvent {
  /// Creates a [ToggleSidebarGroup] event
  const ToggleSidebarGroup(this.groupId);

  /// Unique identifier of the group to toggle
  final String groupId;

  @override
  List<Object> get props => [groupId];
}

/// Event to split the editor vertically
///
/// Creates a new pane for displaying additional tabs side by side.
class SplitView extends WorkspaceEvent {
  /// Creates a [SplitView] event
  const SplitView({this.orientation = SplitOrientation.vertical});

  /// How to split the editor (currently only vertical supported)
  final SplitOrientation orientation;

  @override
  List<Object> get props => [orientation];
}

/// Event to close a split pane
///
/// Removes the pane and moves its tabs to the remaining pane.
class CloseSplit extends WorkspaceEvent {
  /// Creates a [CloseSplit] event
  const CloseSplit(this.paneIndex);

  /// Index of the pane to close (0-based)
  final int paneIndex;

  @override
  List<Object> get props => [paneIndex];
}

/// Event to resize split panes
///
/// Adjusts the width ratios of the split panes.
class ResizeSplit extends WorkspaceEvent {
  /// Creates a [ResizeSplit] event
  const ResizeSplit(this.splitRatios);

  /// New size ratios for each pane (should sum to 1.0)
  final List<double> splitRatios;

  @override
  List<Object> get props => [splitRatios];
}

/// Event to resize the sidebar
///
/// Updates the width of the sidebar.
class ResizeSidebar extends WorkspaceEvent {
  /// Creates a [ResizeSidebar] event
  const ResizeSidebar(this.width);

  /// New width of the sidebar
  final double width;

  @override
  List<Object> get props => [width];
}

/// Event to reorder a tab within the same pane
class ReorderTab extends WorkspaceEvent {
  /// Creates a [ReorderTab] event
  const ReorderTab({
    required this.paneIndex,
    required this.oldIndex,
    required this.newIndex,
  });

  /// Index of the pane containing the tab
  final int paneIndex;

  /// Original index of the tab
  final int oldIndex;

  /// New index for the tab
  final int newIndex;

  @override
  List<Object> get props => [paneIndex, oldIndex, newIndex];
}

/// Event to move a tab to a different pane
class MoveTabToPane extends WorkspaceEvent {
  /// Creates a [MoveTabToPane] event
  const MoveTabToPane({
    required this.tabId,
    required this.targetPaneIndex,
  });

  /// ID of the tab to move
  final String tabId;

  /// Index of the destination pane
  final int targetPaneIndex;

  @override
  List<Object> get props => [tabId, targetPaneIndex];
}

/// Event to close all other tabs in a pane except the specified one
class CloseOthers extends WorkspaceEvent {
  /// Creates a [CloseOthers] event
  const CloseOthers({
    required this.tabId,
    required this.paneIndex,
  });

  /// ID of the tab to keep open
  final String tabId;

  /// Index of the pane
  final int paneIndex;

  @override
  List<Object> get props => [tabId, paneIndex];
}

/// Event to close all tabs in a pane
class CloseAll extends WorkspaceEvent {
  /// Creates a [CloseAll] event
  const CloseAll(this.paneIndex);

  /// Index of the pane to clear
  final int paneIndex;

  @override
  List<Object> get props => [paneIndex];
}
