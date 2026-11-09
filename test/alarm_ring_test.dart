import 'package:eala/core/platform/alarm_platform_client.dart';
import 'package:eala/features/alarm/data/platform_alarm_scheduler.dart';
import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/features/alarm_audio/domain/entities/alarm_audio.dart';
import 'package:eala/features/create_alarm/domain/entities/alarm_draft.dart';
import 'package:eala/features/create_alarm/domain/entities/alarm_schedule.dart';
import 'package:eala/features/create_alarm/domain/usecases/reschedule_alarms_usecase.dart';
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

  group('RescheduleAlarmsUseCase', () {
    // Monday 9 November 2026, 9:00.
    final now = DateTime(2026, 11, 9, 9);

    test('a repeating alarm that rang is set for its next day', () async {
      final alarms = FakeAlarmRepository();
      alarms.store['a'] = weekly(time: DateTime(2026, 11, 9, 6, 30));
      final scheduler = FakeAlarmScheduler();

      final moved = await RescheduleAlarmsUseCase(alarms, scheduler)(
        RescheduleAlarmsParams(now),
      );

      expect(moved.getOrElse(() => -1), 1);
      final next = alarms.store['a']!;
      expect(next.time, DateTime(2026, 11, 10, 6, 30));
      expect(scheduler.scheduled.single, (next, 'Mornings'));
    });

    test('alarms still ringing, one-off, switched off or ahead stay', () async {
      final alarms = FakeAlarmRepository();
      // Rang 8:50 with two ring-agains (8:55, 9:00): its last ring is not over.
      alarms.store['ringing'] = weekly(
        id: 'ringing',
        time: DateTime(2026, 11, 9, 8, 50),
        ringAgain: 2,
      );
      alarms.store['once'] = weekly(
        id: 'once',
        time: DateTime(2026, 11, 9, 6, 30),
        days: const [],
      );
      alarms.store['off'] = weekly(
        id: 'off',
        time: DateTime(2026, 11, 9, 6, 30),
        enabled: false,
      );
      alarms.store['ahead'] = weekly(
        id: 'ahead',
        time: DateTime(2026, 11, 10, 6, 30),
      );
      final before = Map.of(alarms.store);
      final scheduler = FakeAlarmScheduler();

      final moved = await RescheduleAlarmsUseCase(alarms, scheduler)(
        RescheduleAlarmsParams(now),
      );

      expect(moved.getOrElse(() => -1), 0);
      expect(alarms.store, before);
      expect(scheduler.scheduled, isEmpty);
    });

    test('an alarm the device refuses keeps its time to try again', () async {
      final alarms = FakeAlarmRepository();
      final rang = weekly(time: DateTime(2026, 11, 9, 6, 30));
      alarms.store['a'] = rang;
      final scheduler = FakeAlarmScheduler()..fail = true;

      final moved = await RescheduleAlarmsUseCase(alarms, scheduler)(
        RescheduleAlarmsParams(now),
      );

      expect(moved.getOrElse(() => -1), 0);
      expect(alarms.store['a'], rang);
    });
  });

  group('PlatformAlarmScheduler', () {
    const channel = MethodChannel('com.eala.app/alarm');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
    });

    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    PlatformAlarmScheduler scheduler(List<AlarmAudio> sounds) =>
        PlatformAlarmScheduler(
          AlarmPlatformClient(),
          FakeAlarmAudioRepository({AlarmAudioKind.alarmSound: sounds}),
        );

    const bell = AlarmAudio(
      kind: AlarmAudioKind.alarmSound,
      id: 3,
      title: 'Bell',
      audioFile: '/app/alarm_audio/alarm_sound-3-audio-ab12.mp3',
    );

    test('sends the chosen sound\'s file and the days it rings', () async {
      final alarm = weekly(
        time: DateTime(2026, 11, 9, 6, 30),
        days: const [1, 7],
        dayTimes: const {1: 390, 7: 480},
        ringAgain: 2,
        alarmSoundId: 3,
      );
      await scheduler(const [bell]).schedule(alarm, title: 'Mornings');

      final args = calls.single.arguments as Map;
      expect(calls.single.method, 'scheduleAlarm');
      expect(args['alarmId'], 'a');
      expect(args['timeMs'], alarm.time.millisecondsSinceEpoch);
      expect(args['tuneFile'], bell.audioFile);
      expect(args['ringDays'], {1: 390, 7: 480});
      expect(args['repeatCount'], 2);
      expect(args['repeatIntervalSec'], 300);
      expect(args['title'], 'Mornings');
    });

    test(
      'no file on the device or a one-off: those keys are left out',
      () async {
        final alarm = weekly(
          time: DateTime(2026, 11, 9, 6, 30),
          days: const [],
          alarmSoundId: 3,
        );
        await scheduler(const [
          AlarmAudio(kind: AlarmAudioKind.alarmSound, id: 3, title: 'Bell'),
        ]).schedule(alarm, title: 'Mornings');

        final args = calls.single.arguments as Map;
        expect(args.containsKey('tuneFile'), isFalse);
        expect(args.containsKey('ringDays'), isFalse);
      },
    );
  });
}
