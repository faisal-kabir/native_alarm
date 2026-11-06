import '../../../../core/utils/server_value.dart';
import '../../domain/entities/matter_suggestion.dart';

/// A `matter_suggestion` row as the server sends it (snake_case keys).
class MatterSuggestionModel extends MatterSuggestion {
  const MatterSuggestionModel({
    required super.id,
    required super.areaId,
    super.purposeSuggestionId,
    required super.text,
  });

  factory MatterSuggestionModel.fromJson(Map<String, dynamic> json) =>
      MatterSuggestionModel(
        id: (json['id'] as num).toInt(),
        areaId: (json['area_id'] as num).toInt(),
        purposeSuggestionId: (json['purpose_suggestion_id'] as num?)?.toInt(),
        text: cleanText(json['suggestion']) ?? '',
      );
}
