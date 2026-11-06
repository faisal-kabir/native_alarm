import '../../../../core/utils/server_value.dart';
import '../../domain/entities/voice.dart';
import 'voice_group_model.dart';

/// A `voice` row as the server sends it (snake_case keys), with its group joined in
/// under `voice_group`.
class VoiceModel extends Voice {
  const VoiceModel({
    required super.id,
    required super.name,
    required super.voiceId,
    super.audio,
    super.avatar,
    super.groupId,
    super.group,
    super.gender,
    super.accent,
    super.traits,
    super.color,
    super.isPremium,
  });

  factory VoiceModel.fromJson(Map<String, dynamic> json) {
    final name = cleanText(json['name']) ?? '';
    return VoiceModel(
      id: (json['id'] as num).toInt(),
      name: name,
      voiceId: cleanText(json['voice_id']) ?? '',
      audio: cleanText(json['audio']),
      avatar: cleanText(json['avatar']),
      groupId: (json['group_id'] as num?)?.toInt(),
      group: switch (json['voice_group']) {
        final Map<String, dynamic> row => VoiceGroupModel.fromJson(row),
        _ => null,
      },
      gender: cleanText(json['gender']),
      accent: cleanText(json['accent']),
      traits: cleanText(json['traits']),
      color: parseHexColor(json['color'] as String?),
      isPremium: json['is_premium'] == true,
    );
  }
}
