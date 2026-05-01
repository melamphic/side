import 'package:flutter/material.dart';

import 'package:side/src/models/menu_items_model.dart';

/// Function signature for building page widgets
///
/// [context] - The build context
/// [args] - Optional arguments passed when opening the page
typedef PageBuilder =
    Widget Function(BuildContext context, Map<String, dynamic>? args);

/// Configuration for the VS Code-like workspace shell
///
/// This class defines the overall structure and behavior of the workspace,
/// including the activity bar, sidebar views, and editor configuration.
class WorkspaceConfig {
  /// Creates a [WorkspaceConfig]
  const WorkspaceConfig({
    required this.activityBarItems,
    required this.sidebarViews,
    required this.pageRegistry,
    this.maxTabs = 10,
    this.activityBarWidth = 60.0,
    this.sidebarWidth = 256.0,
    this.collapsibleSidebar = false,
  });

  /// Items displayed in the leftmost activity bar (like VS Code)
  ///
  /// Each item represents a different workspace context (Explorer, Search, etc.)
  /// When clicked, it switches the sidebar content to the corresponding view.
  final List<ActivityBarItem> activityBarItems;

  /// Sidebar content for each activity bar item
  ///
  /// Key should match the [ActivityBarItem.id] to display the correct
  /// sidebar content when that activity is selected.
  final Map<String, SidebarView> sidebarViews;

  /// Registry of all available pages that can be opened in tabs
  ///
  /// Key is the pageId used in navigation, value is the builder function
  /// that creates the widget for that page.
  final Map<String, PageBuilder> pageRegistry;

  /// Maximum number of tabs that can be open simultaneously
  ///
  /// When this limit is reached, users must close existing tabs before
  /// opening new ones. Helps prevent memory issues in large applications.
  final int maxTabs;

  /// Width of the leftmost activity bar in pixels
  ///
  /// Typically narrow since it only shows icons. Default matches VS Code.
  final double activityBarWidth;

  /// Width of the sidebar panel in pixels
  ///
  /// Contains the hierarchical navigation for the active activity.
  final double sidebarWidth;

  /// When true, the sidebar collapses to zero width whenever the cursor
  /// leaves the activity bar + sidebar region, and animates back open on
  /// hover. Activity bar stays visible at all times. Default false to
  /// preserve the persistent-sidebar behavior existing consumers expect.
  final bool collapsibleSidebar;
}

/// Represents an item in the VS Code-like activity bar
///
/// Activity bar items are the main navigation elements that switch
/// the entire sidebar context. Examples: Explorer, Search, Source Control.
class ActivityBarItem {
  /// Creates an [ActivityBarItem]
  const ActivityBarItem({
    required this.id,
    required this.icon,
    required this.label,
    this.tooltip,
    this.itemContentBuilder,
  });

  /// Unique identifier for this activity
  ///
  /// Used to associate with [SidebarView] and track active state.
  final String id;

  /// Icon displayed in the activity bar
  ///
  /// Should be recognizable and consistent with the activity's purpose.
  /// Used if [itemContentBuilder] is null.
  final IconData icon;

  /// Label for accessibility and tooltips
  ///
  /// Displayed when hovering over the activity bar item.
  final String label;

  /// Optional detailed tooltip text
  ///
  /// If not provided, [label] will be used as the tooltip.
  final String? tooltip;

  /// Optional builder for custom activity bar item content
  ///
  /// If provided, used instead of the default icon.
  /// The builder is passed the active state boolean.
  final Widget Function(BuildContext context, {required bool isActive})?
  itemContentBuilder;
}
