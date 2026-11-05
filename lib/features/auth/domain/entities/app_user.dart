import 'package:equatable/equatable.dart';

/// The person using the app, as Supabase Auth knows them.
class AppUser extends Equatable {
  /// Supabase Auth UUID (`auth.users.id`, the value of `auth.uid()` in policies).
  final String id;

  /// True until the user signs in with Google or Apple.
  final bool isAnonymous;

  const AppUser({required this.id, required this.isAnonymous});

  @override
  List<Object?> get props => [id, isAnonymous];
}
