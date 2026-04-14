import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:side/side.dart';

class MockStorage extends Mock implements Storage {}

void main() {
  late Storage storage;

  setUp(() {
    storage = MockStorage();
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  group('WorkspaceBloc', () {
    late WorkspaceBloc bloc;

    setUp(() {
      bloc = WorkspaceBloc(maxTabs: 5);
    });

    test('initial state is correct', () {
      expect(bloc.state.openTabs, isEmpty);
      expect(bloc.state.activeTabId, isNull);
      expect(bloc.state.activePaneIndex, 0);
      expect(bloc.state.splitConfiguration.splitCount, 1);
      expect(bloc.state.error, isNull);
    });

    group('Tab Management', () {
      blocTest<WorkspaceBloc, WorkspaceState>(
        'OpenTab adds a new tab and focuses it',
        build: () => bloc,
        act: (bloc) => bloc.add(const OpenTab(pageId: 'p1', title: 'P1')),
        expect: () => [
          isA<WorkspaceState>()
              .having((s) => s.openTabs.length, 'length', 1)
              .having((s) => s.activeTabId, 'activeId', isNotNull)
              .having((s) => s.activePaneIndex, 'activePane', 0)
              .having((s) => s.error, 'error', isNull),
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'OpenTab respects maxTabs limit',
        build: () => bloc,
        seed: () => WorkspaceState(
          openTabs: const [
            TabData(id: '1', pageId: 'p1', title: 'T1'),
            TabData(id: '2', pageId: 'p2', title: 'T2'),
            TabData(id: '3', pageId: 'p3', title: 'T3'),
            TabData(id: '4', pageId: 'p4', title: 'T4'),
            TabData(id: '5', pageId: 'p5', title: 'T5'),
          ],
        ),
        act: (bloc) => bloc.add(const OpenTab(pageId: 'p6', title: 'T6')),
        expect: () => [
          isA<WorkspaceState>().having(
            (s) => s.error,
            'max tabs error',
            contains('Maximum 5 tabs open'),
          ),
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'OpenTab properly de-duplicates (focuses existing tab)',
        build: () => bloc,
        seed: () => WorkspaceState(
          openTabs: const [
            TabData(id: 'tab1', pageId: 'p1', title: 'T1'),
            TabData(id: 'tab2', pageId: 'secondary', title: 'T2'),
          ],
          tabsByPane: const {
            0: ['tab1', 'tab2'],
          },
          activeTabId: 'tab1',
          activeTabByPane: const {0: 'tab1'},
        ),
        act: (bloc) =>
            bloc.add(const OpenTab(pageId: 'secondary', title: 'Dupe')),
        expect: () => [
          isA<WorkspaceState>()
              .having((s) => s.activeTabId, 'focus existing globally', 'tab2')
              .having(
                (s) => s.activeTabByPane[0],
                'focus existing in pane',
                'tab2',
              ),
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'CloseTab removes tab and updates focus (next tab)',
        build: () => bloc,
        seed: () => WorkspaceState(
          openTabs: const [
            TabData(id: 't1', pageId: 'p1', title: 'T1'),
            TabData(id: 't2', pageId: 'p2', title: 'T2'),
          ],
          tabsByPane: const {
            0: ['t1', 't2'],
          },
          activeTabId: 't1',
        ),
        act: (bloc) => bloc.add(const CloseTab('t1')),
        expect: () => [
          isA<WorkspaceState>()
              .having((s) => s.openTabs.length, 'length', 1)
              .having(
                (s) => s.activeTabId,
                'focused',
                't2',
              ), // Focuses next available
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'SwitchTab changes active tab and pane',
        build: () => bloc,
        seed: () => WorkspaceState(
          openTabs: const [TabData(id: 't1', pageId: 'p1', title: 'T1')],
          tabsByPane: const {
            0: ['t1'],
          },
          activePaneIndex: 1, // Assume existing state was different
        ),
        act: (bloc) => bloc.add(const SwitchTab(tabId: 't1', paneIndex: 0)),
        expect: () => [
          isA<WorkspaceState>()
              .having((s) => s.activeTabId, 'activeTab', 't1')
              .having((s) => s.activePaneIndex, 'activePane', 0),
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'MarkTabDirty updates isDirty flag',
        build: () => bloc,
        seed: () => WorkspaceState(
          openTabs: const [TabData(id: 't1', pageId: 'p1', title: 'T1')],
        ),
        act: (bloc) => bloc.add(const MarkTabDirty(tabId: 't1', isDirty: true)),
        expect: () => [
          isA<WorkspaceState>().having(
            (s) => s.openTabs.first.isDirty,
            'isDirty',
            true,
          ),
        ],
      );
    });

    group('Activity & Sidebar', () {
      blocTest<WorkspaceBloc, WorkspaceState>(
        'SwitchActivity updates activeActivityId',
        build: () => bloc,
        act: (bloc) => bloc.add(const SwitchActivity('new_activity')),
        expect: () => [
          isA<WorkspaceState>().having(
            (s) => s.activeActivityId,
            'activity',
            'new_activity',
          ),
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'ToggleSidebarGroup toggles expansion state',
        build: () => bloc,
        act: (bloc) => bloc.add(const ToggleSidebarGroup('group1')),
        expect: () => [
          isA<WorkspaceState>().having(
            (s) => s.expandedGroups['group1'],
            'expanded',
            true,
          ),
        ],
      );
    });

    group('Split View', () {
      blocTest<WorkspaceBloc, WorkspaceState>(
        'SplitView adds a new split pane',
        build: () => bloc,
        act: (bloc) => bloc.add(const SplitView()),
        expect: () => [
          isA<WorkspaceState>().having(
            (s) => s.splitConfiguration.splitCount,
            'splitCount',
            2,
          ),
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'SplitView respects max splits limit',
        build: () => WorkspaceBloc(maxTabs: 10),
        seed: () => WorkspaceState(
          splitConfiguration: const SplitConfiguration(splitCount: 2),
        ),
        act: (bloc) => bloc.add(const SplitView()),
        expect: () => [
          isA<WorkspaceState>().having(
            (s) => s.error,
            'max split error',
            contains('Maximum 2 splits allowed'),
          ),
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'CloseSplit merges tabs and reduces split count',
        build: () => bloc,
        seed: () => WorkspaceState(
          splitConfiguration: const SplitConfiguration(splitCount: 2),
          tabsByPane: const {
            0: ['t1'],
            1: ['t2'],
          },
          openTabs: const [
            TabData(id: 't1', pageId: 'p1', title: 'T1'),
            TabData(id: 't2', pageId: 'p2', title: 'T2'),
          ],
          activePaneIndex: 1,
        ),
        act: (bloc) => bloc.add(const CloseSplit(1)),
        expect: () => [
          isA<WorkspaceState>()
              .having((s) => s.splitConfiguration.splitCount, 'splitCount', 1)
              .having(
                (s) => s.tabsByPane[0],
                'merged tabs',
                containsAll(['t1', 't2']),
              )
              .having((s) => s.activePaneIndex, 'reset active pane', 0),
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'ResizeSplit updates ratios',
        build: () => bloc,
        seed: () => WorkspaceState(
          splitConfiguration: const SplitConfiguration(splitCount: 2),
        ),
        act: (bloc) => bloc.add(const ResizeSplit([0.7, 0.3])),
        expect: () => [
          isA<WorkspaceState>().having(
            (s) => s.splitConfiguration.splitRatios,
            'ratios',
            [0.7, 0.3],
          ),
        ],
      );
    });
  });
}
