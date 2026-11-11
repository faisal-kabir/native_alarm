import 'dart:convert';

import '../../../../core/utils/server_value.dart';
import '../../domain/entities/goal_topic.dart';

/// A `goal_topic` row as the server sends it with its goals and whys embedded
/// (`goals:goal_suggestion(...)`, `whys:why_suggestion(...)`, snake_case keys).
class GoalTopicModel extends GoalTopic {
  const GoalTopicModel({
    required super.id,
    required super.label,
    super.gentle,
    super.keywords,
    super.sortOrder,
    super.goals,
    super.whys,
  });

  factory GoalTopicModel.fromJson(Map<String, dynamic> json) => GoalTopicModel(
    id: (json['id'] as num).toInt(),
    label: cleanText(json['label']) ?? '',
    gentle: json['gentle'] == true,
    keywords: cleanText(json['keywords']) ?? '',
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    goals: _texts(json['goals']),
    whys: _texts(json['whys']),
  );

  /// The embedded rows' `suggestion` texts in `sort_order`, blanks left out.
  static List<String> _texts(Object? rows) {
    if (rows is! List) return const [];
    final list = [
      for (final row in rows)
        if (row is Map<String, dynamic>)
          if (cleanText(row['suggestion']) case final text?)
            ((row['sort_order'] as num?)?.toInt() ?? 0, text),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final item in list) item.$2];
  }

  /// A list of texts as the one JSON string the device keeps it as.
  static String encode(List<String> texts) => jsonEncode(texts);

  /// The texts back from [encode]'s string; empty when it can not be read.
  static List<String> decode(String json) {
    try {
      final data = jsonDecode(json);
      return data is List ? [for (final t in data) '$t'] : const [];
    } catch (_) {
      return const [];
    }
  }
}

/// A general `why_suggestion` row (`topic_id` null).
class GeneralWhyModel {
  const GeneralWhyModel({
    required this.id,
    required this.text,
    required this.sortOrder,
  });

  factory GeneralWhyModel.fromJson(Map<String, dynamic> json) =>
      GeneralWhyModel(
        id: (json['id'] as num).toInt(),
        text: cleanText(json['suggestion']) ?? '',
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );

  final int id;
  final String text;
  final int sortOrder;
}
