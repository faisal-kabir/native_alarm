import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/area_of_life_model.dart';

abstract class AreaOfLifeRemoteDataSource {
  /// Every row of the server's `area_of_life` table, ordered by id.
  Future<List<AreaOfLifeModel>> fetchAreas();
}

@LazySingleton(as: AreaOfLifeRemoteDataSource)
class AreaOfLifeRemoteDataSourceImpl implements AreaOfLifeRemoteDataSource {
  final SupabaseClient client;

  AreaOfLifeRemoteDataSourceImpl(this.client);

  @override
  Future<List<AreaOfLifeModel>> fetchAreas() async {
    try {
      final rows = await client.from('area_of_life').select().order('id');
      return rows.map(AreaOfLifeModel.fromJson).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
