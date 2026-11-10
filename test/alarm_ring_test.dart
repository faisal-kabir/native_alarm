import 'package:eala/core/platform/alarm_platform_client.dart';
import 'package:eala/features/alarm/data/system_alarm_manager.dart';
import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/features/alarm_audio/domain/entities/alarm_audio.dart';
import 'package:eala/features/create_alarm/domain/entities/alarm_draft.dart';
import 'package:eala/features/reasons/domain/entities/reason.dart';
import 'package:eala/features/create_alarm/domain/entities/alarm_schedule.dart';
import 'package:eala/features/alarm/domain/usecases/get_alarms_usecase.dart';
import 'package:eala/features/create_alarm/domain/usecases/sync_system_alarms_usecase.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

/// Sunday 8 November 2026.
Alarm weekly({
  String id = 'a',
  required DateTime time,
  List<int> days = const [1, 2, 3, 4, 5],
  Map<int, int>? dayTimes,
  int ringAgain = 0,
  bool enabled = true,
  int? alarmSoundId,
}) => Alarm(
  id: id,
  enabled: enabled,
  time: time,
  repeatWeekdays: days,
  audioTrackId: 'morning_message',
  ringtoneId: 'default',
  label: 'Mornings',
  missionName: 'Mornings',
  ringAgain: ringAgain,
  dayTimes: dayTimes,
  alarmSoundId: alarmSoundId,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a saved alarm\'s next ring', () {
    test('minutes after midnight read back as the 12-hour time', () {
      expect(AlarmTime.fromMinutes(0), const AlarmTime(12, 0));
      expect(AlarmTime.fromMinutes(390), const AlarmTime(6, 30));
      expect(AlarmTime.fromMinutes(750), const AlarmTime(12, 30, pm: true));
      expect(AlarmTime.fromMinutes(1035), const AlarmTime(5, 15, pm: true));
      for (final m in [0, 59, 720, 1439]) {
        expect(AlarmTime.fromMinutes(m).minutesOfDay, m);
      }
    });

    test('weekdays ring on the next weekday at their time', () {
      // Rang Friday 6:30; now Saturday: next is Monday 6:30.
      final alarm = weekly(time: DateTime(2026, 11, 6, 6, 30));
      expect(
        nextRingOf(alarm, DateTime(2026, 11, 7, 9)),
        DateTime(2026, 11, 9, 6, 30),
      );
      // Monday morning before 6:30: today.
      expect(
        nextRingOf(alarm, DateTime(2026, 11, 9, 6)),
        DateTime(2026, 11, 9, 6, 30),
      );
    });

    test('each day keeps its own time', () {
      // Mon 6:30, Sun 8:00 (1 = Mon .. 7 = Sun).
      final alarm = weekly(
        time: DateTime(2026, 11, 2, 6, 30),
        days: const [1, 7],
        dayTimes: const {1: 390, 7: 480},
      );
      expect(alarm.ringDays, {1: 390, 7: 480});
      expect(
        nextRingOf(alarm, DateTime(2026, 11, 8, 7)),
        DateTime(2026, 11, 8, 8),
      );
      expect(
        nextRingOf(alarm, DateTime(2026, 11, 8, 9)),
        DateTime(2026, 11, 9, 6, 30),
      );
    });

    test(
      'ring days are every day at the alarm\'s time, none for a one-off',
      () {
        expect(
          weekly(time: DateTime(2026, 11, 9, 6, 30), days: [1, 3]).ringDays,
          {1: 390, 3: 390},
        );
        expect(
          weekly(time: DateTime(2026, 11, 9, 6, 30), days: const []).ringDays,
          isEmpty,
        );
      },
    );
  });

  group('SyncSystemAlarmsUseCase', () {
    // Monday 9 November 2026, 9:00.
    final now = DateTime(2026, 11, 9, 9);

    SyncSystemAlarmsUseCase sync(
      FakeAlarmRepository alarms,
      FakeAlarmScheduler scheduler, {
      List<Reason> reasons = const [],
    }) => SyncSystemAlarmsUseCase(
      GetAlarmsUseCase(alarms),
      alarms,
      FakeReasonRepository(reasons),
      scheduler,
    );

    test('every alarm goes to the device, a rung week moved on', () async {
      final alarms = FakeAlarmRepository();
      alarms.store['a'] = weekly(time: DateTime(2026, 11, 9, 6, 30));
      alarms.store['off'] = weekly(
        id: 'off',
        time: DateTime(2026, 11, 9, 6, 30),
        enabled: false,
      );
      final scheduler = FakeAlarmScheduler();

      final result = await sync(alarms, scheduler)(SyncSystemAlarmsParams(now));

      expect(result.isRight(), isTrue);
      final next = alarms.store['a']!;
      expect(next.time, DateTime(2026, 11, 10, 6, 30));
      expect(scheduler.synced, [
        (alarm: next, title: 'Mornings'),
        (alarm: alarms.store['off']!, title: 'Mornings'),
      ]);
    });

    test('one still ringing keeps its time; a rung one-off is switched off', () async {
      final alarms = FakeAlarmRepository();
      // Rang 8:50 with two ring-agains (8:55, 9:00): its last ring is not over.
      final ringing = weekly(
        id: 'ringing',
        time: DateTime(2026, 11, 9, 8, 50),
        ringAgain: 2,
      );
      alarms.store['ringing'] = ringing;
      alarms.store['once'] = weekly(
        id: 'once',
        time: DateTime(2026, 11, 9, 6, 30),
        days: const [],
      );
      final scheduler = FakeAlarmScheduler();

      await sync(alarms, scheduler)(SyncSystemAlarmsParams(now));

      expect(alarms.store['ringing'], ringing);
      expect(alarms.store['once']!.enabled, isFalse);
    });

    test('the text follows the Reason\'s current name', () async {
      final alarms = FakeAlarmRepository();
      alarms.store['a'] = weekly(time: DateTime(2026, 11, 10, 6, 30))
          .copyWith(label: 'Old');
      final withReason = Alarm(
        id: 'a',
        enabled: true,
        time: DateTime(2026, 11, 10, 6, 30),
        repeatWeekdays: const [1, 2],
        audioTrackId: 'morning_message',
        ringtoneId: 'default',
        label: 'Old',
        missionName: 'Old',
        reasonId: 4,
      );
      alarms.store['a'] = withReason;
      final scheduler = FakeAlarmScheduler();

      await sync(
        alarms,
        scheduler,
        reasons: [testReason(id: 4, name: 'Renamed')],
      )(SyncSystemAlarmsParams(now));

      expect(alarms.store['a']!.missionName, 'Renamed');
      expect(scheduler.synced.single.title, 'Renamed');
    });

    test('a device that refuses says so', () async {
      final alarms = FakeAlarmRepository()
        ..store['a'] = weekly(time: DateTime(2026, 11, 10, 6, 30));
      final result = await sync(alarms, FakeAlarmScheduler()..fail = true)(
        SyncSystemAlarmsParams(now),
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('SystemAlarmManager', () {
    const channel = MethodChannel('com.eala.app/alarm');
    final calls = <MethodCall>[];
    // What native answers `syncAlarms` with: id -> signature.
    var held = <String, String>{};

    setUp(() {
      calls.clear();
      held = {};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'syncAlarms' ? held : null;
          });
    });

    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    SystemAlarmManager manager(List<AlarmAudio> sounds) => SystemAlarmManager(
      AlarmPlatformClient(),
      FakeAlarmAudioRepository({AlarmAudioKind.alarmSound: sounds}),
    );

    const bell = AlarmAudio(
      kind: AlarmAudioKind.alarmSound,
      id: 3,
      title: 'Bell',
      audioFile: '/app/alarm_audio/alarm_sound-3-audio-ab12.mp3',
    );

    test(
      'sends the chosen sound\'s file, the days it rings, a signature',
      () async {
        final alarm = weekly(
          time: DateTime(2026, 11, 9, 6, 30),
          days: const [1, 7],
          dayTimes: const {1: 390, 7: 480},
          ringAgain: 2,
          alarmSoundId: 3,
        );
        await manager(const [bell]).schedule(alarm, title: 'Mornings');

        final args = calls.single.arguments as Map;
        expect(calls.single.method, 'scheduleAlarm');
        expect(args['alarmId'], 'a');
        expect(args['timeMs'], alarm.time.millisecondsSinceEpoch);
        expect(args['tuneFile'], bell.audioFile);
        expect(args['ringDays'], {1: 390, 7: 480});
        expect(args['repeatCount'], 2);
        expect(args['repeatIntervalSec'], 300);
        expect(args['title'], 'Mornings');
        expect(args['missionName'], 'Mornings');
        expect(args['signature'], isA<String>());
      },
    );

    test(
      'no file on the device or a one-off: those keys are left out',
      () async {
        final alarm = weekly(
          time: DateTime(2026, 11, 9, 6, 30),
          days: const [],
          alarmSoundId: 3,
        );
        await manager(const [
          AlarmAudio(kind: AlarmAudioKind.alarmSound, id: 3, title: 'Bell'),
        ]).schedule(alarm, title: 'Mornings');

        final args = calls.single.arguments as Map;
        expect(args.containsKey('tuneFile'), isFalse);
        expect(args.containsKey('ringDays'), isFalse);
      },
    );

    test(
      'sync sets only what is missing or changed, takes off the rest',
      () async {
        final now = DateTime(2026, 11, 9, 9);
        final same = weekly(id: 'same', time: DateTime(2026, 11, 10, 6, 30));
        final renamed = weekly(
          id: 'renamed',
          time: DateTime(2026, 11, 10, 6, 30),
        );
        final missing = weekly(
          id: 'missing',
          time: DateTime(2026, 11, 10, 6, 30),
        );
        final off = weekly(
          id: 'off',
          time: DateTime(2026, 11, 10, 6, 30),
          enabled: false,
        );
        final rungOnce = weekly(
          id: 'rung',
          time: DateTime(2026, 11, 9, 6, 30),
          days: const [],
        );
        final sut = manager(const []);
        // What `same` and `renamed` were set with before.
        await sut.schedule(same, title: 'Mornings');
        await sut.schedule(renamed, title: 'Mornings');
        held = {
          for (final c in calls)
            (c.arguments as Map)['alarmId'] as String:
                (c.arguments as Map)['signature'] as String,
          'off': 'x',
        };
        calls.clear();

        await sut.sync([
          (alarm: same, title: 'Mornings'),
          (alarm: renamed, title: 'New name'),
          (alarm: missing, title: 'Mornings'),
          (alarm: off, title: 'Mornings'),
          (alarm: rungOnce, title: 'Mornings'),
        ], now: now);

        expect(calls.first.method, 'syncAlarms');
        expect((calls.first.arguments as Map)['keepIds'], [
          'same',
          'renamed',
          'missing',
          'off',
          'rung',
        ]);
        expect(
          [
            for (final c in calls.skip(1))
              '${c.method} ${(c.arguments as Map)['alarmId']}',
          ],
          ['scheduleAlarm renamed', 'scheduleAlarm missing', 'cancelAlarm off'],
        );
      },
    );

    test('snooze rings once more under its own id', () async {
      await manager(const [])
          .snooze('a', at: DateTime(2026, 11, 9, 9, 5), title: 'Mornings');
      final args = calls.single.arguments as Map;
      expect(args['alarmId'], 'snooze_a');
      expect(args['repeatCount'], 0);
      expect(
        args['timeMs'],
        DateTime(2026, 11, 9, 9, 5).millisecondsSinceEpoch,
      );
    });
  });
}
