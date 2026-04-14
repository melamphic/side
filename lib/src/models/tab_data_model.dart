import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Data model representing a single open tab
class TabData extends Equatable {
  /// Creates a [TabData] instance
  const TabData({
    required this.id,
    required this.pageId,
    required this.title,
    this.icon,
    this.isDirty = false,
    this.pageArgs,
  });

  /// Creates a [TabData] instance from a JSON map
  factory TabData.fromJson(Map<String, dynamic> json) {
    return TabData(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      title: json['title'] as String,
      icon: json['iconCodePoint'] != null
          ? IconData(
              json['iconCodePoint'] as int,
              fontFamily: json['iconFontFamily'] as String?,
              fontPackage: json['iconFontPackage'] as String?,
            )
          : null,
      isDirty: json['isDirty'] as bool? ?? false,
      pageArgs: json['pageArgs'] as Map<String, dynamic>?,
    );
  }

  /// Unique identifier for this specific tab instance
  final String id;

  /// Identifier of the page type (e.g., 'editor', 'settings')
  final String pageId;

  /// Display title for the tab
  final String title;

  /// Optional icon displayed in the tab
  final IconData? icon;

  /// Whether the tab has unsaved changes
  final bool isDirty;

  /// Optional arguments passed to the page builder
  final Map<String, dynamic>? pageArgs;

  /// Creates a copy with modified values
  TabData copyWith({
    String? id,
    String? pageId,
    String? title,
    IconData? icon,
    bool? isDirty,
    Map<String, dynamic>? pageArgs,
  }) {
    return TabData(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      isDirty: isDirty ?? this.isDirty,
      pageArgs: pageArgs ?? this.pageArgs,
    );
  }

  /// Converts the [TabData] instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageId': pageId,
      'title': title,
      if (icon != null) 'iconCodePoint': icon!.codePoint,
      if (icon != null) 'iconFontFamily': icon!.fontFamily,
      if (icon != null) 'iconFontPackage': icon!.fontPackage,
      'isDirty': isDirty,
      'pageArgs': pageArgs,
    };
  }

  @override
  List<Object?> get props => [id, pageId, title, icon, isDirty, pageArgs];
}

/// Data passed during drag and drop from sidebar to editor
class WorkspaceDragData extends Equatable {
  /// Creates a [WorkspaceDragData]
  const WorkspaceDragData({
    required this.pageId,
    required this.title,
    this.icon,
    this.pageArgs,
  });

  /// The ID of the page to open
  final String pageId;

  /// The title for the new tab
  final String title;

  /// The icon for the new tab
  final IconData? icon;

  /// Optional arguments for the page
  final Map<String, dynamic>? pageArgs;

  @override
  List<Object?> get props => [pageId, title, icon, pageArgs];
}
