import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/new_reason.dart';
import '../models/reason_model.dart';

abstract class ReasonRemoteDataSource {
  /// The signed-in user's `user.id` (the row's first column), for `reason.user_id`.
  Future<int> fetchOwnUserId();

  /// Names of [userId]'s reasons that start with [base] (to pick an unused name).
  Future<List<String>> fetchNamesStartingWith(int userId, String base);

  /// Inserts the reason with [name] for [userId]; returns the new row's id.
  Future<int> insertReason(int userId, String name, NewReason reason);

  Future<void> updateName(int id, String name);

  /// All of the signed-in user's reasons, oldest first, with each one's area title
  /// and colour and sound title joined in.
  Future<List<ReasonModel>> fetchReasons();
}

@LazySingleton(as: ReasonRemoteDataSource)
class ReasonRemoteDataSourceImpl implements ReasonRemoteDataSource {
  final SupabaseClient client;

  ReasonRemoteDataSourceImpl(this.client);

  /// How long a request waits for the session the app opens on start.
  static const Duration _sessionWait = Duration(seconds: 15);

  /// The signed-in user's auth id. Right after launch the session may still be
  /// opening (the dashboard starts it), so this waits for it a little.
  Future<String> _authUserId() async {
    final now = client.auth.currentUser?.id;
    if (now != null) return now;
    try {
      final id = await client.auth.onAuthStateChange
          .map((s) => s.session?.user.id)
          .firstWhere((id) => id != null)
          .timeout(_sessionWait);
      return id!;
    } catch (_) {
      throw const ServerException('Not signed in');
    }
  }

  @override
  Future<int> fetchOwnUserId() async {
    final authUserId = await _authUserId();
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

  @override
  Future<List<ReasonModel>> fetchReasons() async {
    final userId = await fetchOwnUserId();
    try {
      // One request: the area and the sound come along over the reason's foreign
      // keys (`area_id` → area_of_life, `sound_type_id` → sound_type).
      final rows = await client
          .from('reason')
          .select(
            'id, name, created_at, area_of_life(title, name, color), '
            'sound_type(title)',
          )
          .eq('user_id', userId)
          .order('id', ascending: true);
      return [for (final row in rows) ReasonModel.fromJson(row)];
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
