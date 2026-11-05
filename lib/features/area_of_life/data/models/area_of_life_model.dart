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
      title: _text(json['title']) ?? name,
      description: _text(json['description']),
      icon: _text(json['icon']),
      color: parseHexColor(json['color'] as String?),
    );
  }
}

String? _text(Object? value) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? null : text;
}

/// `"#C96B4B"` / `"C96B4B"` / `"#FFC96B4B"` to an ARGB int; null on anything else.
int? parseHexColor(String? hex) {
  final digits = (hex ?? '').trim().replaceFirst('#', '');
  final value = int.tryParse(digits, radix: 16);
  if (value == null) return null;
  return switch (digits.length) {
    6 => 0xFF000000 | value,
    8 => value,
    _ => null,
  };
}
