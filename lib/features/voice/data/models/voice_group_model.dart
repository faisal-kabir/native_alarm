import '../../../../core/utils/server_value.dart';
import '../../domain/entities/voice_group.dart';

/// A `voice_group` row as the server sends it (snake_case keys).
class VoiceGroupModel extends VoiceGroup {
  const VoiceGroupModel({
    required super.id,
    required super.title,
    super.description,
  });

  factory VoiceGroupModel.fromJson(Map<String, dynamic> json) =>
      VoiceGroupModel(
        id: (json['id'] as num).toInt(),
        title: cleanText(json['title']) ?? '',
        description: cleanText(json['description']),
      );
}
