import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/alarm_audio.dart';
import '../models/alarm_audio_model.dart';

abstract class AlarmAudioRemoteDataSource {
  /// Every row of [kind]'s server table, by id.
  Future<List<AlarmAudioModel>> fetchAudio(AlarmAudioKind kind);
}

@LazySingleton(as: AlarmAudioRemoteDataSource)
class AlarmAudioRemoteDataSourceImpl implements AlarmAudioRemoteDataSource {
  final SupabaseClient client;

  AlarmAudioRemoteDataSourceImpl(this.client);

  @override
  Future<List<AlarmAudioModel>> fetchAudio(AlarmAudioKind kind) async {
    try {
      final rows = await client
          .from(kind.table)
          .select('id, title, description, icon, color, audio, updated_at')
          .order('id', ascending: true);
      return [for (final row in rows) AlarmAudioModel.fromJson(kind, row)];
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
