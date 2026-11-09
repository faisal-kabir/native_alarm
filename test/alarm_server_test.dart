import 'dart:convert';

import 'package:drift/native.dart';
import 'package:eala/core/database/app_database.dart';
import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/features/create_alarm/data/datasources/alarm_remote_data_source.dart';
import 'package:eala/features/create_alarm/data/models/alarm_server_model.dart';
import 'package:eala/features/create_alarm/data/repositories/remote_alarm_repository_impl.dart';
import 'package:eala/features/reasons/data/datasources/reason_local_data_source.dart';
import 'package:eala/features/reasons/data/models/reasons_table.dart';
import 'package:eala/features/create_alarm/domain/usecases/upload_pending_alarms_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

/// The server in tests: an inserted alarm becomes [id], its Reason linked to it.
class FakeAlarmRemote implements AlarmRemoteDataSource {
  FakeAlarmRemote(this.id);

  final int id;

  Map<String, dynamic> reasonRow(int? alarmId) => {
    'id': 7,
    'name': 'Mornings',
    'area_id': 1,
    'sound_type_id': 1,
    'voice_id': 1,
    'alarm_id': alarmId,
  };

  @override
  Future<Map<String, dynamic>> insertAlarm(Alarm alarm, DateTime now) async {
    final schedule = serverSchedules(alarm, now).first;
    return {
      'id': id,
      ...alarmColumns(alarm, 5, schedule),
      'sub_alarms': const [],
      'reason': reasonRow(id),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> deleteAlarm(int id) async => [
    reasonRow(null),
  ];
}

void main() {
  // Saturday 8 Nov 2026, 7:00.
  final now = DateTime(2026, 11, 8, 7);

  // 6:30 on weekdays, 8:00 at the weekend, on the server as alarm 12.
  final weekAndWeekend = Alarm(
    id: 'alarm_1',
    enabled: true,
    time: DateTime(2026, 11, 8, 8),
    repeatWeekdays: const [1, 2, 3, 4, 5, 6, 7],
    audioTrackId: 'morning_message',
    ringtoneId: '3',
    label: 'Mornings',
    missionName: 'Mornings',
    reasonId: 7,
    soundTrackId: 2,
    alarmSoundId: 3,
    ringAgain: 1,
    dayTimes: const {1: 390, 2: 390, 3: 390, 4: 390, 5: 390, 6: 480, 7: 480},
  );

  group('alarm on the server', () {
    test('the first schedule is the week, the weekend a sub alarm', () {
      final schedules = serverSchedules(weekAndWeekend, now);
      expect(schedules, hasLength(2));
      expect(schedules[0].days, [1, 2, 3, 4, 5]);
      expect(schedules[0].time, DateTime(2026, 11, 9, 6, 30)); // Monday
      expect(schedules[1].days, [0, 6]);
      expect(schedules[1].time, DateTime(2026, 11, 8, 8)); // later today

      final row = alarmColumns(weekAndWeekend, 5, schedules.first);
      expect(row, {
        'user_id': 5,
        'time': DateTime(2026, 11, 9, 6, 30).toUtc().toIso8601String(),
        'week_days': '["Mon","Tue","Wed","Thu","Fri"]',
        'reason_id': 7,
        'sound_track_id': 2,
        'alarm_sound_id': 3,
        'number_of_ring': 1,
        'enable': true,
      });
    });

    test('a one-off alarm keeps its own date and has no days', () {
      final once = Alarm(
        id: 'a',
        enabled: true,
        time: DateTime(2026, 11, 9, 6, 30),
        audioTrackId: 'm',
        ringtoneId: 'default',
      );
      final schedules = serverSchedules(once, now);
      expect(schedules.single.time, DateTime(2026, 11, 9, 6, 30));
      expect(scheduleColumns(schedules.single)['week_days'], '[]');
    });

    test('the joined object reads back as the same alarm', () {
      final schedules = serverSchedules(weekAndWeekend, now);
      String time(DateTime t) => t.toUtc().toIso8601String();
      final json = <String, dynamic>{
        'id': 12,
        ...alarmColumns(weekAndWeekend, 5, schedules.first),
        'time': time(schedules[0].time),
        'sub_alarms': [
          {
            'id': 30,
            'alarm_id': 12,
            'time': time(schedules[1].time),
            'week_days': jsonEncode(['Sun', 'Sat']),
          },
        ],
        'reason': {'id': 7, 'name': 'Mornings, renamed'},
        'sound_track': {'id': 2},
        'alarm_sound': {'id': 3},
      };

      final alarm = alarmFromServer(json, weekAndWeekend);
      expect(alarm.remoteId, 12);
      expect(alarm.repeatWeekdays, weekAndWeekend.repeatWeekdays);
      expect(alarm.dayTimes, weekAndWeekend.dayTimes);
      expect(alarm.label, 'Mornings, renamed');
      expect(alarm.ringAgain, 1);
      expect(alarm.time, weekAndWeekend.time);
      expect(alarm.id, weekAndWeekend.id);
    });
  });

  group('UploadPendingAlarmsUseCase', () {
    test(
      'sends only the alarms made offline, and keeps their server id',
      () async {
        final alarms = FakeAlarmRepository();
        alarms.store['alarm_1'] = weekAndWeekend;
        alarms.store['sent'] = weekAndWeekend.copyWith(id: 'sent', remoteId: 4);
        alarms.store['old'] = Alarm(
          id: 'old',
          enabled: true,
          time: now,
          audioTrackId: 'm',
          ringtoneId: 'default',
        );
        final remote = FakeRemoteAlarmRepository();

        final sent = await UploadPendingAlarmsUseCase(alarms, remote)(
          UploadPendingAlarmsParams(now),
        );

        expect(sent.getOrElse(() => -1), 1);
        expect(remote.uploaded.single.id, 'alarm_1');
        expect(alarms.store['alarm_1']!.remoteId, 1);
      },
    );

    test('offline they wait for the next open', () async {
      final alarms = FakeAlarmRepository()..store['alarm_1'] = weekAndWeekend;
      final sent = await UploadPendingAlarmsUseCase(
        alarms,
        FakeRemoteAlarmRepository()..fail = true,
      )(UploadPendingAlarmsParams(now));
      expect(sent.isLeft(), isTrue);
      expect(alarms.store['alarm_1']!.remoteId, isNull);
    });
  });

  group('RemoteAlarmRepositoryImpl', () {
    late AppDatabase db;
    late ReasonLocalDataSourceImpl reasons;
    late RemoteAlarmRepositoryImpl repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      reasons = ReasonLocalDataSourceImpl(db);
      repository = RemoteAlarmRepositoryImpl(FakeAlarmRemote(12), reasons);
    });

    tearDown(() => db.close());

    Future<int?> savedAlarmId() async =>
        (await db.select(db.reasonsTable).getSingle()).toEntity().alarmId;

    test('the Reason an alarm takes is saved with its alarm_id', () async {
      final uploaded = await repository.upload(weekAndWeekend, now: now);
      expect(uploaded.getOrElse(() => throw 'failed').remoteId, 12);
      expect(await savedAlarmId(), 12);
    });

    test('an alarm taken back frees its Reason on the device', () async {
      await repository.upload(weekAndWeekend, now: now);
      await repository.remove(12);
      expect(await savedAlarmId(), isNull);
    });
  });
}
