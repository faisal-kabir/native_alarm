import '../../../../core/utils/server_value.dart';
import '../../domain/entities/area_of_life.dart';

/// An `area_of_life` row as the server sends it (snake_case keys).
class AreaOfLifeModel extends AreaOfLife {
  const AreaOfLifeModel({
    required super.id,
    required super.name,
    required super.title,
    super.description,
    super.icon,
    super.color,
  });

  factory AreaOfLifeModel.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?) ?? '';
    return AreaOfLifeModel(
      id: (json['id'] as num).toInt(),
      name: name,
      title: cleanText(json['title']) ?? name,
      description: cleanText(json['description']),
      icon: cleanText(json['icon']),
      color: parseHexColor(json['color'] as String?),
    );
  }
}
