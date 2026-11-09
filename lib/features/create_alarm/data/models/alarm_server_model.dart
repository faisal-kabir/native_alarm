import 'dart:convert';

import '../../../alarm/domain/entities/alarm.dart';
import '../../../reasons/data/models/reason_model.dart';
import '../../domain/entities/alarm_draft.dart';
import '../../domain/entities/alarm_schedule.dart';

/// One `alarm` row with everything it points at, as one object (foreign keys):
/// `sub_alarms` (its other schedules), `reason` (whole, with its own joins, as
/// [reasonSelect]), `sound_track` and `alarm_sound`. `reason` is named by its column
/// because `reason.alarm_id` links the two tables the other way too.
const String alarmSelect =
    '*, sub_alarms:sub_alarm(*), reason:reason!reason_id($reasonSelect), '
    'sound_track(*), alarm_sound(*)';

/// The day names `week_days` holds, by editor day (0 = Sun .. 6 = Sat).
const List<String> serverDayNames = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

/// One schedule as the server keeps it (an `alarm` or a `sub_alarm` row): its next
/// ring and its days (editor days, 0 = Sun; empty = rings once).
typedef ServerSchedule = ({DateTime time, List<int> days});

/// [alarm]'s schedules as the editor shows them (weekdays before the weekend): the
/// first goes in `alarm`, the others in `sub_alarm`.
List<ServerSchedule> serverSchedules(Alarm alarm, DateTime now) => [
  for (final card in groupDays(alarmDraftOf(alarm), () => ''))
    (
      // A one-off alarm keeps its own date.
      time: card.days.isEmpty
          ? alarm.time
          : nextRing(AlarmDraft(time: card.time, days: card.days), now),
      days: card.days,
    ),
];

/// The `time` and `week_days` columns of [schedule] (`week_days` is a JSON array of
/// day names: `["Mon","Tue"]`).
Map<String, Object?> scheduleColumns(ServerSchedule schedule) => {
  'time': schedule.time.toUtc().toIso8601String(),
  'week_days': jsonEncode([for (final d in schedule.days) serverDayNames[d]]),
};

/// The `alarm` columns of [alarm] holding its [first] schedule (what an edit
/// writes).
Map<String, Object?> alarmUpdateColumns(Alarm alarm, ServerSchedule first) => {
  ...scheduleColumns(first),
  'reason_id': alarm.reasonId,
  'sound_track_id': alarm.soundTrackId,
  'alarm_sound_id': alarm.alarmSoundId,
  'number_of_ring': alarm.ringAgain,
  'enable': alarm.enabled,
};

/// The new `alarm` row for [alarm] of [userId], holding its [first] schedule.
Map<String, Object?> alarmColumns(
  Alarm alarm,
  int userId,
  ServerSchedule first,
) => {'user_id': userId, ...alarmUpdateColumns(alarm, first)};

/// [local] as the server's [json] ([alarmSelect]) holds it: its server id, days and
/// times (from `alarm` and `sub_alarms`), Reason (and its name), sounds, ring again
/// and on / off. What only the device knows (its id, next ring, native tracks) stays
/// from [local].
Alarm alarmFromServer(Map<String, dynamic> json, Alarm local) {
  int? id(Object? value) => (value as num?)?.toInt();
  final rows = [
    json,
    ...(json['sub_alarms'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>(),
  ];
  // Each day the alarm rings (1 = Mon .. 7 = Sun) and its time of day.
  final byDay = <int, int>{
    for (final row in rows)
      for (final day in _days(row['week_days']))
        alarmWeekday(day): _minutes(row['time']),
  };
  final reason = json['reason'] as Map<String, dynamic>?;
  final name = reason?['name'] as String? ?? local.label;
  return Alarm(
    id: local.id,
    enabled: json['enable'] as bool? ?? local.enabled,
    time: local.time,
    repeatWeekdays: List.unmodifiable(byDay.keys.toList()..sort()),
    audioTrackId: local.audioTrackId,
    ringtoneId: local.ringtoneId,
    label: name,
    missionName: name,
    reasonId: id(json['reason_id']),
    soundTrackId: id(json['sound_track_id']),
    alarmSoundId: id(json['alarm_sound_id']),
    ringAgain: id(json['number_of_ring']) ?? 0,
    dayTimes: byDay.values.toSet().length > 1 ? byDay : null,
    remoteId: id(json['id']),
  );
}

/// `week_days` as editor days: a JSON array of names (or the array itself).
List<int> _days(Object? value) {
  final list = value is String ? jsonDecode(value) : value;
  return [
    for (final name in list as List<dynamic>? ?? const [])
      if (serverDayNames.contains(name)) serverDayNames.indexOf(name as String),
  ];
}

/// A `time` value as minutes after midnight on this device's clock.
int _minutes(Object? value) {
  final time = DateTime.parse(value as String).toLocal();
  return time.hour * 60 + time.minute;
}
