import 'package:eala/core/error/exceptions.dart';
import 'package:eala/core/notification/fcm_token.dart';
import 'package:eala/core/error/failures.dart';
import 'package:eala/core/usecase/usecase.dart';
import 'package:eala/features/alarm_audio/domain/usecases/refresh_alarm_audio_usecase.dart';
import 'package:eala/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:eala/features/auth/data/datasources/pending_merge_local_data_source.dart';
import 'package:eala/features/auth/data/datasources/social_credential_source.dart';
import 'package:eala/features/auth/data/models/app_user_mapper.dart';
import 'package:eala/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:eala/features/auth/domain/entities/auth_provider.dart';
import 'package:eala/features/auth/domain/entities/app_user.dart';
import 'package:eala/features/alarm/domain/usecases/get_alarms_usecase.dart';
import 'package:eala/features/create_alarm/domain/usecases/sync_system_alarms_usecase.dart';
import 'package:eala/features/create_alarm/domain/usecases/upload_pending_alarms_usecase.dart';
import 'package:eala/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:eala/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:eala/features/auth/domain/usecases/ensure_signed_in_usecase.dart';
import 'package:eala/features/auth/domain/usecases/finish_account_merge_usecase.dart';
import 'package:eala/features/auth/domain/usecases/sync_user_profile_usecase.dart';
import 'package:eala/features/auth/domain/usecases/update_device_info_usecase.dart';
import 'package:eala/features/settings/domain/usecases/get_app_info_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes/fake_alarm_repository.dart';

User _user(
  String id, {
  bool anonymous = true,
  String? provider,
  String? email,
}) => User(
  id: id,
  appMetadata: provider == null ? const {} : {'provider': provider},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-11-05T00:00:00Z',
  isAnonymous: anonymous,
  email: email,
  identities: provider == null
      ? null
      : [
          UserIdentity(
            id: 'i1',
            userId: id,
            identityData: const {},
            identityId: 'i1',
            provider: provider,
            createdAt: '2026-11-05T00:00:00Z',
            lastSignInAt: '2026-11-05T00:00:00Z',
          ),
        ],
);

class _FakeRemote implements AuthRemoteDataSource {
  _FakeRemote({this.saved, this.fail = false, this.taken = false});

  User? saved;
  final bool fail;

  /// The Apple / Google identity already belongs to another account.
  final bool taken;
  int signIns = 0;
  final List<String> calls = [];

  /// The server refuses the ticket, the switch to the account, or the move.
  bool startFails = false;
  bool signInFails = false;
  bool finishFails = false;

  @override
  Stream<User?> get userChanges async* {
    yield saved;
  }

  @override
  Future<User> linkWithIdToken(
    AuthProvider provider,
    SocialCredential credential,
  ) async {
    calls.add('link ${provider.value}');
    if (taken) throw const AccountInUseException();
    return saved = _user(
      saved!.id,
      anonymous: false,
      provider: provider.value,
      email: 'a@b.c',
    );
  }

  @override
  Future<User> signInWithIdToken(
    AuthProvider provider,
    SocialCredential credential,
  ) async {
    calls.add('signin ${provider.value}');
    if (signInFails) throw const ServerException('offline');
    return saved = _user(
      'account-uuid',
      anonymous: false,
      provider: provider.value,
    );
  }

  @override
  Future<String> startMerge() async {
    calls.add('start merge');
    if (startFails) throw const ServerException('offline');
    return 'ticket-1';
  }

  @override
  Future<void> finishMerge(String ticket) async {
    calls.add('finish merge $ticket');
    if (finishFails) throw const ServerException('offline');
  }

  @override
  Future<void> signOut() async {
    calls.add('signout');
    if (fail) throw const ServerException('offline');
    saved = null;
  }

  @override
  User? get currentUser => saved;

  @override
  Future<User> signInAnonymously() async {
    signIns++;
    if (fail) throw const ServerException('offline');
    return saved = _user('new-uuid');
  }
}

/// What Apple or Google would hand back, or what going wrong looks like.
class _FakeCredentials implements SocialCredentialSource {
  _FakeCredentials({this.error});

  final Exception? error;

  @override
  Future<SocialCredential> request(AuthProvider provider) async {
    if (error != null) throw error!;
    return SocialCredential(
      idToken: 'token-${provider.value}',
      nonce: 'n',
      name: 'Alex Rivers',
    );
  }
}

/// The device's storage for a merge's ticket, in memory.
class _FakePendingMerge implements PendingMergeLocalDataSource {
  String? ticket;

  @override
  Future<String?> read() async => ticket;

  @override
  Future<void> write(String ticket) async => this.ticket = ticket;

  @override
  Future<void> clear() async => ticket = null;
}

AuthRepositoryImpl _repo(
  _FakeRemote remote, [
  Exception? error,
  _FakePendingMerge? pending,
]) => AuthRepositoryImpl(
  remote,
  _FakeCredentials(error: error),
  pending ?? _FakePendingMerge(),
);

void main() {
  test('a saved session is reused; no new anonymous user is created', () async {
    final remote = _FakeRemote(saved: _user('saved-uuid', anonymous: false));
    final result = await _repo(remote).ensureSignedIn();

    expect(
      result.getOrElse(() => throw 'no user'),
      const AppUser(id: 'saved-uuid', isAnonymous: false),
    );
    expect(remote.signIns, 0);
  });

  test('without a session an anonymous user is created once', () async {
    final remote = _FakeRemote();
    final repo = _repo(remote);

    final first = await repo.ensureSignedIn();
    final second = await repo.ensureSignedIn();

    expect(first.getOrElse(() => throw 'no user').id, 'new-uuid');
    expect(first.getOrElse(() => throw 'no user').isAnonymous, isTrue);
    expect(second.getOrElse(() => throw 'no user').id, 'new-uuid');
    expect(remote.signIns, 1);
  });

  test('offline sign-in becomes a ServerFailure instead of a crash', () async {
    final result = await _repo(_FakeRemote(fail: true)).ensureSignedIn();
    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });

  test('the Dashboard ensures a session when asked', () async {
    final auth = FakeAuthRepository();
    final profiles = FakeUserProfileRepository();
    final audio = FakeAlarmAudioRepository();
    final reasons = FakeReasonRepository();
    final bloc = DashboardBloc(
      FakeAnalyticsService(),
      EnsureSignedInUseCase(auth),
      FinishAccountMergeUseCase(auth, reasons),
      SyncUserProfileUseCase(profiles),
      UpdateDeviceInfoUseCase(profiles),
      GetAppInfoUseCase(FakeSettingsRepository()),
      RefreshAlarmAudioUseCase(audio),
      SyncSystemAlarmsUseCase(
        GetAlarmsUseCase(FakeAlarmRepository()),
        FakeAlarmRepository(),
        FakeReasonRepository(),
        FakeAlarmScheduler(),
      ),
      UploadPendingAlarmsUseCase(
        FakeAlarmRepository(),
        FakeRemoteAlarmRepository(),
      ),
    )..add(const EnsureSessionEvent());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(auth.calls, 1);
    // Once signed in, the user's row is saved on the device.
    expect(profiles.syncs, 1);
    // ...and the alarm sounds and tracks are brought up to date.
    expect(audio.refreshes, 1);
    // ...and a move into an account is looked for; none waited, so the goals stay.
    expect(auth.mergeChecks, 1);
    expect(reasons.refreshes, 0);
    await bloc.close();
  });

  test('a move into an account left unfinished is finished on start', () async {
    final auth = FakeAuthRepository()..mergeWaiting = true;
    final reasons = FakeReasonRepository();
    final result = await FinishAccountMergeUseCase(auth, reasons)(NoParams());
    expect(result.getOrElse(() => false), isTrue);
    expect(reasons.refreshes, 1, reason: 'the moved goals are read again');
  });

  test('a refreshed FCM token is passed on to the server', () async {
    final auth = FakeAuthRepository();
    final profiles = FakeUserProfileRepository();
    final audio = FakeAlarmAudioRepository();
    final reasons = FakeReasonRepository();
    final bloc = DashboardBloc(
      FakeAnalyticsService(),
      EnsureSignedInUseCase(auth),
      FinishAccountMergeUseCase(auth, reasons),
      SyncUserProfileUseCase(profiles),
      UpdateDeviceInfoUseCase(profiles),
      GetAppInfoUseCase(FakeSettingsRepository()),
      RefreshAlarmAudioUseCase(audio),
      SyncSystemAlarmsUseCase(
        GetAlarmsUseCase(FakeAlarmRepository()),
        FakeAlarmRepository(),
        FakeReasonRepository(),
        FakeAlarmScheduler(),
      ),
      UploadPendingAlarmsUseCase(
        FakeAlarmRepository(),
        FakeRemoteAlarmRepository(),
      ),
    );

    setFcmToken('fresh-token');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(profiles.deviceUpdates.last.fcmToken, 'fresh-token');
    expect(profiles.deviceUpdates.last.appVersion, '1.0.0+1');
    await bloc.close();
    setFcmToken(null);
  });

  group('signing in', () {
    test('an anonymous user is LINKED, so their goals stay theirs', () async {
      final remote = _FakeRemote(saved: _user('anon-uuid'));
      final result = await _repo(remote).signIn(AuthProvider.google);

      final signedIn = result.getOrElse(() => throw 'failed');
      expect(remote.calls, ['link google']);
      expect(signedIn.user.id, 'anon-uuid', reason: 'the same user');
      expect(signedIn.user.signedIn, isTrue);
      expect(signedIn.user.provider, AuthProvider.google);
      expect(signedIn.user.email, 'a@b.c');
      expect(signedIn.name, 'Alex Rivers');
    });

    test('someone who is already signed in just signs in again', () async {
      final remote = _FakeRemote(
        saved: _user('account-uuid', anonymous: false, provider: 'apple'),
      );
      await _repo(remote).signIn(AuthProvider.apple);
      expect(remote.calls, ['signin apple']);
    });

    test('closing the sheet is a cancel, not an error', () async {
      final remote = _FakeRemote(saved: _user('anon-uuid'));
      final result = await _repo(
        remote,
        const CancelledException(),
      ).signIn(AuthProvider.apple);
      expect(result.fold((f) => f, (_) => null), isA<CancelledFailure>());
      expect(remote.calls, isEmpty);
    });

    test('an account Eala already has: signs in to it and MOVES this user\'s '
        'goals and alarms there', () async {
      final remote = _FakeRemote(saved: _user('anon-uuid'), taken: true);
      final pending = _FakePendingMerge();
      final result = await _repo(
        remote,
        null,
        pending,
      ).signIn(AuthProvider.google);

      final signedIn = result.getOrElse(() => throw 'failed');
      expect(remote.calls, [
        'link google',
        // The ticket is asked for while still the anonymous user...
        'start merge',
        'signin google',
        // ...and claimed by the account.
        'finish merge ticket-1',
      ]);
      expect(signedIn.user.id, 'account-uuid');
      expect(signedIn.joined, isTrue);
      expect(signedIn.mergePending, isFalse);
      expect(pending.ticket, isNull);
    });

    test(
      'offline after the switch, the move waits and finishes later',
      () async {
        final remote = _FakeRemote(saved: _user('anon-uuid'), taken: true)
          ..finishFails = true;
        final pending = _FakePendingMerge();
        final repo = _repo(remote, null, pending);

        final signedIn = (await repo.signIn(AuthProvider.apple))
            .getOrElse(() => throw 'failed');
        expect(signedIn.joined, isTrue);
        expect(signedIn.mergePending, isTrue);
        expect(pending.ticket, 'ticket-1', reason: 'kept for the next try');

        remote.finishFails = false;
        final later = await repo.finishPendingMerge();
        expect(later.getOrElse(() => false), isTrue);
        expect(remote.calls.last, 'finish merge ticket-1');
        expect(pending.ticket, isNull);
      },
    );

    test(
      'without a ticket there is no switch: still the anonymous user',
      () async {
        final remote = _FakeRemote(saved: _user('anon-uuid'), taken: true)
          ..startFails = true;
        final result = await _repo(remote).signIn(AuthProvider.google);
        expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
        expect(remote.calls, ['link google', 'start merge']);
        expect(remote.currentUser!.id, 'anon-uuid');
      },
    );

    test('a switch that fails leaves the anonymous user as it was', () async {
      final remote = _FakeRemote(saved: _user('anon-uuid'), taken: true)
        ..signInFails = true;
      final pending = _FakePendingMerge();
      final result = await _repo(
        remote,
        null,
        pending,
      ).signIn(AuthProvider.google);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
      expect(remote.currentUser!.id, 'anon-uuid');
      expect(pending.ticket, isNull, reason: 'nothing to move');
    });

    test('only the account finishes a move, and only one that waits', () async {
      final remote = _FakeRemote(saved: _user('anon-uuid'));
      final pending = _FakePendingMerge()..ticket = 'ticket-1';
      final repo = _repo(remote, null, pending);
      expect((await repo.finishPendingMerge()).getOrElse(() => true), isFalse);
      expect(pending.ticket, 'ticket-1', reason: 'anonymous: not yet');

      remote.saved = _user('account-uuid', anonymous: false, provider: 'apple');
      pending.ticket = null;
      expect((await repo.finishPendingMerge()).getOrElse(() => true), isFalse);
      expect(remote.calls, isEmpty);
    });

    test('a provider that fails is a ServerFailure', () async {
      final result = await _repo(
        _FakeRemote(saved: _user('anon-uuid')),
        const ServerException('no network'),
      ).signIn(AuthProvider.google);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });

  test('a link refused for an identity or an e-mail another account has is '
      '"account in use" (so the device joins it), anything else is not', () {
    expect(
      isAccountInUse(const AuthException('x', code: 'identity_already_exists')),
      isTrue,
    );
    expect(
      isAccountInUse(
        const AuthException(
          'A user with this email address has already been registered',
          code: 'email_exists',
        ),
      ),
      isTrue,
    );
    expect(
      isAccountInUse(const AuthException('Invalid token', code: 'bad_jwt')),
      isFalse,
    );
  });

  group('signing out', () {
    test('ends the session and starts a new anonymous one', () async {
      final remote = _FakeRemote(
        saved: _user('account-uuid', anonymous: false, provider: 'google'),
      );
      final result = await _repo(remote).signOut();
      expect(remote.calls, ['signout']);
      expect(remote.signIns, 1);
      final user = result.getOrElse(() => throw 'failed');
      expect(user.isAnonymous, isTrue);
      expect(user.provider, isNull);
    });

    test('offline it fails and says so', () async {
      final result = await _repo(
        _FakeRemote(saved: _user('account-uuid', anonymous: false), fail: true),
      ).signOut();
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });

  group('who is signed in', () {
    test('an anonymous user has no provider and is not signed in', () async {
      final user = (await _repo(
        _FakeRemote(saved: _user('a')),
      ).ensureSignedIn()).getOrElse(() => throw 'no user');
      expect(user.signedIn, isFalse);
      expect(user.provider, isNull);
    });

    test('Apple and Google are read from the identities', () async {
      for (final name in ['apple', 'google']) {
        final user = (await _repo(
          _FakeRemote(
            saved: _user('a', anonymous: false, provider: name, email: 'x@y.z'),
          ),
        ).ensureSignedIn()).getOrElse(() => throw 'no user');
        expect(user.provider, AuthProvider.fromValue(name));
        expect(user.email, 'x@y.z');
        expect(user.signedIn, isTrue);
      }
    });

    test('one account with Apple and Google is named by the one used last', () {
      UserIdentity identity(String provider, String lastSignInAt) =>
          UserIdentity(
            id: provider,
            userId: 'a',
            identityData: const {},
            identityId: provider,
            provider: provider,
            createdAt: '2026-11-01T00:00:00Z',
            lastSignInAt: lastSignInAt,
          );
      User both(String apple, String google) => User(
        id: 'a',
        appMetadata: const {'provider': 'apple'},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '2026-11-01T00:00:00Z',
        isAnonymous: false,
        identities: [
          identity('anonymous', '2026-11-01T00:00:00Z'),
          identity('apple', apple),
          identity('google', google),
        ],
      );

      expect(
        both(
          '2026-11-12T10:00:00Z',
          '2026-11-13T10:00:00Z',
        ).toEntity().provider,
        AuthProvider.google,
      );
      expect(
        both(
          '2026-11-13T11:00:00Z',
          '2026-11-13T10:00:00Z',
        ).toEntity().provider,
        AuthProvider.apple,
      );
      // The provider just signed in with wins over whatever the identities say.
      expect(
        both(
          '2026-11-13T11:00:00Z',
          '2026-11-13T10:00:00Z',
        ).toEntity(signedInWith: AuthProvider.google).provider,
        AuthProvider.google,
      );
    });

    test('signing in names the provider used, also when the account has '
        'another one', () async {
      final remote = _FakeRemote(saved: _user('anon-uuid'), taken: true);
      final signedIn = (await _repo(remote).signIn(AuthProvider.google))
          .getOrElse(() => throw 'failed');
      expect(signedIn.user.provider, AuthProvider.google);
    });

    test('any other provider is signed in, with none we name', () async {
      final user = (await _repo(
        _FakeRemote(saved: _user('a', anonymous: false, provider: 'email')),
      ).ensureSignedIn()).getOrElse(() => throw 'no user');
      expect(user.signedIn, isTrue);
      expect(user.provider, isNull);
    });

    test('the user is watched, now and when it changes', () async {
      final users = await _repo(_FakeRemote(saved: _user('a')))
          .watchUser()
          .toList();
      expect(users.single?.id, 'a');
    });
  });
}
