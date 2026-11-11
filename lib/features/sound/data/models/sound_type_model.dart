import '../../../../core/utils/server_value.dart';
import '../../domain/entities/sound_type.dart';

/// A `sound_type` row as the server sends it (snake_case keys).
class SoundTypeModel extends SoundType {
  const SoundTypeModel({
    required super.id,
    required super.title,
    super.description,
    super.icon,
    super.color,
    super.sample,
  });

  factory SoundTypeModel.fromJson(Map<String, dynamic> json) => SoundTypeModel(
    id: (json['id'] as num).toInt(),
    title: cleanText(json['title']) ?? '',
    description: cleanText(json['description']),
    icon: cleanText(json['icon']),
    color: parseHexColor(json['color'] as String?),
    sample: cleanText(json['sample']),
  );
}
