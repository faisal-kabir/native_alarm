import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/sound_quote_model.dart';
import '../models/sound_type_model.dart';

abstract class SoundRemoteDataSource {
  /// Every row of the server's `sound_type` table, ordered by id.
  Future<List<SoundTypeModel>> fetchSoundTypes();

  /// The first `quotes_of_sound` row (by id) of [areaId] and [soundId], or null.
  Future<SoundQuoteModel?> fetchSoundQuote(int areaId, int soundId);
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

  @override
  Future<SoundQuoteModel?> fetchSoundQuote(int areaId, int soundId) async {
    try {
      final row = await client
          .from('quotes_of_sound')
          .select()
          .eq('area_id', areaId)
          .eq('sound_id', soundId)
          .order('id', ascending: true)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      final quote = SoundQuoteModel.fromJson(row);
      return quote.text.isEmpty ? null : quote;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
