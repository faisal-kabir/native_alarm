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
  IntColumn get reasonId => integer().nullable()();
  IntColumn get soundTrackId => integer().nullable()();
  IntColumn get alarmSoundId => integer().nullable()();
  IntColumn get ringAgain => integer().withDefault(const Constant(0))();

  /// [Alarm.dayTimes] as JSON (`{"1": 390, ...}`), null when the days share a time.
  TextColumn get dayTimes => text().map(const DayTimesConverter()).nullable()();

  /// [Alarm.remoteId]: the server's `alarm.id`, null until uploaded.
  IntColumn get remoteId => integer().nullable()();

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

/// Stores [Alarm.dayTimes] (weekday → minutes after midnight) as a JSON object.
class DayTimesConverter extends TypeConverter<Map<int, int>, String> {
  const DayTimesConverter();

  @override
  Map<int, int> fromSql(String fromDb) => {
    for (final e in (jsonDecode(fromDb) as Map<String, dynamic>).entries)
      int.parse(e.key): (e.value as num).toInt(),
  };

  @override
  String toSql(Map<int, int> value) =>
      jsonEncode({for (final e in value.entries) '${e.key}': e.value});
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
    reasonId: reasonId,
    soundTrackId: soundTrackId,
    alarmSoundId: alarmSoundId,
    ringAgain: ringAgain,
    dayTimes: dayTimes,
    remoteId: remoteId,
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
    reasonId: Value(reasonId),
    soundTrackId: Value(soundTrackId),
    alarmSoundId: Value(alarmSoundId),
    ringAgain: Value(ringAgain),
    dayTimes: Value(dayTimes),
    remoteId: Value(remoteId),
  );
}
