import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:side/side.dart';
import 'package:path_provider/path_provider.dart';

// Theme Constants
const kPrimaryColor = Color(0xFF2D3748); // Slate
const kAccentColor = Color(0xFFEDF2F7); // Light Grey-Blue
const kSurfaceColor = Color(0xFFF7FAFC); // Off White

// Typography
const kFontHeader = TextStyle(
  fontWeight: FontWeight.bold,
  color: kPrimaryColor,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path,
          ),
  );
  runApp(const OffIdeExampleApp());
}

class OffIdeExampleApp extends StatelessWidget {
  const OffIdeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Side Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          surface: kSurfaceColor,
          primary: kPrimaryColor,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
        ),
      ),
      home: WorkspaceShell(
        config: WorkspaceConfig(
          maxTabs: 10,
          activityBarItems: [
            const ActivityBarItem(
              id: 'explorer',
              icon: Icons.folder_outlined,
              label: 'Explorer',
              tooltip: 'Project Explorer',
            ),
            const ActivityBarItem(
              id: 'team',
              icon: Icons.people_outline,
              label: 'Team',
              tooltip: 'Team Members',
            ),
            const ActivityBarItem(
              id: 'analytics',
              icon: Icons.analytics_outlined,
              label: 'Analytics',
              tooltip: 'Reports & Metrics',
            ),
            const ActivityBarItem(
              id: 'settings',
              icon: Icons.settings_outlined,
              label: 'Settings',
              tooltip: 'Configuration',
            ),
          ],
          sidebarViews: {
            'explorer': const SidebarView(
              id: 'explorer',
              title: 'EXPLORER',
              groups: [
                MenuGroup(
                  id: 'acme_corp',
                  label: 'Acme_Corp',
                  isExpanded: true,
                  subGroups: [
                    MenuSubGroup(
                      id: 'marketing',
                      label: 'Marketing',
                      isExpanded: true,
                      items: [
                        MenuItem(
                          id: 'team_directory',
                          label: 'Team_Directory.list',
                          pageId: 'team-directory',
                          icon: Icons.people,
                        ),
                        MenuItem(
                          id: 'project_overview',
                          label: 'Project_Overview.dash',
                          pageId: 'project-overview',
                          icon: Icons.dashboard,
                        ),
                        MenuItem(
                          id: 'office_layout',
                          label: 'Office_Layout.map',
                          pageId: 'office-layout',
                          icon: Icons.map,
                        ),
                      ],
                    ),
                    MenuSubGroup(
                      id: 'engineering',
                      label: 'Engineering',
                      isExpanded: false,
                      pageId: 'engineering-dash',
                      items: [
                        MenuItem(
                          id: 'sprint_board',
                          label: 'Sprint_Board.task',
                          pageId: 'sprint-board',
                          icon: Icons.view_kanban,
                        ),
                        MenuItem(
                          id: 'resources',
                          label: 'Resources.cfg',
                          pageId: 'resources',
                          icon: Icons.storage,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            'team': const SidebarView(
              title: 'TEAM',
              id: 'team',
              groups: [],
              childBuilder: _buildTeamSidebar,
            ),
            'analytics': const SidebarView(
              title: 'ANALYTICS',
              id: 'analytics',
              groups: [],
              childBuilder: _buildTeamSidebar,
            ),
            'settings': const SidebarView(
              title: 'SETTINGS',
              id: 'settings',
              groups: [],
            ),
          },
          pageRegistry: {
            'team-directory': (context, args) => const TeamDirectoryPage(),
            'member-profile': (context, args) =>
                MemberProfilePage(args: args ?? {}),
            'project-overview': (context, args) => const ProjectOverviewPage(),
            'office-layout': (context, args) => const OfficeLayoutPage(),
            'sprint-board': (context, args) => const SprintBoardPage(),
            'engineering-dash': (context, args) => Container(
              color: Colors.orange.shade50,
              child: const Center(
                child: Text(
                  'Engineering Dashboard\n(Actionable Group Demo)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            'resources': (context, args) => Container(
              color: Colors.blue.shade50,
              child: const Center(child: Text('Resources Configuration')),
            ),
          },
        ),
      ),
    );
  }

  static Widget _buildTeamSidebar(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: _teamMembers.map((person) {
        return ListTile(
          leading: CircleAvatar(child: Text(person['initials']!)),
          title: Text(person['name']!),
          subtitle: Text(person['role']!),
          onTap: () {
            context.read<WorkspaceBloc>().add(
              OpenTab(
                pageId: 'member-profile',
                title: person['name']!,
                icon: Icons.person,
                pageArgs: {
                  'name': person['name'],
                  'initials': person['initials'],
                  'role': person['role'],
                  'department': person['department'],
                  'status': person['status'],
                },
              ),
            );
          },
        );
      }).toList(),
    );
  }

  static const List<Map<String, String>> _teamMembers = [
    {
      'name': 'Emily Richardson',
      'initials': 'ER',
      'role': 'Product Manager',
      'department': 'Marketing',
      'status': 'Active',
    },
    {
      'name': 'Marcus Vane',
      'initials': 'MV',
      'role': 'Frontend Developer',
      'department': 'Engineering',
      'status': 'Active',
    },
    {
      'name': 'Sarah Jenkins',
      'initials': 'SJ',
      'role': 'UX Designer',
      'department': 'Design',
      'status': 'Away',
    },
    {
      'name': 'Alan Grant',
      'initials': 'AG',
      'role': 'Team Lead',
      'department': 'Engineering',
      'status': 'Active',
    },
  ];
}

// -----------------------------------------------------------------------------
// 1. Team Directory Page (Rich List)
// -----------------------------------------------------------------------------
class TeamDirectoryPage extends StatelessWidget {
  const TeamDirectoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Directory',
                    style: kFontHeader.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Showing all active members across departments',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: const BorderSide(color: kPrimaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Export CSV'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Member'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Rich Table
          Expanded(
            child: Card(
              child: ListView.separated(
                padding: const EdgeInsets.all(0),
                itemCount: _memberList.length + 1, // +1 for header
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) return _buildTableHeader();
                  return _buildMemberRow(context, _memberList[index - 1]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('NAME', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('ROLE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'DEPARTMENT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'STATUS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(BuildContext context, Map<String, dynamic> member) {
    return InkWell(
      onTap: () {
        context.read<WorkspaceBloc>().add(
          OpenTab(
            pageId: 'member-profile',
            title: member['name'] as String,
            icon: Icons.person,
            pageArgs: {
              'name': member['name'],
              'initials': member['initials'],
              'role': member['role'],
              'department': member['department'],
              'status': member['status'],
            },
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Name with Avatar
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: member['avatarColor'] as Color,
                    foregroundColor: kPrimaryColor,
                    child: Text(member['initials'] as String),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    member['name'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Role
            Expanded(
              flex: 2,
              child: Text(
                member['role'] as String,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
            // Department
            Expanded(flex: 2, child: Text(member['department'] as String)),
            // Status Badge
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (member['active'] as bool)
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (member['status'] as String).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: (member['active'] as bool)
                        ? Colors.green[800]
                        : Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final List<Map<String, dynamic>> _memberList = [
    {
      'name': 'Emily Richardson',
      'initials': 'ER',
      'avatarColor': const Color(0xFFE0F2F1),
      'role': 'Product Manager',
      'department': 'Marketing',
      'status': 'Active',
      'active': true,
    },
    {
      'name': 'Marcus Vane',
      'initials': 'MV',
      'avatarColor': const Color(0xFFFFF3E0),
      'role': 'Frontend Developer',
      'department': 'Engineering',
      'status': 'Active',
      'active': true,
    },
    {
      'name': 'Sarah Jenkins',
      'initials': 'SJ',
      'avatarColor': const Color(0xFFE3F2FD),
      'role': 'UX Designer',
      'department': 'Design',
      'status': 'Away',
      'active': false,
    },
    {
      'name': 'Alan Grant',
      'initials': 'AG',
      'avatarColor': const Color(0xFFF3E5F5),
      'role': 'Team Lead',
      'department': 'Engineering',
      'status': 'Active',
      'active': true,
    },
  ];
}

// -----------------------------------------------------------------------------
// 2. Project Overview Page (Dashboard with KPIs)
// -----------------------------------------------------------------------------
class ProjectOverviewPage extends StatelessWidget {
  const ProjectOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project Overview', style: kFontHeader.copyWith(fontSize: 32)),
          const SizedBox(height: 24),

          // KPI Cards
          Row(
            children: [
              _buildKPICard(
                'Active Projects',
                '24',
                '+3 this month',
                Icons.work_outline,
                Colors.blue,
              ),
              const SizedBox(width: 24),
              _buildKPICard(
                'Completion Rate',
                '87%',
                '4 due this week',
                Icons.check_circle_outline,
                Colors.green,
              ),
              const SizedBox(width: 24),
              _buildKPICard(
                'Open Issues',
                '18',
                '5 critical',
                Icons.bug_report_outlined,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const DropdownMenu<String>(
                initialSelection: 'All Teams',
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: 'All Teams', label: 'All Teams'),
                  DropdownMenuEntry(value: 'Marketing', label: 'Marketing'),
                  DropdownMenuEntry(value: 'Engineering', label: 'Engineering'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return _buildProjectCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
    String label,
    String value,
    String subtext,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtext,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(int index) {
    final status = index % 3 == 0
        ? 'In Progress'
        : (index % 2 == 0 ? 'On Hold' : 'Review');
    final color = index % 3 == 0
        ? Colors.blue
        : (index % 2 == 0 ? Colors.orange : Colors.green);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Text('P$index'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project #${100 + index}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Sprint ${index + 1}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Office Layout Page (Canvas Diagram)
// -----------------------------------------------------------------------------
class OfficeLayoutPage extends StatelessWidget {
  const OfficeLayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Office Layout — Floor 3',
                style: kFontHeader.copyWith(fontSize: 32),
              ),
              Row(
                children: [
                  _buildLegendItem('Occupied', Colors.green),
                  const SizedBox(width: 16),
                  _buildLegendItem('Available', Colors.grey),
                  const SizedBox(width: 16),
                  _buildLegendItem('Reserved', Colors.blue),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              color: const Color(0xFFF9F9F9),
              child: Center(
                child: CustomPaint(
                  size: const Size(600, 400),
                  painter: _LayoutPainter(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _LayoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    // Hallway
    paint.color = Colors.grey[300]!;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2 - 40, size.width, 80),
      paint,
    );

    // Offices Top
    paint.color = Colors.green[100]!;
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(Rect.fromLTWH(i * 120 + 10.0, 10.0, 100, 120), paint);
      canvas.drawLine(
        Offset(i * 120 + 60.0, 130.0),
        Offset(i * 120 + 60.0, 150.0),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );
    }

    // Meeting Rooms Bottom
    paint.color = Colors.blue[100]!;
    for (int i = 0; i < 5; i++) {
      if (i == 2) paint.color = Colors.grey[200]!; // Available
      canvas.drawRect(
        Rect.fromLTWH(i * 120 + 10.0, size.height - 130, 100, 120),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// 4. Sprint Board Page (Kanban-style)
// -----------------------------------------------------------------------------
class SprintBoardPage extends StatelessWidget {
  const SprintBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sprint Board', style: kFontHeader.copyWith(fontSize: 32)),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'board', label: Text('Board')),
                  ButtonSegment(value: 'list', label: Text('List')),
                  ButtonSegment(value: 'timeline', label: Text('Timeline')),
                ],
                selected: const {'board'},
                onSelectionChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                _buildColumn('To Do', Colors.grey, [
                  'Setup CI pipeline',
                  'Write API docs',
                  'Design login page',
                ]),
                const SizedBox(width: 16),
                _buildColumn('In Progress', Colors.blue, [
                  'Build dashboard',
                  'Integrate payments',
                ]),
                const SizedBox(width: 16),
                _buildColumn('Review', Colors.orange, [
                  'Auth module',
                  'User settings',
                ]),
                const SizedBox(width: 16),
                _buildColumn('Done', Colors.green, [
                  'Project setup',
                  'DB schema',
                  'Landing page',
                  'Email templates',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(String title, Color color, List<String> items) {
    return Expanded(
      child: Card(
        child: Column(
          children: [
            // Column Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${items.length}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            // Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      border: Border(left: BorderSide(color: color, width: 3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      items[index],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. Member Profile Page (Opens per member)
// -----------------------------------------------------------------------------
class MemberProfilePage extends StatelessWidget {
  const MemberProfilePage({super.key, required this.args});

  final Map<String, dynamic> args;

  @override
  Widget build(BuildContext context) {
    final name = args['name'] as String? ?? 'Unknown';
    final initials = args['initials'] as String? ?? '??';
    final role = args['role'] as String? ?? 'N/A';
    final department = args['department'] as String? ?? 'N/A';
    final status = args['status'] as String? ?? 'N/A';
    final isActive = status == 'Active';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: kPrimaryColor.withValues(alpha: .1),
                child: Text(
                  initials,
                  style: kFontHeader.copyWith(fontSize: 24),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: kFontHeader.copyWith(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: .1)
                      : Colors.grey.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green[800] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Info Cards
          Row(
            children: [
              _infoCard('Department', department, Icons.business),
              const SizedBox(width: 16),
              _infoCard('Location', 'Floor 3, Desk 12', Icons.location_on),
              const SizedBox(width: 16),
              _infoCard('Joined', 'Jan 2023', Icons.calendar_today),
            ],
          ),
          const SizedBox(height: 32),

          // Activity log
          Text('Recent Activity', style: kFontHeader.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final actions = [
                    'Pushed 3 commits to main',
                    'Reviewed PR #142 — Dashboard layout',
                    'Updated project timeline',
                    'Completed onboarding checklist',
                    'Added comments on design spec',
                  ];
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.green[400],
                    ),
                    title: Text(actions[index]),
                    trailing: Text(
                      '${index + 1}h ago',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: kPrimaryColor, size: 28),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
