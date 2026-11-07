import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/server_value.dart';
import '../../domain/entities/reason.dart';

/// A `reason` row as the server sends it, with its area (`area_of_life`) and sound
/// (`sound_type`) joined in, plus when it was made (the list's order).
class ReasonModel extends Reason {
  const ReasonModel({
    required super.id,
    required super.name,
    required super.areaName,
    super.areaColor,
    required super.toneName,
    this.createdAt,
  });

  final DateTime? createdAt;

  factory ReasonModel.fromJson(Map<String, dynamic> json) {
    final area = json['area_of_life'] as Map<String, dynamic>?;
    final sound = json['sound_type'] as Map<String, dynamic>?;
    return ReasonModel(
      id: '${json['id']}',
      name: cleanText(json['name']) ?? '',
      areaName: cleanText(area?['title']) ?? cleanText(area?['name']) ?? '',
      areaColor: parseHexColor(area?['color'] as String?),
      toneName: cleanText(sound?['title']) ?? '',
      createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal(),
    );
  }

  ReasonsTableCompanion toCompanion() => ReasonsTableCompanion(
    reasonId: Value(id),
    name: Value(name),
    areaName: Value(areaName),
    areaColor: Value(areaColor),
    toneName: Value(toneName),
    createdAt: createdAt == null ? const Value.absent() : Value(createdAt!),
  );
}
