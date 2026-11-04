import 'dart:io';

import 'package:drift/native.dart';
import 'package:eala/core/database/app_database.dart';
import 'package:eala/features/alarm/data/datasources/alarm_local_data_source.dart';
import 'package:eala/features/alarm/data/models/alarms_table.dart';
import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:flutter_test/flutter_test.dart';

final _alarm = Alarm(
  id: 'alarm_1',
  enabled: true,
  time: DateTime(2026, 11, 5, 4, 0),
  repeatWeekdays: const [1, 5],
  audioTrackId: 'morning_message',
  ringtoneId: 'default',
  label: 'Tahajjat Alarm 1',
  missionName: 'Start Morning Mission',
);

void main() {
  test(
    'save updates by alarmId, delete removes, list is sorted by time',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final source = AlarmLocalDataSourceImpl(db);

      await source.saveAlarm(_alarm);
      await source.saveAlarm(
        _alarm.copyWith(id: 'alarm_0', time: DateTime(2026, 11, 5, 3, 0)),
      );
      await source.saveAlarm(_alarm.copyWith(enabled: false));

      final rows = await source.getAlarms();
      expect(rows.map((r) => r.alarmId), ['alarm_0', 'alarm_1']);
      expect(rows.last.toEntity(), _alarm.copyWith(enabled: false));

      await source.deleteAlarm('alarm_0');
      expect((await source.getAlarms()).map((r) => r.alarmId), ['alarm_1']);
      await db.close();
    },
  );

  test(
    'alarms survive closing and reopening the database file (app restart)',
    () async {
      final dir = await Directory.systemTemp.createTemp('drift_alarm_test');
      final file = File('${dir.path}/eala.sqlite');

      var db = AppDatabase(NativeDatabase(file));
      await AlarmLocalDataSourceImpl(db).saveAlarm(_alarm);
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      final rows = await AlarmLocalDataSourceImpl(db).getAlarms();
      expect(rows.single.toEntity(), _alarm);
      await db.close();
      await dir.delete(recursive: true);
    },
  );
}
