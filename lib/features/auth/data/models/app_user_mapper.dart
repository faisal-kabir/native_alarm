import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_provider.dart';

extension SupabaseUserMapper on User {
  /// [signedInWith] is the provider just used to sign in, when known; otherwise the
  /// provider is the identity (Apple / Google) signed in with most recently. One
  /// account can hold both (same e-mail), and the app names the last one used.
  AppUser toEntity({AuthProvider? signedInWith}) => AppUser(
    id: id,
    isAnonymous: isAnonymous,
    provider: isAnonymous ? null : signedInWith ?? _lastProvider(),
    email: email,
  );

  AuthProvider? _lastProvider() {
    AuthProvider? last;
    DateTime? lastAt;
    for (final identity in identities ?? const <UserIdentity>[]) {
      final provider = AuthProvider.fromValue(identity.provider);
      if (provider == null) continue;
      final at = DateTime.tryParse(identity.lastSignInAt ?? '');
      if (last == null ||
          (at != null && (lastAt == null || at.isAfter(lastAt)))) {
        last = provider;
        lastAt = at;
      }
    }
    return last ?? AuthProvider.fromValue(appMetadata['provider'] as String?);
  }
}
