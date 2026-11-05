import 'package:eala/core/error/exceptions.dart';
import 'package:eala/core/notification/fcm_token.dart';
import 'package:eala/core/error/failures.dart';
import 'package:eala/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:eala/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:eala/features/auth/domain/entities/app_user.dart';
import 'package:eala/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:eala/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:eala/features/auth/domain/usecases/ensure_signed_in_usecase.dart';
import 'package:eala/features/auth/domain/usecases/sync_user_profile_usecase.dart';
import 'package:eala/features/auth/domain/usecases/update_device_info_usecase.dart';
import 'package:eala/features/settings/domain/usecases/get_app_info_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes/fake_alarm_repository.dart';

User _user(String id, {bool anonymous = true}) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-11-05T00:00:00Z',
  isAnonymous: anonymous,
);

class _FakeRemote implements AuthRemoteDataSource {
  _FakeRemote({this.saved, this.fail = false});

  User? saved;
  final bool fail;
  int signIns = 0;

  @override
  User? get currentUser => saved;

  @override
  Future<User> signInAnonymously() async {
    signIns++;
    if (fail) throw const ServerException('offline');
    return saved = _user('new-uuid');
  }
}

void main() {
  test('a saved session is reused; no new anonymous user is created', () async {
    final remote = _FakeRemote(saved: _user('saved-uuid', anonymous: false));
    final result = await AuthRepositoryImpl(remote).ensureSignedIn();

    expect(
      result.getOrElse(() => throw 'no user'),
      const AppUser(id: 'saved-uuid', isAnonymous: false),
    );
    expect(remote.signIns, 0);
  });

  test('without a session an anonymous user is created once', () async {
    final remote = _FakeRemote();
    final repo = AuthRepositoryImpl(remote);

    final first = await repo.ensureSignedIn();
    final second = await repo.ensureSignedIn();

    expect(first.getOrElse(() => throw 'no user').id, 'new-uuid');
    expect(first.getOrElse(() => throw 'no user').isAnonymous, isTrue);
    expect(second.getOrElse(() => throw 'no user').id, 'new-uuid');
    expect(remote.signIns, 1);
  });

  test('offline sign-in becomes a ServerFailure instead of a crash', () async {
    final result = await AuthRepositoryImpl(_FakeRemote(fail: true))
        .ensureSignedIn();
    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });

  test('the Dashboard ensures a session when asked', () async {
    final auth = FakeAuthRepository();
    final profiles = FakeUserProfileRepository();
    final bloc = DashboardBloc(
      FakeAnalyticsService(),
      EnsureSignedInUseCase(auth),
      SyncUserProfileUseCase(profiles),
      UpdateDeviceInfoUseCase(profiles),
      GetAppInfoUseCase(FakeSettingsRepository()),
    )..add(const EnsureSessionEvent());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(auth.calls, 1);
    // Once signed in, the user's row is saved on the device.
    expect(profiles.syncs, 1);
    await bloc.close();
  });

  test('a refreshed FCM token is passed on to the server', () async {
    final auth = FakeAuthRepository();
    final profiles = FakeUserProfileRepository();
    final bloc = DashboardBloc(
      FakeAnalyticsService(),
      EnsureSignedInUseCase(auth),
      SyncUserProfileUseCase(profiles),
      UpdateDeviceInfoUseCase(profiles),
      GetAppInfoUseCase(FakeSettingsRepository()),
    );

    setFcmToken('fresh-token');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(profiles.deviceUpdates.last.fcmToken, 'fresh-token');
    expect(profiles.deviceUpdates.last.appVersion, '1.0.0+1');
    await bloc.close();
    setFcmToken(null);
  });
}
