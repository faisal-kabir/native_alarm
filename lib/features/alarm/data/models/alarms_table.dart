import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/alarm.dart';

/// SQL table `alarms`. Each row is one alarm, keyed by the id shared with the native
/// layers. Rows come back as [AlarmRecord].
@DataClassName('AlarmRecord')
class AlarmsTable extends Table {
  @override
  String get tableName => 'alarms';

  TextColumn get alarmId => text()();
  BoolColumn get enabled => boolean()();
  DateTimeColumn get time => dateTime()();
  TextColumn get repeatWeekdays =>
      text().map(const WeekdaysConverter()).withDefault(const Constant('[]'))();
  TextColumn get audioTrackId => text()();
  TextColumn get ringtoneId => text()();
  TextColumn get label => text().nullable()();
  TextColumn get missionName => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {alarmId};
}

/// Stores the weekday list (1=Mon .. 7=Sun) as a JSON array in one TEXT column.
class WeekdaysConverter extends TypeConverter<List<int>, String> {
  const WeekdaysConverter();

  @override
  List<int> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<dynamic>).cast<int>();

  @override
  String toSql(List<int> value) => jsonEncode(value);
}

extension AlarmRecordMapper on AlarmRecord {
  Alarm toEntity() => Alarm(
    id: alarmId,
    enabled: enabled,
    time: time,
    repeatWeekdays: List<int>.unmodifiable(repeatWeekdays),
    audioTrackId: audioTrackId,
    ringtoneId: ringtoneId,
    label: label,
    missionName: missionName,
  );
}

extension AlarmCompanionMapper on Alarm {
  AlarmsTableCompanion toCompanion() => AlarmsTableCompanion.insert(
    alarmId: id,
    enabled: enabled,
    time: time,
    repeatWeekdays: Value(List<int>.from(repeatWeekdays)),
    audioTrackId: audioTrackId,
    ringtoneId: ringtoneId,
    label: Value(label),
    missionName: Value(missionName),
  );
}
