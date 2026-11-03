import 'package:isar_community/isar.dart';

import '../../domain/entities/alarm.dart';

part 'alarm_isar_model.g.dart';

/// Isar row for one alarm. [alarmId] is the identity shared with the native layers.
@collection
class AlarmIsarModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String alarmId;

  late bool enabled;
  late DateTime time;
  List<int> repeatWeekdays = [];
  late String audioTrackId;
  late String ringtoneId;
  String? label;
  String? missionName;

  AlarmIsarModel();

  factory AlarmIsarModel.fromEntity(Alarm alarm) => AlarmIsarModel()
    ..alarmId = alarm.id
    ..enabled = alarm.enabled
    ..time = alarm.time
    ..repeatWeekdays = List<int>.from(alarm.repeatWeekdays)
    ..audioTrackId = alarm.audioTrackId
    ..ringtoneId = alarm.ringtoneId
    ..label = alarm.label
    ..missionName = alarm.missionName;

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
