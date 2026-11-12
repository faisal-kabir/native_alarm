import 'package:equatable/equatable.dart';

import 'auth_provider.dart';

/// The person using the app, as Supabase Auth knows them.
class AppUser extends Equatable {
  /// Supabase Auth UUID (`auth.users.id`, the value of `auth.uid()` in policies).
  final String id;

  /// True until the user signs in with Google or Apple.
  final bool isAnonymous;

  /// The provider they signed in with; null while [isAnonymous].
  final AuthProvider? provider;

  /// The e-mail their account has, if the provider gave one.
  final String? email;

  const AppUser({
    required this.id,
    required this.isAnonymous,
    this.provider,
    this.email,
  });

  /// Whether this is a real account (Apple or Google), not just this device.
  bool get signedIn => !isAnonymous;

  @override
  List<Object?> get props => [id, isAnonymous, provider, email];
}
