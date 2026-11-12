import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/auth_provider.dart';

/// What Apple or Google handed back: the token Supabase checks, and what goes with it.
class SocialCredential {
  const SocialCredential({required this.idToken, this.nonce, this.name});

  /// The signed identity token (a JWT) from the provider.
  final String idToken;

  /// The plain nonce the token was requested with (Apple only; the token holds its hash).
  final String? nonce;

  /// The person's name, when the provider gave it (Apple, the first time only).
  final String? name;
}

/// Asks Apple or Google, with their own sheets, who the person is. The one place the two
/// provider SDKs are used, so the rest of the app (and its tests) never touch them.
abstract class SocialCredentialSource {
  /// The credential of the account the person chose. Throws [CancelledException] when
  /// they closed the sheet, [ServerException] when the provider failed.
  Future<SocialCredential> request(AuthProvider provider);
}

@LazySingleton(as: SocialCredentialSource)
class SocialCredentialSourceImpl implements SocialCredentialSource {
  bool _googleReady = false;

  @override
  Future<SocialCredential> request(AuthProvider provider) async {
    try {
      return switch (provider) {
        AuthProvider.apple => await _apple(),
        AuthProvider.google => await _google(),
      };
    } on CancelledException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const CancelledException();
      }
      throw ServerException(e.message);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const CancelledException();
      }
      throw ServerException(e.description ?? e.code.name);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<SocialCredential> _apple() async {
    // Apple puts the HASH of this in the token; Supabase is given the plain one to check.
    final raw = _randomNonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: sha256.convert(utf8.encode(raw)).toString(),
    );
    final token = credential.identityToken;
    if (token == null) throw const ServerException('Apple sent no token');
    final name = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    return SocialCredential(
      idToken: token,
      nonce: raw,
      name: name.isEmpty ? null : name,
    );
  }

  Future<SocialCredential> _google() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        serverClientId: AppConstant.googleServerClientId,
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? AppConstant.googleIosClientId
            : null,
      );
      _googleReady = true;
    }
    final account = await google.authenticate();
    final token = account.authentication.idToken;
    if (token == null) throw const ServerException('Google sent no token');
    final name = account.displayName;
    return SocialCredential(
      idToken: token,
      name: name == null || name.trim().isEmpty ? null : name,
    );
  }

  static String _randomNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
