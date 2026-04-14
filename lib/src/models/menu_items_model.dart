import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:side/side.dart' show WorkspaceConfig;
import 'package:side/src/models/models.dart' show WorkspaceConfig;
import 'package:side/src/models/workspace_config_model.dart'
    show WorkspaceConfig;

/// Represents a clickable menu item that can open a page in the editor
///
/// This is the leaf node in the hierarchical menu structure.
/// When clicked, it opens the associated page in a new tab.
class MenuItem extends Equatable {
  /// Creates a [MenuItem]
  const MenuItem({
    required this.id,
    required this.label,
    required this.pageId,
    this.icon,
    this.tooltip,
    this.pageArgs,
    this.shortcut,
  });

  /// Unique identifier for this menu item
  ///
  /// Used for tracking selection state and building navigation paths.
  final String id;

  /// Display text shown in the sidebar
  ///
  /// Should be concise but descriptive of the page's purpose.
  final String label;

  /// Identifier of the page to open when this item is clicked
  ///
  /// Must correspond to a key in [WorkspaceConfig.pageRegistry].
  final String pageId;

  /// Optional icon displayed next to the label
  ///
  /// Helps users quickly identify different types of pages.
  final IconData? icon;

  /// Optional tooltip text shown on hover
  ///
  /// Can provide additional context about the page's functionality.
  final String? tooltip;

  /// Optional arguments passed to the page builder
  ///
  /// Useful for parameterized pages (e.g., user profile with user ID).
  final Map<String, dynamic>? pageArgs;

  /// Optional keyboard shortcut for quick access
  ///
  /// Displayed in the UI for user reference (not automatically handled).
  final String? shortcut;

  @override
  List<Object?> get props => [
    id,
    label,
    pageId,
    icon,
    tooltip,
    pageArgs,
    shortcut,
  ];
}

/// Represents a collapsible group containing menu items or sub-groups
///
/// This provides the second level of hierarchy in the sidebar navigation.
/// Groups can contain both menu items and nested sub-groups.
class MenuGroup extends Equatable {
  /// Creates a [MenuGroup]
  const MenuGroup({
    required this.id,
    required this.label,
    this.items = const [],
    this.subGroups = const [],
    this.icon,
    this.isExpanded = false,
    this.pageId,
    this.pageArgs,
  });

  /// Unique identifier for this group
  ///
  /// Used for tracking expansion state and navigation.
  final String id;

  /// Display text shown in the sidebar
  ///
  /// Appears as a collapsible section header.
  final String label;

  /// Direct menu items within this group
  ///
  /// These are the actual clickable items that open pages.
  final List<MenuItem> items;

  /// Nested sub-groups within this group
  ///
  /// Provides the third level of hierarchy (main → group → sub-group).
  final List<MenuSubGroup> subGroups;

  /// Optional icon displayed next to the group name
  ///
  /// Helps categorize different types of functionality.
  final IconData? icon;

  /// Whether this group is expanded by default
  ///
  /// User can still collapse/expand regardless of this setting.
  final bool isExpanded;

  /// Optional page ID to open when the group header is clicked
  ///
  /// If provided, clicking the label opens this page, while the arrow toggles expansion.
  final String? pageId;

  /// Optional arguments passed to the page builder
  final Map<String, dynamic>? pageArgs;

  @override
  List<Object?> get props => [
    id,
    label,
    items,
    subGroups,
    icon,
    isExpanded,
    pageId,
    pageArgs,
  ];
}

/// Represents a nested sub-group within a MenuGroup
///
/// This is the third and final level of hierarchy in the sidebar.
/// Sub-groups can only contain menu items, not further nesting.
class MenuSubGroup extends Equatable {
  /// Creates a [MenuSubGroup]
  const MenuSubGroup({
    required this.id,
    required this.label,
    required this.items,
    this.icon,
    this.isExpanded = false,
    this.pageId,
    this.pageArgs,
  });

  /// Unique identifier for this sub-group
  final String id;

  /// Display text shown in the sidebar
  final String label;

  /// Menu items within this sub-group
  ///
  /// These are the actual clickable items that open pages.
  final List<MenuItem> items;

  /// Optional icon displayed next to the sub-group name
  final IconData? icon;

  /// Whether this sub-group is expanded by default
  final bool isExpanded;

  /// Optional page ID to open when the sub-group header is clicked
  final String? pageId;

  /// Optional arguments passed to the page builder
  final Map<String, dynamic>? pageArgs;

  @override
  List<Object?> get props => [
    id,
    label,
    items,
    icon,
    isExpanded,
    pageId,
    pageArgs,
  ];
}

/// Represents the complete sidebar content for an activity bar item
///
/// Each activity (Explorer, Search, etc.) has its own sidebar view
/// with a hierarchical structure of groups and items.
class SidebarView extends Equatable {
  /// Creates a [SidebarView]
  const SidebarView({
    required this.id,
    required this.title,
    required this.groups,
    this.actions = const [],
    this.searchable = false,
    this.childBuilder,
  });

  /// Unique identifier matching the associated activity bar item
  final String id;

  /// Title displayed at the top of the sidebar
  ///
  /// Usually matches the activity bar item name but can be more descriptive.
  final String title;

  /// Top-level groups in this sidebar view
  ///
  /// Each group can contain items and sub-groups for hierarchical navigation.
  /// Used when [childBuilder] is null.
  final List<MenuGroup> groups;

  /// Optional builder for fully custom sidebar content
  ///
  /// If provided, this builder is used to render the sidebar content
  /// instead of the default group-based list.
  final WidgetBuilder? childBuilder;

  /// Optional action buttons shown in the sidebar header
  ///
  /// Common actions like "New File", "Refresh", "Settings", etc.
  final List<SidebarAction> actions;

  /// Whether this sidebar supports search functionality
  ///
  /// When true, displays a search box to filter the menu items.
  final bool searchable;

  @override
  List<Object?> get props => [
    id,
    title,
    groups,
    actions,
    searchable,
    childBuilder,
  ];
}

/// Represents an action button in the sidebar header
///
/// These are quick actions related to the current sidebar context.
class SidebarAction extends Equatable {
  /// Creates a [SidebarAction]
  const SidebarAction({
    required this.id,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  /// Unique identifier for this action
  final String id;

  /// Icon displayed in the button
  final IconData icon;

  /// Tooltip text shown on hover
  final String tooltip;

  /// Callback function executed when the action is tapped
  final VoidCallback onTap;

  @override
  List<Object?> get props => [id, icon, tooltip];
}
