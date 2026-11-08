import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/reason_draft.dart';
import '../models/reason_model.dart';

abstract class ReasonRemoteDataSource {
  /// The signed-in user's `user.id` (the row's first column), for `reason.user_id`.
  Future<int> fetchOwnUserId();

  /// Names of [userId]'s reasons that start with [base] (to pick an unused name).
  Future<List<String>> fetchNamesStartingWith(int userId, String base);

  /// Inserts the reason for [userId] as [name]; returns the new row with its joins
  /// ([reasonSelect]).
  Future<Map<String, dynamic>> insertReason(
    int userId,
    String name,
    ReasonDraft draft,
  );

  /// Writes [changes] (column → value) into reason [id]; returns the row as saved,
  /// with its joins.
  Future<Map<String, dynamic>> updateReason(
    int id,
    Map<String, Object?> changes,
  );

  /// All of the signed-in user's reasons, oldest first, each with its joins.
  Future<List<Map<String, dynamic>>> fetchReasons();

  /// Deletes reason [id]. Throws when the server deleted nothing (gone already, or
  /// not allowed), so the device never drops a reason the server still has.
  Future<void> deleteReason(int id);
}

/// The `reason` columns a [ReasonDraft] fills ("why" empty → null).
Map<String, Object?> reasonDraftColumns(ReasonDraft draft) => {
  'area_id': draft.areaId,
  'purpose': draft.purpose.trim(),
  'why': draft.why.trim().isEmpty ? null : draft.why.trim(),
  'sound_type_id': draft.soundTypeId,
  'voice_id': draft.voiceId,
  'length': draft.lengthSeconds,
};

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

  /// The `user.id` found for an auth id: it never changes, so it is asked once (a
  /// refresh or a new reason then needs one request less). A new sign-in asks again.
  String? _userIdFor;
  int? _userId;

  @override
  Future<int> fetchOwnUserId() async {
    final authUserId = await _authUserId();
    final known = _userId;
    if (known != null && _userIdFor == authUserId) return known;
    try {
      final row = await client
          .from('user')
          .select('id')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      if (row == null) throw const ServerException('No user row yet');
      _userIdFor = authUserId;
      return _userId = (row['id'] as num).toInt();
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
  Future<Map<String, dynamic>> insertReason(
    int userId,
    String name,
    ReasonDraft draft,
  ) async {
    try {
      return await client
          .from('reason')
          .insert({
            'user_id': userId,
            'name': name,
            ...reasonDraftColumns(draft),
          })
          .select(reasonSelect)
          .single();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> updateReason(
    int id,
    Map<String, Object?> changes,
  ) async {
    try {
      return await client
          .from('reason')
          .update({
            ...changes,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select(reasonSelect)
          .single();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReasons() async {
    final userId = await fetchOwnUserId();
    try {
      // One request: each reason with its area, sound and voice (foreign keys).
      return await client
          .from('reason')
          .select(reasonSelect)
          .eq('user_id', userId)
          .order('id', ascending: true);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteReason(int id) async {
    List<Map<String, dynamic>> deleted;
    try {
      // `select` returns the rows really deleted: row-level security that does not
      // allow it deletes nothing and reports no error.
      deleted = await client.from('reason').delete().eq('id', id).select('id');
    } catch (e) {
      throw ServerException(e.toString());
    }
    if (deleted.isEmpty) throw const ServerException('Reason not deleted');
  }
}
