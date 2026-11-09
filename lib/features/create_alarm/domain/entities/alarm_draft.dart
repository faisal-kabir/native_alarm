import 'package:equatable/equatable.dart';

/// A 12-hour clock time: [hour] 1-12, [minute] 0-59, [pm] for PM.
class AlarmTime extends Equatable {
  const AlarmTime(this.hour, this.minute, {this.pm = false});

  /// The time [minutes] after midnight (the reverse of [minutesOfDay]).
  factory AlarmTime.fromMinutes(int minutes) {
    final hour = minutes ~/ 60 % 24;
    return AlarmTime(
      hour % 12 == 0 ? 12 : hour % 12,
      minutes % 60,
      pm: hour >= 12,
    );
  }

  final int hour;
  final int minute;
  final bool pm;

  AlarmTime copyWith({int? hour, int? minute, bool? pm}) =>
      AlarmTime(hour ?? this.hour, minute ?? this.minute, pm: pm ?? this.pm);

  /// "6:30".
  String get clock => '$hour:${minute.toString().padLeft(2, '0')}';

  /// "AM" / "PM".
  String get meridiem => pm ? 'PM' : 'AM';

  /// "6:30 AM".
  String get label => '$clock $meridiem';

  /// Minutes after midnight (12 AM = 0).
  int get minutesOfDay => (hour % 12 + (pm ? 12 : 0)) * 60 + minute;

  @override
  List<Object?> get props => [hour, minute, pm];
}

/// What the alarm editor edits: when it rings, which Reason it plays, the two sounds,
/// ring again, on or off. Days are 0 = Sunday ... 6 = Saturday (as the design counts).
class AlarmDraft extends Equatable {
  AlarmDraft({
    this.time = const AlarmTime(6, 30),
    List<int> days = const [],
    this.byDay,
    this.reasonId,
    this.soundTrackId,
    this.alarmSoundId,
    this.again = 0,
    this.enabled = true,
  }) : days = List.unmodifiable(days);

  /// The one time of a simple alarm (with [byDay], the first day's time).
  final AlarmTime time;

  /// The days that ring, sorted. Empty = once.
  final List<int> days;

  /// A time for each day that rings, when the days do not all share one.
  final Map<int, AlarmTime>? byDay;

  /// The Reason it plays (null until one is chosen: there is no default).
  final int? reasonId;

  /// The `sound_track` (music behind the message) and `alarm_sound` (the ring) rows.
  final int? soundTrackId;
  final int? alarmSoundId;

  /// Ring again if I'm not up: 0 off, 1 once, 2 twice (5 minutes apart).
  final int again;
  final bool enabled;

  AlarmDraft copyWith({
    int? reasonId,
    int? soundTrackId,
    int? alarmSoundId,
    int? again,
    bool? enabled,
  }) => AlarmDraft(
    time: time,
    days: days,
    byDay: byDay,
    reasonId: reasonId ?? this.reasonId,
    soundTrackId: soundTrackId ?? this.soundTrackId,
    alarmSoundId: alarmSoundId ?? this.alarmSoundId,
    again: again ?? this.again,
    enabled: enabled ?? this.enabled,
  );

  /// The same alarm with its schedule replaced (a null [byDay] removes the list).
  AlarmDraft withSchedule({
    required AlarmTime time,
    required List<int> days,
    Map<int, AlarmTime>? byDay,
  }) => AlarmDraft(
    time: time,
    days: days,
    byDay: byDay,
    reasonId: reasonId,
    soundTrackId: soundTrackId,
    alarmSoundId: alarmSoundId,
    again: again,
    enabled: enabled,
  );

  @override
  List<Object?> get props => [
    time,
    days,
    byDay,
    reasonId,
    soundTrackId,
    alarmSoundId,
    again,
    enabled,
  ];
}

/// One schedule in the editor (a card): a time and the days that ring at it. [id] is
/// local to the editor and never saved.
class ScheduleCard extends Equatable {
  const ScheduleCard({
    required this.id,
    required this.time,
    required this.days,
  });

  final String id;
  final AlarmTime time;
  final List<int> days;

  ScheduleCard copyWith({AlarmTime? time, List<int>? days}) =>
      ScheduleCard(id: id, time: time ?? this.time, days: days ?? this.days);

  @override
  List<Object?> get props => [id, time, days];
}
