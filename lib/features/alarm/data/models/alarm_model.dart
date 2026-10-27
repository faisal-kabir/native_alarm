// lib/features/alarm/data/models/alarm_model.dart
import 'package:equatable/equatable.dart';

/// Data model used for persistence (e.g., shared_preferences, sqflite).
class AlarmModel extends Equatable {
  final String id;
  final bool enabled;
  final DateTime time;
  final List<int> repeatWeekdays;
  final String audioTrackId;
  final String ringtoneId;
  final String? label;
  final String? missionName;

  const AlarmModel({
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

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
    id: json['id'] as String,
    enabled: json['enabled'] as bool,
    time: DateTime.parse(json['time'] as String),
    repeatWeekdays: List<int>.from(json['repeatWeekdays'] ?? []),
    audioTrackId: json['audioTrackId'] as String,
    ringtoneId: json['ringtoneId'] as String,
    label: json['label'] as String?,
    missionName: json['missionName'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'enabled': enabled,
    'time': time.toIso8601String(),
    'repeatWeekdays': repeatWeekdays,
    'audioTrackId': audioTrackId,
    'ringtoneId': ringtoneId,
    if (label != null) 'label': label,
    if (missionName != null) 'missionName': missionName,
  };
}
