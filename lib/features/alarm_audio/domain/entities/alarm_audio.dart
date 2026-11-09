import 'package:equatable/equatable.dart';

/// Which server list an [AlarmAudio] comes from. Both have the same columns.
enum AlarmAudioKind {
  /// `alarm_sound`: the sounds an alarm rings with.
  alarmSound('alarm_sound'),

  /// `sound_track`: the music tracks.
  soundTrack('sound_track');

  const AlarmAudioKind(this.table);

  /// The server table's name (also what the device's copy is keyed by).
  final String table;
}

/// One row of `alarm_sound` or `sound_track`, as the device keeps it for making
/// alarms, offline too. [icon] and [audio] are the server's file paths; [iconFile] and
/// [audioFile] are the downloaded copies on the device (absolute paths), null until
/// they have been downloaded once.
class AlarmAudio extends Equatable {
  final AlarmAudioKind kind;
  final int id;
  final String title;
  final String? description;
  final String? icon;

  /// The server's tint as an ARGB int; null when it sent none.
  final int? color;
  final String? audio;
  final String? iconFile;
  final String? audioFile;

  const AlarmAudio({
    required this.kind,
    required this.id,
    required this.title,
    this.description,
    this.icon,
    this.color,
    this.audio,
    this.iconFile,
    this.audioFile,
  });

  @override
  List<Object?> get props => [
    kind,
    id,
    title,
    description,
    icon,
    color,
    audio,
    iconFile,
    audioFile,
  ];
}
