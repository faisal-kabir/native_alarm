import 'package:eala/core/error/exceptions.dart';
import 'package:eala/core/error/failures.dart';
import 'package:eala/features/auth/data/datasources/user_profile_local_data_source.dart';
import 'package:eala/features/auth/data/datasources/user_profile_remote_data_source.dart';
import 'package:eala/features/auth/data/models/user_profile_model.dart';
import 'package:eala/features/auth/data/repositories/user_profile_repository_impl.dart';
import 'package:eala/features/auth/domain/entities/device_info.dart';
import 'package:eala/features/auth/domain/entities/user_profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

final _profile = UserProfile(
  id: 7,
  authUserId: 'uuid-1',
  name: 'Alex',
  email: 'a@b.c',
  primaryProvider: 'anonymous',
  platform: 'ios',
  appVersion: '1.0.0',
  status: 'active',
  fcmToken: 'tok',
  createdAt: DateTime.utc(2026, 11, 5, 8),
  updatedAt: DateTime.utc(2026, 11, 5, 9),
);

class _FakeRemote implements UserProfileRemoteDataSource {
  _FakeRemote(this.authUserId, {this.row, this.fail = false});

  @override
  String? authUserId;
  UserProfile? row;
  final bool fail;
  final List<DeviceInfo> updates = [];

  @override
  Future<UserProfile> fetchProfile(String authUserId) async {
    if (fail) throw const ServerException('offline');
    return row!;
  }

  @override
  Future<UserProfile> updateDeviceInfo(
    String authUserId,
    DeviceInfo info,
  ) async {
    if (fail) throw const ServerException('offline');
    updates.add(info);
    return row = UserProfile(
      id: 7,
      authUserId: authUserId,
      platform: info.platform,
      appVersion: info.appVersion,
      fcmToken: info.fcmToken ?? row?.fcmToken,
    );
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  UserProfileLocalDataSourceImpl local() =>
      UserProfileLocalDataSourceImpl(const FlutterSecureStorage());

  test('the JSON form of a profile round-trips (Supabase row shape)', () {
    final back = userProfileFromJson(_profile.toJson());
    expect(back, _profile);
    // A bare row with only the required columns also parses.
    final bare = userProfileFromJson({'id': 3, 'auth_user_id': 'u'});
    expect(bare, const UserProfile(id: 3, authUserId: 'u'));
  });

  test('sync downloads the row and keeps it in secure storage', () async {
    final repo = UserProfileRepositoryImpl(
      _FakeRemote('uuid-1', row: _profile),
      local(),
    );

    final synced = await repo.syncProfile();
    expect(synced.getOrElse(() => throw 'no profile'), _profile);

    // A new repository (= app restart) still finds it, without the network.
    final afterRestart = UserProfileRepositoryImpl(
      _FakeRemote('uuid-1', fail: true),
      local(),
    );
    final cached = await afterRestart.getCachedProfile();
    expect(cached.getOrElse(() => null), _profile);
  });

  test('a failed download keeps the saved profile', () async {
    await local().write(_profile);
    final repo = UserProfileRepositoryImpl(
      _FakeRemote('uuid-1', fail: true),
      local(),
    );

    expect(
      (await repo.syncProfile()).fold((f) => f, (_) => null),
      isA<ServerFailure>(),
    );
    expect((await repo.getCachedProfile()).getOrElse(() => null), _profile);
  });

  test(
    'a profile of another user (reinstall) is dropped, never shown',
    () async {
      await local().write(_profile); // saved for uuid-1
      final repo = UserProfileRepositoryImpl(_FakeRemote('uuid-2'), local());

      expect((await repo.getCachedProfile()).getOrElse(() => _profile), isNull);
      expect(await local().read(), isNull);
    },
  );

  test('sync without a signed-in user fails cleanly', () async {
    final repo = UserProfileRepositoryImpl(_FakeRemote(null), local());
    expect((await repo.syncProfile()).isLeft(), isTrue);
  });

  group('device info (platform, app_version, fcm_token)', () {
    const info = DeviceInfo(
      platform: 'ios',
      appVersion: '1.0.0+1',
      fcmToken: 'token-1',
    );

    UserProfileRepositoryImpl repo(_FakeRemote remote) =>
        UserProfileRepositoryImpl(remote, local());

    test('the first time it is sent and the result is saved', () async {
      final remote = _FakeRemote('uuid-1', row: _profile);
      final result = await repo(remote).updateDeviceInfo(info);

      expect(remote.updates, [info]);
      final saved = await local().read();
      expect(saved?.platform, 'ios');
      expect(saved?.appVersion, '1.0.0+1');
      expect(saved?.fcmToken, 'token-1');
      expect(result.isRight(), isTrue);
    });

    test('nothing is sent when nothing changed', () async {
      final remote = _FakeRemote('uuid-1', row: _profile);
      final r = repo(remote);
      await r.updateDeviceInfo(info);
      await r.updateDeviceInfo(info);
      await r.updateDeviceInfo(info);
      expect(remote.updates.length, 1);
    });

    test('a new app version, a new token or a new platform is sent', () async {
      final remote = _FakeRemote('uuid-1', row: _profile);
      final r = repo(remote);
      await r.updateDeviceInfo(info);
      await r.updateDeviceInfo(
        const DeviceInfo(
          platform: 'ios',
          appVersion: '1.1.0+2',
          fcmToken: 'token-1',
        ),
      );
      await r.updateDeviceInfo(
        const DeviceInfo(
          platform: 'ios',
          appVersion: '1.1.0+2',
          fcmToken: 'token-2',
        ),
      );
      expect(remote.updates.length, 3);
      expect((await local().read())?.fcmToken, 'token-2');
    });

    test('with no token yet, the saved token is kept', () async {
      final remote = _FakeRemote('uuid-1', row: _profile);
      final r = repo(remote);
      await r.updateDeviceInfo(info);
      await r.updateDeviceInfo(
        const DeviceInfo(platform: 'ios', appVersion: '1.0.0+1'),
      );
      expect(remote.updates.length, 1);
      expect((await local().read())?.fcmToken, 'token-1');
    });

    test('a failed update changes nothing on the device', () async {
      await local().write(_profile);
      final r = repo(_FakeRemote('uuid-1', row: _profile, fail: true));
      final result = await r.updateDeviceInfo(info);
      expect(result.isLeft(), isTrue);
      expect(await local().read(), _profile);
    });
  });
}
