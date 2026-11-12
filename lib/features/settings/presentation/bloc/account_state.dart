import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/auth_provider.dart';

/// Where the account stands, as the screens say it.
enum AccountStatus {
  /// An anonymous user of this device: "Not signed in".
  signedOut,

  /// "Signed in with Apple".
  apple,

  /// "Signed in with Google".
  google,

  /// Signed in, with an account that is neither: "Signed in on this device".
  thisDevice,
}

/// Something the person should be told, once.
enum AccountNotice { none, signInFailed, signOutFailed, nameFailed }

class AccountState extends Equatable {
  /// Who is signed in; null until the session is known.
  final AppUser? user;

  /// The saved first name; empty while none is set.
  final String name;

  /// How the account was last signed in to, as the profile (`user.primary_provider`)
  /// says; null when it names no provider we know.
  final AuthProvider? lastProvider;

  /// True once the saved name has been read.
  final bool loaded;

  /// A sign-in, a sign-out or a name save is on its way (its button waits).
  final bool busy;

  /// What to tell the person ([noticeCount] changes with every notice, so the same one
  /// twice in a row is still heard).
  final AccountNotice notice;
  final int noticeCount;

  const AccountState({
    this.user,
    this.name = '',
    this.lastProvider,
    this.loaded = false,
    this.busy = false,
    this.notice = AccountNotice.none,
    this.noticeCount = 0,
  });

  /// Whether a real account (Apple or Google) is signed in.
  bool get signedIn => user?.signedIn ?? false;

  /// The provider the account was last signed in with: the profile's, which every
  /// sign-in writes (on any device), else the session's.
  AuthProvider? get provider => lastProvider ?? user?.provider;

  AccountStatus get status {
    if (!signedIn) return AccountStatus.signedOut;
    return switch (provider) {
      AuthProvider.apple => AccountStatus.apple,
      AuthProvider.google => AccountStatus.google,
      null => AccountStatus.thisDevice,
    };
  }

  AccountState copyWith({
    AppUser? Function()? user,
    String? name,
    AuthProvider? Function()? lastProvider,
    bool? loaded,
    bool? busy,
    AccountNotice? notice,
  }) => AccountState(
    user: user == null ? this.user : user(),
    name: name ?? this.name,
    lastProvider: lastProvider == null ? this.lastProvider : lastProvider(),
    loaded: loaded ?? this.loaded,
    busy: busy ?? this.busy,
    notice: notice ?? this.notice,
    noticeCount: notice == null || notice == AccountNotice.none
        ? noticeCount
        : noticeCount + 1,
  );

  @override
  List<Object?> get props => [
    user,
    name,
    lastProvider,
    loaded,
    busy,
    notice,
    noticeCount,
  ];
}
