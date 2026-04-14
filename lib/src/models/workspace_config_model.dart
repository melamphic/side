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
    this.activityBarWidth = 48.0,
    this.sidebarWidth = 250.0,
    this.maxVerticalSplits = 2,
    this.emptyPaneBuilder,
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

  /// Maximum number of vertical splits allowed in the editor
  ///
  /// Limits how many times the editor can be split vertically.
  /// 1 = no splits, 2 = one split (two panes), 3 = two splits (three panes).
  final int maxVerticalSplits;

  /// Optional builder for custom empty pane content
  ///
  /// If provided, this widget is shown when a pane has no open tabs.
  /// If null, a default placeholder is displayed.
  final Widget Function(BuildContext context, int paneIndex)? emptyPaneBuilder;
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

/// Configuration for split view behavior
///
/// Defines how the editor area can be split vertically to show
/// multiple content areas simultaneously.
enum SplitOrientation {
  /// Split the editor vertically (side by side)
  vertical,

  /// Future: Split horizontally (top and bottom)
  /// Currently not implemented but reserved for future use.
  horizontal,
}

/// Represents the split state of the editor area
///
/// Tracks which tabs are displayed in which split pane and
/// how the editor area is divided.
class SplitConfiguration {
  /// Creates a [SplitConfiguration]
  const SplitConfiguration({
    this.splitCount = 1,
    this.orientation = SplitOrientation.vertical,
    this.splitRatios = const [1.0],
    this.activePane = 0,
  });

  /// Creates a [SplitConfiguration] instance from a JSON map
  factory SplitConfiguration.fromJson(Map<String, dynamic> json) {
    return SplitConfiguration(
      splitCount: json['splitCount'] as int? ?? 1,
      orientation: SplitOrientation.values.firstWhere(
        (e) => e.toString() == (json['orientation'] as String),
        orElse: () => SplitOrientation.vertical,
      ),
      splitRatios:
          (json['splitRatios'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [1.0],
      activePane: json['activePane'] as int? ?? 0,
    );
  }

  /// Number of split panes currently active
  ///
  /// 1 = no split, 2 = one split (two panes), etc.
  final int splitCount;

  /// How the editor is split
  ///
  /// Currently only vertical splitting is supported.
  final SplitOrientation orientation;

  /// Size ratios for each split pane
  ///
  /// Values should sum to 1.0. Each value represents the
  /// proportional width of that pane.
  final List<double> splitRatios;

  /// Index of the currently focused pane
  ///
  /// Used for tab operations and keyboard navigation.
  final int activePane;

  /// Converts the [SplitConfiguration] instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'splitCount': splitCount,
      'orientation': orientation.toString(),
      'splitRatios': splitRatios,
      'activePane': activePane,
    };
  }

  /// Creates a copy with modified values
  SplitConfiguration copyWith({
    int? splitCount,
    SplitOrientation? orientation,
    List<double>? splitRatios,
    int? activePane,
  }) {
    return SplitConfiguration(
      splitCount: splitCount ?? this.splitCount,
      orientation: orientation ?? this.orientation,
      splitRatios: splitRatios ?? this.splitRatios,
      activePane: activePane ?? this.activePane,
    );
  }
}
