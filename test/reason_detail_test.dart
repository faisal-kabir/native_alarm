import 'package:eala/core/di/injection.dart';
import 'package:eala/core/router/app_router.dart';
import 'package:eala/core/router/route_names.dart';
import 'package:eala/core/widgets/app_sheet.dart';
import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/features/area_of_life/domain/entities/area_of_life.dart';
import 'package:eala/features/area_of_life/domain/entities/purpose_suggestion.dart';
import 'package:eala/features/reason_detail/presentation/bloc/reason_detail_bloc.dart';
import 'package:eala/features/reason_detail/presentation/pages/reason_detail_page.dart';
import 'package:eala/features/reasons/domain/entities/reason.dart';
import 'package:eala/features/reasons/presentation/widgets/reason_row.dart';
import 'package:eala/features/sound/domain/entities/sound_type.dart';
import 'package:eala/features/voice/domain/entities/voice.dart';
import 'package:eala/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

const health = AreaOfLife(id: 1, name: 'health', title: 'Health');
const work = AreaOfLife(id: 2, name: 'work', title: 'Work');
const encouraging = SoundType(id: 1, title: 'Encouraging');
const calm = SoundType(id: 2, title: 'Calm');
const astra = Voice(id: 1, name: 'Astra', voiceId: 'a');
const bold = Voice(id: 2, name: 'Bold', voiceId: 'b');

const saved = Reason(
  id: 7,
  name: 'Mornings',
  purpose: 'Sleep well every night',
  lengthSeconds: 30,
  areaId: 1,
  area: health,
  soundTypeId: 1,
  sound: encouraging,
  voiceId: 1,
  voice: astra,
);

/// Opens the dashboard, the Reasons tab and the reason's screen ([reason], with
/// [alarms] on the device).
Future<FakeReasonRepository> openDetail(
  WidgetTester tester, {
  Reason reason = saved,
  FakeAlarmRepository? alarms,
  FakeAlarmScheduler? scheduler,
  FakeRemoteAlarmRepository? remote,
}) async {
  final reasons = FakeReasonRepository(
    [reason],
    const [health, work],
    const [encouraging, calm],
    const [astra, bold],
  );
  await registerFakeAlarmDependencies(
    alarms ?? FakeAlarmRepository(),
    alarmScheduler: scheduler,
    remoteAlarmRepository: remote,
    reasonRepository: reasons,
    areaOfLifeRepository: FakeAreaOfLifeRepository(
      saved: const [health, work],
      server: const [health, work],
      areaSuggestions: const {
        1: [
          PurposeSuggestion(id: 1, areaId: 1, text: 'Rest deeply every night'),
        ],
      },
    ),
    voiceRepository: FakeVoiceRepository(
      saved: const [astra, bold],
      server: const [astra, bold],
    ),
    soundRepository: FakeSoundRepository(sounds: const [encouraging, calm]),
  );
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reasons').first);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ReasonRow));
  await tester.pumpAndSettle();
  return reasons;
}

Future<void> tapRow(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => appRouter.go(RouteNames.dashboardPath));

  test('the purpose ideas are asked once for both text sheets', () async {
    final areas = FakeAreaOfLifeRepository(
      saved: const [health],
      server: const [health],
      areaSuggestions: const {
        1: [
          PurposeSuggestion(id: 5, areaId: 1, text: 'Rest deeply every night'),
        ],
      },
    );
    await registerFakeAlarmDependencies(
      FakeAlarmRepository(),
      reasonRepository: FakeReasonRepository(
        const [saved],
        const [health],
        const [encouraging],
        const [astra],
      ),
      areaOfLifeRepository: areas,
    );
    final bloc = instance<ReasonDetailBloc>(param1: saved);
    expect(await bloc.purposeSuggestions(1), ['Rest deeply every night']);
    // The why ideas follow the purpose idea the text reads like.
    await bloc.whySuggestions(1, 'rest deeply  every night');
    expect(areas.suggestionRequests, [1]);
    expect(areas.matterRequests, [(1, 5)]);
    await bloc.close();
  });

  testWidgets('a reason opens with everything it holds', (tester) async {
    await openDetail(tester);
    expect(find.byType(ReasonDetailPage), findsOneWidget);
    expect(find.text('Mornings'), findsWidgets);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Sleep well every night'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget); // no "why" yet
    expect(find.text('Encouraging'), findsOneWidget);
    expect(find.text('Astra'), findsOneWidget);
    expect(find.text('Short · 30 sec'), findsOneWidget);
    expect(find.text('Not in an alarm yet.'), findsOneWidget);
    expect(find.text('Connect an alarm'), findsOneWidget);
    expect(find.bySemanticsLabel('More'), findsOneWidget);
    expect(find.text('Save Changes'), findsNothing);
  });

  testWidgets('a chosen area is held, then saved with Save Changes', (
    tester,
  ) async {
    final reasons = await openDetail(tester);
    await tapRow(tester, 'Area of life');
    expect(find.text('What part of life is this for?'), findsOneWidget);
    expect(find.text('Keep This Area'), findsOneWidget);

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Work'));
    await tester.pumpAndSettle();

    // Held, not saved: the row says Work and the Save bar is up.
    expect(find.text('Work'), findsOneWidget);
    expect(reasons.updates, isEmpty);
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(reasons.updates.single.$2, saved.draft.copyWith(areaId: 2));
    expect(find.text('Save Changes'), findsNothing);
  });

  testWidgets('choosing the saved value again is no change', (tester) async {
    await openDetail(tester);
    await tapRow(tester, 'Length');
    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Standard'));
    await tester.pumpAndSettle();
    expect(find.text('Standard · 45 sec'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    await tapRow(tester, 'Length');
    await tester.tap(find.text('Short'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Short'));
    await tester.pumpAndSettle();
    expect(find.text('Save Changes'), findsNothing);
  });

  testWidgets('Discard asks first, then puts the saved values back', (
    tester,
  ) async {
    final reasons = await openDetail(tester);
    await tapRow(tester, 'Tone');
    await tester.tap(find.text('Calm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Calm'));
    await tester.pumpAndSettle();
    expect(find.text('Calm'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();
    expect(find.text('Calm'), findsOneWidget);

    await tester.tap(find.text('Discard').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard').last);
    await tester.pumpAndSettle();
    expect(find.text('Encouraging'), findsOneWidget);
    expect(find.text('Save Changes'), findsNothing);
    expect(reasons.updates, isEmpty);
  });

  testWidgets('back with held changes asks before leaving', (tester) async {
    await openDetail(tester);
    await tapRow(tester, 'Voice');
    expect(find.text('Choose a voice'), findsOneWidget);
    await tester.tap(find.text('Bold'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Bold'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reasons').first);
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard').last);
    await tester.pumpAndSettle();
    expect(find.byType(ReasonDetailPage), findsNothing);
    expect(find.byType(ReasonRow), findsOneWidget);
  });

  testWidgets('the purpose sheet offers ideas and holds new words', (
    tester,
  ) async {
    await openDetail(tester);
    await tapRow(tester, 'Purpose');
    expect(find.text('What are you working toward?'), findsOneWidget);
    expect(find.text('No Changes'), findsOneWidget);

    final field = find.descendant(
      of: find.byType(AppSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, '');
    await tester.pumpAndSettle();
    expect(find.text('Rest deeply every night'), findsOneWidget);
    await tester.tap(find.text('Rest deeply every night'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use This'));
    await tester.pumpAndSettle();

    expect(find.text('Rest deeply every night'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('a save that fails says so and keeps the changes', (
    tester,
  ) async {
    final reasons = await openDetail(tester);
    reasons.offline = true;
    await tapRow(tester, 'Tone');
    await tester.tap(find.text('Calm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Calm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Couldn’t save your changes'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('back from a saved reason shows the change in the list', (
    tester,
  ) async {
    await openDetail(tester);
    await tapRow(tester, 'Tone');
    await tester.tap(find.text('Calm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Calm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reasons').first);
    await tester.pumpAndSettle();
    expect(find.byType(ReasonDetailPage), findsNothing);
    expect(find.text('Health · Calm'), findsOneWidget);
  });

  testWidgets('… → Delete Reason asks first, then deletes and goes back', (
    tester,
  ) async {
    final reasons = await openDetail(tester);
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    expect(find.text('Use with an alarm'), findsOneWidget);
    await tester.tap(find.text('Delete Reason'));
    await tester.pumpAndSettle();
    // The question comes 120 ms after the sheet has gone.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.text('Delete “Mornings”?'), findsOneWidget);
    expect(find.text('This can’t be undone.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(reasons.deletes, isEmpty);
    expect(find.byType(ReasonDetailPage), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Reason'));
    await tester.pumpAndSettle();
    // The question comes 120 ms after the sheet has gone.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(reasons.deletes, [7]);
    expect(find.byType(ReasonDetailPage), findsNothing);
    expect(find.byType(ReasonRow), findsNothing);
  });

  testWidgets('a delete that fails says so and stays', (tester) async {
    final reasons = await openDetail(tester);
    reasons.offline = true;
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Reason'));
    await tester.pumpAndSettle();
    // The question comes 120 ms after the sheet has gone.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Couldn’t delete this reason'), findsOneWidget);
    expect(find.byType(ReasonDetailPage), findsOneWidget);
  });

  group('a reason with its alarm', () {
    // Played by alarm 'a' (server alarm 12): 6:30 on Tuesday and Wednesday.
    const withAlarm = Reason(
      id: 7,
      name: 'Mornings',
      lengthSeconds: 30,
      areaId: 1,
      area: health,
      soundTypeId: 1,
      sound: encouraging,
      voiceId: 1,
      voice: astra,
      alarmId: 12,
    );
    FakeAlarmRepository alarmsWithOne() =>
        FakeAlarmRepository()
          ..store['a'] = Alarm(
            id: 'a',
            enabled: true,
            time: DateTime(2026, 11, 10, 6, 30),
            repeatWeekdays: const [2, 3],
            audioTrackId: 'morning_message',
            ringtoneId: 'default',
            reasonId: 7,
            remoteId: 12,
          );

    Future<void> askToDelete(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Reason'));
      await tester.pumpAndSettle();
      // The question comes 120 ms after the sheet has gone.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
    }

    testWidgets('shows its alarm instead of "Connect an alarm"', (
      tester,
    ) async {
      await openDetail(tester, reason: withAlarm, alarms: alarmsWithOne());
      expect(find.text('Connect an alarm'), findsNothing);
      expect(find.text('Not in an alarm yet.'), findsNothing);
      expect(find.text('6:30 AM'), findsOneWidget);
      expect(find.text('Tue Wed'), findsOneWidget);
    });

    testWidgets('deleting it deletes its alarm too, everywhere', (
      tester,
    ) async {
      final alarms = alarmsWithOne();
      final scheduler = FakeAlarmScheduler();
      final remote = FakeRemoteAlarmRepository();
      final reasons = await openDetail(
        tester,
        reason: withAlarm,
        alarms: alarms,
        scheduler: scheduler,
        remote: remote,
      );
      await askToDelete(tester);
      expect(find.text('Delete “Mornings”?'), findsOneWidget);
      expect(
        find.text('Its alarm will be deleted too. Every alarm needs a reason.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(remote.removed, [12]);
      expect(scheduler.cancelled, ['a']);
      expect(alarms.store, isEmpty);
      expect(reasons.deletes, [7]);
      expect(find.byType(ReasonDetailPage), findsNothing);
    });

    testWidgets('offline nothing is deleted', (tester) async {
      final alarms = alarmsWithOne();
      final remote = FakeRemoteAlarmRepository()..fail = true;
      final reasons = await openDetail(
        tester,
        reason: withAlarm,
        alarms: alarms,
        remote: remote,
      );
      await askToDelete(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Couldn’t delete this reason'),
        findsOneWidget,
      );
      expect(alarms.store, hasLength(1));
      expect(reasons.deletes, isEmpty);
    });
  });
}
