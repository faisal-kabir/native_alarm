import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/new_reason.dart';

abstract class ReasonRemoteDataSource {
  /// The signed-in user's `user.id` (the row's first column), for `reason.user_id`.
  Future<int> fetchOwnUserId();

  /// Names of [userId]'s reasons that start with [base] (to pick an unused name).
  Future<List<String>> fetchNamesStartingWith(int userId, String base);

  /// Inserts the reason with [name] for [userId]; returns the new row's id.
  Future<int> insertReason(int userId, String name, NewReason reason);

  Future<void> updateName(int id, String name);
}

@LazySingleton(as: ReasonRemoteDataSource)
class ReasonRemoteDataSourceImpl implements ReasonRemoteDataSource {
  final SupabaseClient client;

  ReasonRemoteDataSourceImpl(this.client);

  @override
  Future<int> fetchOwnUserId() async {
    final authUserId = client.auth.currentUser?.id;
    if (authUserId == null) throw const ServerException('Not signed in');
    try {
      final row = await client
          .from('user')
          .select('id')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      if (row == null) throw const ServerException('No user row yet');
      return (row['id'] as num).toInt();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<String>> fetchNamesStartingWith(int userId, String base) async {
    try {
      // LIKE treats % and _ as wildcards: escape them in the base name.
      final pattern = base.replaceAllMapped(
        RegExp(r'[\\%_]'),
        (m) => '\\${m[0]}',
      );
      final rows = await client
          .from('reason')
          .select('name')
          .eq('user_id', userId)
          .like('name', '$pattern%');
      return [for (final row in rows) (row['name'] as String?) ?? ''];
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<int> insertReason(int userId, String name, NewReason reason) async {
    try {
      final row = await client
          .from('reason')
          .insert({
            'user_id': userId,
            'area_id': reason.areaId,
            'name': name,
            'purpose': reason.purpose,
            'why': reason.why,
            'sound_type_id': reason.soundTypeId,
            'voice_id': reason.voiceId,
            'length': reason.lengthSeconds,
          })
          .select('id')
          .single();
      return (row['id'] as num).toInt();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateName(int id, String name) async {
    try {
      await client
          .from('reason')
          .update({
            'name': name,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
