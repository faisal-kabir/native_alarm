import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/sound_type_model.dart';

abstract class SoundRemoteDataSource {
  /// Every row of the server's `sound_type` table, ordered by id.
  Future<List<SoundTypeModel>> fetchSoundTypes();
}

@LazySingleton(as: SoundRemoteDataSource)
class SoundRemoteDataSourceImpl implements SoundRemoteDataSource {
  final SupabaseClient client;

  SoundRemoteDataSourceImpl(this.client);

  @override
  Future<List<SoundTypeModel>> fetchSoundTypes() async {
    try {
      final rows = await client
          .from('sound_type')
          .select()
          .order('id', ascending: true);
      return rows.map(SoundTypeModel.fromJson).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
