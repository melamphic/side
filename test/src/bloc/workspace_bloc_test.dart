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
          activeTabId: 'tab1',
        ),
        act: (bloc) =>
            bloc.add(const OpenTab(pageId: 'secondary', title: 'Dupe')),
        expect: () => [
          isA<WorkspaceState>().having(
            (s) => s.activeTabId,
            'focus existing',
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
          activeTabId: 't1',
        ),
        act: (bloc) => bloc.add(const CloseTab('t1')),
        expect: () => [
          isA<WorkspaceState>()
              .having((s) => s.openTabs.length, 'length', 1)
              .having((s) => s.activeTabId, 'focused', 't2'),
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'SwitchTab changes active tab',
        build: () => bloc,
        seed: () => WorkspaceState(
          openTabs: const [TabData(id: 't1', pageId: 'p1', title: 'T1')],
        ),
        act: (bloc) => bloc.add(const SwitchTab(tabId: 't1')),
        expect: () => [
          isA<WorkspaceState>().having((s) => s.activeTabId, 'activeTab', 't1'),
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

      blocTest<WorkspaceBloc, WorkspaceState>(
        'CloseOthers keeps only the specified tab',
        build: () => bloc,
        seed: () => WorkspaceState(
          openTabs: const [
            TabData(id: 't1', pageId: 'p1', title: 'T1'),
            TabData(id: 't2', pageId: 'p2', title: 'T2'),
            TabData(id: 't3', pageId: 'p3', title: 'T3'),
          ],
          activeTabId: 't2',
        ),
        act: (bloc) => bloc.add(const CloseOthers(tabId: 't2')),
        expect: () => [
          isA<WorkspaceState>()
              .having((s) => s.openTabs.length, 'length', 1)
              .having((s) => s.activeTabId, 'activeId', 't2'),
        ],
      );

      blocTest<WorkspaceBloc, WorkspaceState>(
        'CloseAll empties the tab list',
        build: () => bloc,
        seed: () => WorkspaceState(
          openTabs: const [
            TabData(id: 't1', pageId: 'p1', title: 'T1'),
            TabData(id: 't2', pageId: 'p2', title: 'T2'),
          ],
          activeTabId: 't1',
        ),
        act: (bloc) => bloc.add(const CloseAll()),
        expect: () => [
          isA<WorkspaceState>()
              .having((s) => s.openTabs, 'tabs', isEmpty)
              .having((s) => s.activeTabId, 'activeId', isNull),
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
  });
}
