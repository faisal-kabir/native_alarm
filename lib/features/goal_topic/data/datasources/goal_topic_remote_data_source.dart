import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/goal_topic_model.dart';

abstract class GoalTopicRemoteDataSource {
  /// Every row of the server's `goal_topic` table in chip order, each with its goals
  /// (`goal_suggestion`) and whys (`why_suggestion`) embedded: one request.
  Future<List<GoalTopicModel>> fetchTopics();

  /// The `why_suggestion` rows that belong to no topic (`topic_id` null), in order.
  Future<List<GeneralWhyModel>> fetchGeneralWhys();
}

@LazySingleton(as: GoalTopicRemoteDataSource)
class GoalTopicRemoteDataSourceImpl implements GoalTopicRemoteDataSource {
  final SupabaseClient client;

  GoalTopicRemoteDataSourceImpl(this.client);

  @override
  Future<List<GoalTopicModel>> fetchTopics() async {
    try {
      final rows = await client
          .from('goal_topic')
          .select(
            'id, label, gentle, keywords, sort_order, '
            'goals:goal_suggestion(suggestion, sort_order), '
            'whys:why_suggestion(suggestion, sort_order)',
          )
          .order('sort_order', ascending: true);
      return rows
          .map(GoalTopicModel.fromJson)
          .where((t) => t.label.isNotEmpty)
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<GeneralWhyModel>> fetchGeneralWhys() async {
    try {
      final rows = await client
          .from('why_suggestion')
          .select('id, suggestion, sort_order')
          .isFilter('topic_id', null)
          .order('sort_order', ascending: true);
      return rows
          .map(GeneralWhyModel.fromJson)
          .where((w) => w.text.isNotEmpty)
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
