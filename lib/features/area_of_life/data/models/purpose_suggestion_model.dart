import '../../../../core/utils/server_value.dart';
import '../../domain/entities/purpose_suggestion.dart';

/// A `purpose_suggestion` row as the server sends it (snake_case keys).
class PurposeSuggestionModel extends PurposeSuggestion {
  const PurposeSuggestionModel({
    required super.id,
    required super.areaId,
    required super.text,
  });

  factory PurposeSuggestionModel.fromJson(Map<String, dynamic> json) =>
      PurposeSuggestionModel(
        id: (json['id'] as num).toInt(),
        areaId: (json['area_id'] as num).toInt(),
        text: cleanText(json['suggestion']) ?? '',
      );
}
