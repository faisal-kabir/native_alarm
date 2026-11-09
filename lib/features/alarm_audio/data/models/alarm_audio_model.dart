import '../../../../core/utils/server_value.dart';
import '../../domain/entities/alarm_audio.dart';

/// An `alarm_sound` / `sound_track` row as the server sends it (snake_case keys).
/// [updatedAt] is the server's text as sent: with the file paths it decides whether a
/// downloaded file is still the current one.
class AlarmAudioModel extends AlarmAudio {
  final String? updatedAt;

  const AlarmAudioModel({
    required super.kind,
    required super.id,
    required super.title,
    super.description,
    super.icon,
    super.color,
    super.audio,
    this.updatedAt,
  });

  factory AlarmAudioModel.fromJson(
    AlarmAudioKind kind,
    Map<String, dynamic> json,
  ) => AlarmAudioModel(
    kind: kind,
    id: (json['id'] as num).toInt(),
    title: cleanText(json['title']) ?? '',
    description: cleanText(json['description']),
    icon: cleanText(json['icon']),
    color: parseHexColor(json['color'] as String?),
    audio: cleanText(json['audio']),
    updatedAt: cleanText(json['updated_at']),
  );
}
