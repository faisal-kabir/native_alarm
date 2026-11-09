import 'package:eala/core/router/app_router.dart';
import 'package:eala/core/router/route_names.dart';
import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/features/alarm_audio/domain/entities/alarm_audio.dart';
import 'package:eala/features/create_alarm/domain/entities/alarm_draft.dart';
import 'package:eala/features/create_alarm/domain/entities/alarm_schedule.dart';
import 'package:eala/features/create_alarm/domain/usecases/create_alarm_usecase.dart';
import 'package:eala/features/create_alarm/presentation/bloc/create_alarm_state.dart';
import 'package:eala/features/create_alarm/presentation/pages/create_alarm_page.dart';
import 'package:eala/features/my_alarms/presentation/pages/my_alarms_page.dart';
import 'package:eala/features/my_alarms/presentation/widgets/alarm_card.dart';
import 'package:eala/features/my_alarms/presentation/widgets/slot_meter.dart';
import 'package:eala/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

const words = RepeatWords(
  once: 'Once',
  everyDay: 'Every day',
  weekdays: 'Weekdays',
  weekends: 'Weekends',
  everySingle: _everySingle,
  everyExcept: _everyExcept,
  dayShort: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
);
String _everySingle(String day) => 'Every $day';
String _everyExcept(String days) => 'Every day except $days';

const sixThirty = AlarmTime(6, 30);
const eight = AlarmTime(8, 0);

Alarm savedAlarm(String id, {int? reasonId}) => Alarm(
  id: id,
  enabled: true,
  time: DateTime(2026, 11, 9, 6, 30),
  audioTrackId: 'morning_message',
  ringtoneId: 'default',
  reasonId: reasonId,
);

void main() {
  group('schedule', () {
    test('another time takes the free days, or splits the weekend off', () {
      final week = [
        const ScheduleCard(id: 'a', time: sixThirty, days: [1, 2, 3, 4, 5]),
      ];
      final two = addCard(week, 'b');
      expect(two.last.days, [0, 6]);
      expect(two.last.time, sixThirty);

      final everyDay = [
        const ScheduleCard(
          id: 'a',
          time: sixThirty,
          days: [0, 1, 2, 3, 4, 5, 6],
        ),
      ];
      final split = addCard(everyDay, 'b');
      expect(split.first.days, [1, 2, 3, 4, 5]);
      expect(split.last.days, [0, 6]);
    });

    test('a day moves to the card it is tapped in; an empty card goes', () {
      final cards = [
        const ScheduleCard(id: 'a', time: sixThirty, days: [1, 2]),
        const ScheduleCard(id: 'b', time: eight, days: [0]),
      ];
      final moved = toggleCardDay(cards, 'b', 1);
      expect(moved.first.days, [2]);
      expect(moved.last.days, [0, 1]);

      final gone = toggleCardDay(cards, 'a', 0);
      expect(gone, hasLength(1));
      expect(gone.single.days, [0, 1, 2]);
    });

    test('days that all share one time save as a simple alarm', () {
      final draft = fromCards(AlarmDraft(), [
        const ScheduleCard(id: 'a', time: sixThirty, days: [1, 2]),
        const ScheduleCard(id: 'b', time: sixThirty, days: [6]),
      ]);
      expect(draft.byDay, isNotNull);
      final simple = finalize(draft);
      expect(simple.byDay, isNull);
      expect(simple.days, [1, 2, 6]);
      expect(simple.time, sixThirty);

      final mixed = finalize(
        fromCards(AlarmDraft(), [
          const ScheduleCard(id: 'a', time: sixThirty, days: [1]),
          const ScheduleCard(id: 'b', time: eight, days: [6]),
        ]),
      );
      expect(mixed.byDay, {1: sixThirty, 6: eight});
    });

    test('days are named in as few words as possible', () {
      expect(repeatLabel([], words), 'Once');
      expect(repeatLabel([1, 2, 3, 4, 5], words), 'Weekdays');
      expect(repeatLabel([0, 6], words), 'Weekends');
      expect(repeatLabel([3], words), 'Every Wed');
      expect(repeatLabel([1, 2, 3, 4, 5, 6], words), 'Mon–Sat');
      expect(repeatLabel([1, 3], words), 'Mon Wed');
      expect(repeatLabel([0, 1, 2, 3, 4, 5, 6], words), 'Every day');
    });

    test('the next ring is the soonest day at its time', () {
      // Sunday 8 November 2026, 7:00.
      final now = DateTime(2026, 11, 8, 7);
      expect(
        nextRing(AlarmDraft(time: const AlarmTime(9, 0)), now),
        DateTime(2026, 11, 8, 9),
      );
      expect(
        nextRing(AlarmDraft(time: sixThirty), now),
        DateTime(2026, 11, 9, 6, 30),
      );
      // Sunday has passed for today: next Sunday, unless Monday comes first.
      expect(
        nextRing(AlarmDraft(time: sixThirty, days: const [0]), now),
        DateTime(2026, 11, 15, 6, 30),
      );
      expect(
        nextRing(
          AlarmDraft(
            time: sixThirty,
            days: const [0, 2],
            byDay: const {0: sixThirty, 2: AlarmTime(5, 15, pm: true)},
          ),
          now,
        ),
        DateTime(2026, 11, 10, 17, 15),
      );
    });
  });

  group('CreateAlarmUseCase', () {
    final now = DateTime(2026, 11, 8, 7);

    test('saves the alarm and sets it to ring next', () async {
      final alarms = FakeAlarmRepository();
      final remote = FakeRemoteAlarmRepository();
      final scheduler = FakeAlarmScheduler();
      final result = await CreateAlarmUseCase(alarms, remote, scheduler)(
        CreateAlarmParams(
          draft: AlarmDraft(
            time: sixThirty,
            days: const [1, 0],
            byDay: const {1: sixThirty, 0: eight},
            reasonId: 7,
            soundTrackId: 2,
            alarmSoundId: 3,
            again: 2,
          ),
          title: 'Mornings',
          now: now,
        ),
      );

      final alarm = result.getOrElse(() => throw 'not saved');
      expect(alarms.store.values.single, alarm);
      expect(alarm.repeatWeekdays, [1, 7]);
      expect(alarm.dayTimes, {1: 390, 7: 480});
      expect(alarm.reasonId, 7);
      expect(alarm.soundTrackId, 2);
      expect(alarm.alarmSoundId, 3);
      expect(alarm.ringAgain, 2);
      expect(alarm.label, 'Mornings');
      expect(alarm.time, DateTime(2026, 11, 8, 8)); // Sunday 8:00, later today
      expect(scheduler.scheduled.single, (alarm, 'Mornings'));
      // It went to the server first and is kept with the server's id.
      expect(remote.uploaded.single.remoteId, isNull);
      expect(alarm.remoteId, 1);
    });

    test('offline it is kept on the device, to be sent later', () async {
      final alarms = FakeAlarmRepository();
      final scheduler = FakeAlarmScheduler();
      final result =
          await CreateAlarmUseCase(
            alarms,
            FakeRemoteAlarmRepository()..fail = true,
            scheduler,
          )(
            CreateAlarmParams(
              draft: AlarmDraft(reasonId: 7),
              title: 'x',
              now: now,
            ),
          );
      final alarm = result.getOrElse(() => throw 'not saved');
      expect(alarm.remoteId, isNull);
      expect(alarms.store.values.single, alarm);
      expect(scheduler.scheduled, hasLength(1));
    });

    test('never more than three alarms', () async {
      final alarms = FakeAlarmRepository();
      for (final id in ['a', 'b', 'c']) {
        alarms.store[id] = savedAlarm(id);
      }
      final scheduler = FakeAlarmScheduler();
      final remote = FakeRemoteAlarmRepository();
      final result = await CreateAlarmUseCase(alarms, remote, scheduler)(
        CreateAlarmParams(draft: AlarmDraft(), title: 'x', now: now),
      );
      expect(result.fold((f) => f, (_) => null), isA<AlarmLimitFailure>());
      expect(remote.uploaded, isEmpty);
      expect(alarms.store, hasLength(3));
      expect(scheduler.scheduled, isEmpty);
    });

    test('an alarm the system refuses is not kept', () async {
      final alarms = FakeAlarmRepository();
      final scheduler = FakeAlarmScheduler()..fail = true;
      final remote = FakeRemoteAlarmRepository();
      final result = await CreateAlarmUseCase(alarms, remote, scheduler)(
        CreateAlarmParams(draft: AlarmDraft(), title: 'x', now: now),
      );
      expect(result.isLeft(), isTrue);
      expect(alarms.store, isEmpty);
      // ...nor on the server.
      expect(remote.removed, [1]);
    });

    test('a switched-off alarm is saved but not set to ring', () async {
      final alarms = FakeAlarmRepository();
      final scheduler = FakeAlarmScheduler();
      await CreateAlarmUseCase(alarms, FakeRemoteAlarmRepository(), scheduler)(
        CreateAlarmParams(
          draft: AlarmDraft(enabled: false),
          title: 'x',
          now: now,
        ),
      );
      expect(alarms.store, hasLength(1));
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('pickable reasons', () {
    test(
      'a Reason with an alarm_id, or one a device alarm plays, is taken',
      () {
        final state = CreateAlarmState(
          draft: AlarmDraft(),
          reasons: [
            testReason(id: 1, name: 'Free'),
            testReason(id: 2, name: 'On the server', alarmId: 12),
            testReason(id: 3, name: 'Made offline'),
          ],
          takenReasonIds: const {3},
        );
        expect(state.pickableReasons.map((r) => r.id), [1]);
      },
    );

    test('the chosen Reason stays first even when it has its alarm', () {
      final state = CreateAlarmState(
        draft: AlarmDraft(reasonId: 2),
        reasons: [testReason(id: 1), testReason(id: 2, alarmId: 12)],
      );
      expect(state.pickableReasons.map((r) => r.id), [2, 1]);
    });
  });

  group('Create Alarm page', () {
    setUp(() => appRouter.go(RouteNames.dashboardPath));

    Future<(FakeAlarmRepository, FakeAlarmScheduler)> open(
      WidgetTester tester, {
      List<Alarm> existing = const [],
    }) async {
      final alarms = FakeAlarmRepository();
      for (final a in existing) {
        alarms.store[a.id] = a;
      }
      final scheduler = FakeAlarmScheduler();
      await registerFakeAlarmDependencies(
        alarms,
        reasonRepository: FakeReasonRepository([
          testReason(id: 1, name: 'Mornings'),
          testReason(id: 2, name: 'Training'),
        ]),
        alarmAudioRepository: FakeAlarmAudioRepository({
          AlarmAudioKind.soundTrack: const [
            AlarmAudio(kind: AlarmAudioKind.soundTrack, id: 1, title: 'None'),
            AlarmAudio(
              kind: AlarmAudioKind.soundTrack,
              id: 2,
              title: 'Rain',
              audio: 'audio/rain.mp3',
            ),
          ],
          AlarmAudioKind.alarmSound: const [
            AlarmAudio(
              kind: AlarmAudioKind.alarmSound,
              id: 5,
              title: 'Chime',
              audio: 'audio/chime.mp3',
              audioFile: '/files/chime.mp3',
            ),
          ],
        }),
        alarmScheduler: scheduler,
      );
      // Reduce motion: the empty Reason tile breathes forever otherwise.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      return (alarms, scheduler);
    }

    testWidgets('from My Alarms: choose a reason, save, the meter fills', (
      tester,
    ) async {
      final (alarms, scheduler) = await open(tester);
      await tester.tap(find.text('Set your first alarm'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateAlarmPage), findsOneWidget);
      expect(find.text('Add Alarm'), findsOneWidget);
      // The cached sounds, each starting on its first row.
      expect(find.text('None'), findsOneWidget);
      expect(find.text('Chime'), findsOneWidget);
      // No Reason yet: the button chooses one.
      await tester.tap(find.text('Choose a reason').last);
      await tester.pumpAndSettle();
      expect(find.text('What should wake you up?'), findsOneWidget);
      await tester.tap(find.text('Training'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select Reason'));
      await tester.pumpAndSettle();

      expect(find.text('Training'), findsOneWidget);
      await tester.tap(find.text('Save Alarm'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateAlarmPage), findsNothing);
      final alarm = alarms.store.values.single;
      expect(alarm.reasonId, 2);
      expect(alarm.soundTrackId, 1);
      expect(alarm.alarmSoundId, 5);
      expect(scheduler.scheduled.single.$2, 'Training');
      final meter = tester.widget<SlotMeter>(find.byType(SlotMeter));
      expect(meter.used, 1);
      // The new alarm is listed, and the empty card became the quiet row.
      expect(find.byType(AlarmCard), findsOneWidget);
      expect(find.text('Training'), findsOneWidget);
      expect(find.textContaining('Next ring · '), findsOneWidget);
      expect(find.text('Next alarm'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('Set your first alarm'), findsNothing);
      expect(find.text('Add alarm'), findsOneWidget);
    });

    testWidgets('My Alarms lists every alarm with its reason and days', (
      tester,
    ) async {
      await open(
        tester,
        existing: [
          savedAlarm('b', reasonId: 2).copyWith(
            time: DateTime(2026, 11, 9, 8),
            repeatWeekdays: const [1, 2, 3, 4, 5],
          ),
          savedAlarm('a', reasonId: 1).copyWith(enabled: false),
        ],
      );
      final cards = tester.widgetList<AlarmCard>(find.byType(AlarmCard));
      // Switched on first (it rings next), switched off after.
      expect([for (final c in cards) c.alarm.id], ['b', 'a']);
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('Mornings'), findsOneWidget);
      expect(find.textContaining('Next ring · '), findsOneWidget);
      expect(find.text('Off · won’t ring'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);
    });

    testWidgets('the switch stops an alarm, and sets it again', (tester) async {
      final (alarms, scheduler) = await open(
        tester,
        existing: [
          savedAlarm('a', reasonId: 1).copyWith(repeatWeekdays: const [1]),
        ],
      );
      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pumpAndSettle();
      expect(alarms.store['a']!.enabled, isFalse);
      expect(find.text('Off · won’t ring'), findsOneWidget);

      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pumpAndSettle();
      expect(alarms.store['a']!.enabled, isTrue);
      // Set again at its next Monday 6:30, wherever "now" is.
      final next = alarms.store['a']!.time;
      expect(next.weekday, DateTime.monday);
      expect(next.isAfter(DateTime.now()), isTrue);
      expect(find.textContaining('Next ring · '), findsOneWidget);
    });

    testWidgets('no alarm: the big "Set your first alarm" card', (
      tester,
    ) async {
      await open(tester);
      expect(find.byType(AlarmCard), findsNothing);
      expect(find.text('Set your first alarm'), findsOneWidget);
      expect(find.text('Pick a time and a reason.'), findsOneWidget);
    });

    testWidgets('a reason another alarm plays is not offered', (tester) async {
      await open(tester, existing: [savedAlarm('a', reasonId: 1)]);
      await tester.tap(find.text('Add alarm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose a reason').last);
      await tester.pumpAndSettle();
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('Mornings'), findsNothing);
    });

    testWidgets('three alarms: the limit, no page', (tester) async {
      await open(
        tester,
        existing: [savedAlarm('a'), savedAlarm('b'), savedAlarm('c')],
      );
      expect(tester.widget<SlotMeter>(find.byType(SlotMeter)).used, 3);
      await tester.scrollUntilVisible(
        find.text('Add alarm'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(MyAlarmsPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Add alarm'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateAlarmPage), findsNothing);
      expect(find.text('Alarm limit'), findsOneWidget);
      expect(find.text('You can have up to 3 alarms.'), findsOneWidget);
    });

    testWidgets('another time makes cards; ring again says what it does', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Set your first alarm'));
      await tester.pumpAndSettle();
      expect(find.text('Rings once · tap days to repeat'), findsOneWidget);

      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add another time'));
      await tester.pumpAndSettle();
      // Two cards now, each saying its days.
      expect(find.text('Every Mon'), findsOneWidget);
      expect(find.text('Tue–Sun'), findsOneWidget);

      await tester.ensureVisible(find.text('Twice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Twice'));
      await tester.pumpAndSettle();
      expect(find.textContaining('5 minutes apart'), findsOneWidget);
    });
  });
}
