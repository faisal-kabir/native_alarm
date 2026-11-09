// lib/features/alarm/domain/entities/alarm.dart
import 'package:equatable/equatable.dart';

import '../../data/models/alarm_model.dart';

/// Core Alarm entity used throughout the app.
class Alarm extends Equatable {
  final String id;
  final bool enabled;
  final DateTime time;
  final List<int> repeatWeekdays; // 1=Mon .. 7=Sun
  final String audioTrackId;
  final String ringtoneId;
  final String? label;
  final String? missionName;

  /// The Reason it plays (the server's `reason.id`); null for older alarms.
  final int? reasonId;

  /// The chosen `sound_track` and `alarm_sound` rows (cached on the device).
  final int? soundTrackId;
  final int? alarmSoundId;

  /// "Ring again if I'm not up": 0 off, 1 once, 2 twice (5 minutes apart).
  final int ringAgain;

  /// When its days do not all ring at one time: each day (1=Mon .. 7=Sun) and its
  /// time as minutes after midnight. Null = every day in [repeatWeekdays] rings at
  /// [time]'s hour and minute.
  final Map<int, int>? dayTimes;

  /// The server's `alarm.id` for it; null until it has reached the server (made
  /// offline, it is sent when the app next opens online).
  final int? remoteId;

  const Alarm({
    required this.id,
    required this.enabled,
    required this.time,
    this.repeatWeekdays = const [],
    required this.audioTrackId,
    required this.ringtoneId,
    this.label,
    this.missionName,
    this.reasonId,
    this.soundTrackId,
    this.alarmSoundId,
    this.ringAgain = 0,
    this.dayTimes,
    this.remoteId,
  });

  /// The days it repeats on (1=Mon .. 7=Sun) and each day's time as minutes after
  /// midnight; empty for a one-off alarm.
  Map<int, int> get ringDays => repeatWeekdays.isEmpty
      ? const {}
      : dayTimes ??
            {for (final d in repeatWeekdays) d: time.hour * 60 + time.minute};

  @override
  List<Object?> get props => [
    id,
    enabled,
    time,
    repeatWeekdays,
    audioTrackId,
    ringtoneId,
    label,
    missionName,
    reasonId,
    soundTrackId,
    alarmSoundId,
    ringAgain,
    dayTimes,
    remoteId,
  ];

  Alarm copyWith({
    String? id,
    bool? enabled,
    DateTime? time,
    List<int>? repeatWeekdays,
    String? audioTrackId,
    String? ringtoneId,
    String? label,
    String? missionName,
    int? remoteId,
  }) {
    return Alarm(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      audioTrackId: audioTrackId ?? this.audioTrackId,
      ringtoneId: ringtoneId ?? this.ringtoneId,
      label: label ?? this.label,
      missionName: missionName ?? this.missionName,
      reasonId: reasonId,
      soundTrackId: soundTrackId,
      alarmSoundId: alarmSoundId,
      ringAgain: ringAgain,
      dayTimes: dayTimes,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  factory Alarm.fromModel(AlarmModel model) => Alarm(
    id: model.id,
    enabled: model.enabled,
    time: model.time,
    repeatWeekdays: model.repeatWeekdays,
    audioTrackId: model.audioTrackId,
    ringtoneId: model.ringtoneId,
    label: model.label,
    missionName: model.missionName,
  );

  AlarmModel toModel() => AlarmModel(
    id: id,
    enabled: enabled,
    time: time,
    repeatWeekdays: repeatWeekdays,
    audioTrackId: audioTrackId,
    ringtoneId: ringtoneId,
    label: label,
    missionName: missionName,
  );
}
