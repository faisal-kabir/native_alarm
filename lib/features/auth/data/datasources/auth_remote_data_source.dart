import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/auth_provider.dart';
import 'social_credential_source.dart';

abstract class AuthRemoteDataSource {
  /// The user of the saved session, or null when there is none.
  User? get currentUser;

  /// The session's user now and every time it changes (signed in, linked, signed out);
  /// null while there is no session.
  Stream<User?> get userChanges;

  /// Creates a new anonymous user; the SDK saves its session on the device.
  Future<User> signInAnonymously();

  /// Adds the Apple / Google identity to the current (anonymous) user: same user, same
  /// goals, now with an account. Throws [AccountInUseException] when that identity, or
  /// its e-mail, is already another Eala account's.
  Future<User> linkWithIdToken(
    AuthProvider provider,
    SocialCredential credential,
  );

  /// Signs in to the Eala account the Apple / Google identity belongs to.
  Future<User> signInWithIdToken(
    AuthProvider provider,
    SocialCredential credential,
  );

  /// Called as the ANONYMOUS user, just before signing in to an account that already
  /// exists: a ticket for moving everything this user made to that account (the
  /// server's `start_account_merge`).
  Future<String> startMerge();

  /// Called as the ACCOUNT: moves everything of the anonymous user [ticket] was made
  /// for into this account and deletes that, now empty, user (`finish_account_merge`).
  /// All or nothing: on failure nothing has moved and the ticket still works.
  Future<void> finishMerge(String ticket);

  /// Ends the session on this device.
  Future<void> signOut();
}

/// Whether Supabase refused a link because the person already has an Eala account:
/// the identity is another user's, or its e-mail is (Supabase does not link an address
/// another account has).
@visibleForTesting
bool isAccountInUse(AuthException e) =>
    e.code == 'identity_already_exists' ||
    e.code == 'email_exists' ||
    e.message.toLowerCase().contains('already linked');

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  User? get currentUser => client.auth.currentUser;

  @override
  Stream<User?> get userChanges async* {
    yield client.auth.currentUser;
    yield* client.auth.onAuthStateChange.map((state) => state.session?.user);
  }

  @override
  Future<User> signInAnonymously() =>
      _user(() => client.auth.signInAnonymously());

  OAuthProvider _provider(AuthProvider provider) => switch (provider) {
    AuthProvider.apple => OAuthProvider.apple,
    AuthProvider.google => OAuthProvider.google,
  };

  @override
  Future<User> linkWithIdToken(
    AuthProvider provider,
    SocialCredential credential,
  ) => _user(
    () => client.auth.linkIdentityWithIdToken(
      provider: _provider(provider),
      idToken: credential.idToken,
      nonce: credential.nonce,
    ),
  );

  @override
  Future<User> signInWithIdToken(
    AuthProvider provider,
    SocialCredential credential,
  ) => _user(
    () => client.auth.signInWithIdToken(
      provider: _provider(provider),
      idToken: credential.idToken,
      nonce: credential.nonce,
    ),
  );

  @override
  Future<String> startMerge() async {
    try {
      return await client.rpc<String>('start_account_merge');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> finishMerge(String ticket) async {
    try {
      await client.rpc<void>(
        'finish_account_merge',
        params: {'p_ticket': ticket},
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<User> _user(Future<AuthResponse> Function() request) async {
    try {
      final user = (await request()).user;
      if (user == null) throw const ServerException('No user returned');
      return user;
    } on ServerException {
      rethrow;
    } on AuthException catch (e) {
      if (isAccountInUse(e)) throw const AccountInUseException();
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
