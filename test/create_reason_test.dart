import 'dart:async';

import 'package:eala/core/router/app_router.dart';
import 'package:eala/core/router/route_names.dart';
import 'package:eala/core/widgets/animated_select_list.dart';
import 'package:eala/core/widgets/select_list_skeleton.dart';
import 'package:eala/features/area_of_life/domain/entities/area_of_life.dart';
import 'package:eala/features/area_of_life/domain/usecases/refresh_areas_of_life_usecase.dart';
import 'package:eala/features/area_of_life/domain/usecases/watch_areas_of_life_usecase.dart';
import 'package:eala/features/create_reason/presentation/bloc/create_reason_bloc.dart';
import 'package:eala/features/create_reason/presentation/bloc/create_reason_event.dart';
import 'package:eala/features/create_reason/presentation/bloc/create_reason_state.dart';
import 'package:eala/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

const health = AreaOfLife(
  id: 1,
  name: 'health',
  title: 'Health',
  description: 'Body and mind',
  color: 0xFF30D158,
);
const work = AreaOfLife(
  id: 2,
  name: 'work',
  title: 'Work',
  description: 'Get things done',
);

CreateReasonBloc buildBloc(FakeAreaOfLifeRepository repo) => CreateReasonBloc(
  WatchAreasOfLifeUseCase(repo),
  RefreshAreasOfLifeUseCase(repo),
);

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('CreateReasonBloc', () {
    test(
      'first time: loading until the server answers, then the areas',
      () async {
        final answer = Completer<void>();
        final repo = FakeAreaOfLifeRepository(
          server: [health, work],
          serverAnswer: answer.future,
        );
        final bloc = buildBloc(repo)..add(const LoadAreasEvent());
        await settle();
        expect(bloc.state.areas, isEmpty);
        expect(bloc.state.areasStatus, AreasStatus.loading);

        answer.complete();
        await settle();
        await settle();
        expect(bloc.state.areas, [health, work]);
        expect(bloc.state.areasStatus, AreasStatus.loaded);
        await bloc.close();
      },
    );

    test(
      'saved areas show at once; the update brings changes in later',
      () async {
        final answer = Completer<void>();
        final repo = FakeAreaOfLifeRepository(
          saved: [health],
          server: [health, work],
          serverAnswer: answer.future,
        );
        final bloc = buildBloc(repo)..add(const LoadAreasEvent());
        await settle();
        expect(bloc.state.areas, [health]);

        answer.complete();
        await settle();
        await settle();
        expect(bloc.state.areas, [health, work]);
        await bloc.close();
      },
    );

    test(
      'offline with nothing saved: failed, and Try again recovers',
      () async {
        final repo = FakeAreaOfLifeRepository(server: [health], offline: true);
        final bloc = buildBloc(repo)..add(const LoadAreasEvent());
        await settle();
        await settle();
        expect(bloc.state.areasStatus, AreasStatus.failed);

        repo.offline = false;
        bloc.add(const RefreshAreasEvent());
        await settle();
        await settle();
        expect(bloc.state.areas, [health]);
        expect(bloc.state.areasStatus, AreasStatus.loaded);
        await bloc.close();
      },
    );

    test('offline with saved areas: they stay and nothing breaks', () async {
      final repo = FakeAreaOfLifeRepository(saved: [health], offline: true);
      final bloc = buildBloc(repo)..add(const LoadAreasEvent());
      await settle();
      await settle();
      expect(bloc.state.areas, [health]);
      await bloc.close();
    });

    test(
      'choosing an area enables Continue; progress is 1 of the steps',
      () async {
        final bloc = buildBloc(
          FakeAreaOfLifeRepository(
            saved: [health, work],
            server: [health, work],
          ),
        )..add(const LoadAreasEvent());
        await settle();
        expect(bloc.state.canContinue, isFalse);
        expect(bloc.state.progress, closeTo(0.2, 1e-9));

        bloc.add(const AreaSelectedEvent(2));
        await settle();
        expect(bloc.state.selectedArea, work);
        expect(bloc.state.canContinue, isTrue);

        // No second step page exists yet, so Continue stays on the first.
        bloc.add(const NextStepEvent());
        await settle();
        expect(bloc.state.stepIndex, 0);
        await bloc.close();
      },
    );

    test('a chosen area the server removed is no longer chosen', () async {
      final answer = Completer<void>();
      final repo = FakeAreaOfLifeRepository(
        saved: [health, work],
        server: [health],
        serverAnswer: answer.future,
      );
      final bloc = buildBloc(repo)..add(const LoadAreasEvent());
      await settle();
      bloc.add(const AreaSelectedEvent(2));
      await settle();
      expect(bloc.state.selectedAreaId, 2);

      answer.complete();
      await settle();
      await settle();
      expect(bloc.state.areas, [health]);
      expect(bloc.state.selectedAreaId, isNull);
      await bloc.close();
    });

    test('an area that is not in the list can not be chosen', () async {
      final bloc = buildBloc(
        FakeAreaOfLifeRepository(saved: [health], server: [health]),
      )..add(const LoadAreasEvent());
      await settle();
      bloc.add(const AreaSelectedEvent(99));
      await settle();
      expect(bloc.state.selectedAreaId, isNull);
      await bloc.close();
    });

    test('Previous on the first step does nothing', () async {
      final bloc = buildBloc(FakeAreaOfLifeRepository())
        ..add(const PreviousStepEvent());
      await settle();
      expect(bloc.state.stepIndex, 0);
      await bloc.close();
    });
  });

  group('Create Reason page', () {
    // The router is one app-wide object: start every test from the Dashboard.
    setUp(() => appRouter.go(RouteNames.dashboardPath));

    Future<void> openPage(
      WidgetTester tester,
      FakeAreaOfLifeRepository repo,
    ) async {
      await registerFakeAlarmDependencies(
        FakeAlarmRepository(),
        areaOfLifeRepository: repo,
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reasons').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add your first Reason'));
      // The page slides in; the rows then rise in.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('opens from the Reasons tab: skeleton first, then the rows', (
      tester,
    ) async {
      final answer = Completer<void>();
      final repo = FakeAreaOfLifeRepository(
        server: [health, work],
        serverAnswer: answer.future,
      );
      await openPage(tester, repo);
      // The shimmer never stops, so settle by pumping a fixed time.
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('wake up for'), findsOneWidget);
      expect(find.byType(SelectListSkeleton), findsOneWidget);
      expect(find.text('Health'), findsNothing);

      answer.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(SelectListSkeleton), findsNothing);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Body and mind'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets(
      'choosing rows moves the one shared border; Continue wakes up',
      (tester) async {
        await openPage(
          tester,
          FakeAreaOfLifeRepository(
            saved: [health, work],
            server: [health, work],
          ),
        );
        await tester.pumpAndSettle();

        final list = tester.state<AnimatedSelectListState>(
          find.byType(AnimatedSelectList),
        );
        expect(list.indicatorRect, isNull);

        await tester.tap(find.text('Health'));
        await tester.pumpAndSettle();
        final first = list.indicatorRect!;
        expect(
          first.top,
          closeTo(
            tester.getTopLeft(find.byType(SelectRow).first).dy -
                tester.getTopLeft(find.byType(AnimatedSelectList)).dy,
            0.5,
          ),
        );

        await tester.tap(find.text('Work'));
        await tester.pumpAndSettle();
        final second = list.indicatorRect!;
        expect(second.top, greaterThan(first.top));
        expect(second.height, closeTo(first.height, 0.01));
        expect(second.width, closeTo(first.width, 0.01));
      },
    );

    testWidgets('back on the first step closes the page', (tester) async {
      await openPage(
        tester,
        FakeAreaOfLifeRepository(saved: [health], server: [health]),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('wake up for'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('My Reasons'), findsOneWidget);
    });

    testWidgets('offline with nothing saved shows the message and Try again', (
      tester,
    ) async {
      final repo = FakeAreaOfLifeRepository(server: [health], offline: true);
      await openPage(tester, repo);
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn’t load'), findsOneWidget);

      repo.offline = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Health'), findsOneWidget);
      expect(find.textContaining('Couldn’t load'), findsNothing);
    });
  });
}
