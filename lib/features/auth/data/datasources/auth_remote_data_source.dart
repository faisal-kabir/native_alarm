import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  /// The user of the saved session, or null when there is none.
  User? get currentUser;

  /// Creates a new anonymous user; the SDK saves its session on the device.
  Future<User> signInAnonymously();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  User? get currentUser => client.auth.currentUser;

  @override
  Future<User> signInAnonymously() async {
    try {
      final response = await client.auth.signInAnonymously();
      final user = response.user;
      if (user == null) throw const ServerException('No user returned');
      return user;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
