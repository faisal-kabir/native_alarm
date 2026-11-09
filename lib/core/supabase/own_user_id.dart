import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/exceptions.dart';

/// The signed-in person's `user.id` (the server's own row id, which `reason.user_id`
/// and `alarm.user_id` point at). It never changes for a sign-in, so it is asked once;
/// a new sign-in asks again. Throws [ServerException] when there is no session or no
/// row yet.
@lazySingleton
class OwnUserId {
  final SupabaseClient client;

  OwnUserId(this.client);

  /// How long a request waits for the session the app opens on start.
  static const Duration _sessionWait = Duration(seconds: 15);

  String? _userIdFor;
  int? _userId;

  Future<int> call() async {
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
}
