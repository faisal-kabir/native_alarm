import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/area_of_life_model.dart';
import '../models/purpose_suggestion_model.dart';

abstract class AreaOfLifeRemoteDataSource {
  /// Every row of the server's `area_of_life` table, ordered by id.
  Future<List<AreaOfLifeModel>> fetchAreas();

  /// The rows of the server's `purpose_suggestion` table that belong to [areaId].
  Future<List<PurposeSuggestionModel>> fetchPurposeSuggestions(int areaId);
}

@LazySingleton(as: AreaOfLifeRemoteDataSource)
class AreaOfLifeRemoteDataSourceImpl implements AreaOfLifeRemoteDataSource {
  final SupabaseClient client;

  AreaOfLifeRemoteDataSourceImpl(this.client);

  @override
  Future<List<AreaOfLifeModel>> fetchAreas() async {
    try {
      final rows = await client
          .from('area_of_life')
          .select()
          .order('id', ascending: true);
      return rows.map(AreaOfLifeModel.fromJson).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PurposeSuggestionModel>> fetchPurposeSuggestions(
    int areaId,
  ) async {
    try {
      final rows = await client
          .from('purpose_suggestion')
          .select()
          .eq('area_id', areaId)
          .order('id', ascending: true);
      return rows
          .map(PurposeSuggestionModel.fromJson)
          .where((q) => q.text.isNotEmpty)
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
