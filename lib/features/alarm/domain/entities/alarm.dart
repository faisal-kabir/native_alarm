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

  const Alarm({
    required this.id,
    required this.enabled,
    required this.time,
    this.repeatWeekdays = const [],
    required this.audioTrackId,
    required this.ringtoneId,
    this.label,
    this.missionName,
  });

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
