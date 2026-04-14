/// A VS Code-like workspace shell for Flutter CRM/ERP applications
///
/// This package provides a comprehensive workspace shell widget that mimics
/// Visual Studio Code's interface, featuring:
///
/// - **Activity Bar**: Leftmost navigation with main sections
/// - **Sidebar**: Hierarchical content that changes based on activity
/// - **Split Editor**: Multi-pane content area with tab management
/// - **Persistent State**: Maintains tabs and layout across activity switches
///
/// Perfect for building CRM, ERP, or other data-intensive applications that
/// require multiple simultaneous views and complex navigation structures.
///
/// ## Usage
///
/// ```dart
/// import 'package:side/side.dart';
///
/// WorkspaceShell(
///   config: WorkspaceConfig(
///     activityBarItems: [
///       ActivityBarItem(
///         id: 'explorer',
///         icon: Icons.folder_outlined,
///         label: 'Explorer',
///         sidebarView: SidebarView(
///           id: 'explorer',
///           title: 'Explorer',
///           groups: [
///             MenuGroup(
///               id: 'files',
///               label: 'Files',
///               items: [
///                 MenuItem(
///                   id: 'file1',
///                   label: 'Document.txt',
///                   pageId: 'editor_page',
///                   icon: Icons.description,
///                   pageArgs: {'fileName': 'Document.txt'},
///                 ),
///               ],
///             ),
///           ],
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
library;

export 'package:hydrated_bloc/hydrated_bloc.dart'
    show HydratedBloc, HydratedStorage, HydratedStorageDirectory;

// Core BLoC architecture
export 'src/bloc/workspace_bloc.dart';
// Data models
export 'src/models/models.dart';
// Individual widgets (for advanced customization)
export 'src/widgets/activity_bar.dart';
// Main shell widget
export 'src/widgets/salvia_shell.dart';
export 'src/widgets/sidebar.dart';
export 'src/widgets/split_editor.dart';
export 'src/widgets/tab_bar_widget.dart';
