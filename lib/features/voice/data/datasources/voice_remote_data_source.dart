import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/voice_model.dart';

abstract class VoiceRemoteDataSource {
  /// Every row of the server's `voice` table, ordered by id, each with its
  /// `voice_group` row joined in (needs the `group_id` foreign key).
  Future<List<VoiceModel>> fetchVoices();
}

@LazySingleton(as: VoiceRemoteDataSource)
class VoiceRemoteDataSourceImpl implements VoiceRemoteDataSource {
  final SupabaseClient client;

  VoiceRemoteDataSourceImpl(this.client);

  @override
  Future<List<VoiceModel>> fetchVoices() async {
    try {
      final rows = await client
          .from('voice')
          .select('*, voice_group(id, title, description)')
          .order('id', ascending: true);
      return rows.map(VoiceModel.fromJson).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
