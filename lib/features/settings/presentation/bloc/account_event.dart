import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/auth_provider.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

/// Starts following who is signed in and reads the saved name. Sent by every screen
/// that shows the account; only the first one does anything.
class AccountStartedEvent extends AccountEvent {
  const AccountStartedEvent();
}

/// "Save" on the Profile screen: the first name, already checked.
class AccountNameSavedEvent extends AccountEvent {
  final String name;

  const AccountNameSavedEvent(this.name);

  @override
  List<Object?> get props => [name];
}

/// A button of the sign-in sheet: "Sign in with Apple" / "Sign in with Google".
class AccountSignInRequestedEvent extends AccountEvent {
  final AuthProvider provider;

  const AccountSignInRequestedEvent(this.provider);

  @override
  List<Object?> get props => [provider];
}

/// "Sign Out", after the person confirmed.
class AccountSignOutRequestedEvent extends AccountEvent {
  const AccountSignOutRequestedEvent();
}
