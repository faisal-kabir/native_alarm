import 'package:dartz/dartz.dart';
import 'package:eala/core/di/injection.dart';
import 'package:eala/core/firebase/analytics_service.dart';
import 'package:eala/features/auth/domain/entities/app_user.dart';
import 'package:eala/features/auth/domain/entities/device_info.dart';
import 'package:eala/features/auth/domain/entities/user_profile.dart';
import 'package:eala/features/auth/domain/repositories/auth_repository.dart';
import 'package:eala/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:eala/features/auth/domain/usecases/sync_user_profile_usecase.dart';
import 'package:eala/features/auth/domain/usecases/update_device_info_usecase.dart';
import 'package:eala/features/auth/domain/usecases/ensure_signed_in_usecase.dart';
import 'package:eala/core/error/failures.dart';
import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/features/alarm/domain/repositories/alarm_repository.dart';
import 'package:eala/features/alarm/domain/usecases/delete_alarm_usecase.dart';
import 'package:eala/features/alarm/domain/usecases/get_alarms_usecase.dart';
import 'package:eala/features/alarm/domain/usecases/save_alarm_usecase.dart';
import 'package:eala/core/platform/alarm_platform_client.dart';
import 'package:eala/features/alarm/presentation/bloc/alarm_list_bloc.dart';
import 'package:eala/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:eala/features/my_alarms/presentation/bloc/my_alarms_bloc.dart';
import 'package:eala/features/settings/domain/entities/app_info.dart';
import 'package:eala/features/settings/domain/entities/user_settings.dart';
import 'package:eala/features/settings/domain/repositories/settings_repository.dart';
import 'package:eala/features/settings/domain/usecases/get_app_info_usecase.dart';
import 'package:eala/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:eala/features/settings/domain/usecases/save_settings_usecase.dart';
import 'package:eala/features/settings/presentation/bloc/settings_bloc.dart';

import 'dart:async';

import 'package:eala/features/area_of_life/domain/entities/area_of_life.dart';
import 'package:eala/features/area_of_life/domain/repositories/area_of_life_repository.dart';
import 'package:eala/features/area_of_life/domain/usecases/refresh_areas_of_life_usecase.dart';
import 'package:eala/features/area_of_life/domain/usecases/watch_areas_of_life_usecase.dart';
import 'package:eala/features/create_reason/presentation/bloc/create_reason_bloc.dart';
import 'package:eala/features/reasons/domain/entities/reason.dart';
import 'package:eala/features/reasons/domain/repositories/reason_repository.dart';
import 'package:eala/features/reasons/domain/usecases/get_reasons_usecase.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_bloc.dart';

/// In-memory [AlarmRepository] so BLoC tests run without a database.
class FakeAlarmRepository implements AlarmRepository {
  final Map<String, Alarm> store = {};

  @override
  Future<Either<Failure, List<Alarm>>> getAlarms() async =>
      Right(store.values.toList());

  @override
  Future<Either<Failure, Alarm>> saveAlarm(Alarm alarm) async {
    store[alarm.id] = alarm;
    return Right(alarm);
  }

  @override
  Future<Either<Failure, void>> deleteAlarm(String alarmId) async {
    store.remove(alarmId);
    return const Right(null);
  }
}

AlarmListBloc buildAlarmListBloc(AlarmRepository repository) => AlarmListBloc(
  GetAlarmsUseCase(repository),
  SaveAlarmUseCase(repository),
  DeleteAlarmUseCase(repository),
);

/// Pretends to be signed in anonymously; counts how often a session was ensured.
class FakeAuthRepository implements AuthRepository {
  int calls = 0;

  @override
  Future<Either<Failure, AppUser>> ensureSignedIn() async {
    calls++;
    return const Right(AppUser(id: 'test-uuid', isAnonymous: true));
  }
}

/// Keeps the profile in memory; counts how often it was synced.
class FakeUserProfileRepository implements UserProfileRepository {
  int syncs = 0;
  UserProfile? cached;
  final List<DeviceInfo> deviceUpdates = [];

  @override
  Future<Either<Failure, UserProfile?>> getCachedProfile() async =>
      Right(cached);

  @override
  Future<Either<Failure, UserProfile>> syncProfile() async {
    syncs++;
    return Right(cached = const UserProfile(id: 1, authUserId: 'test-uuid'));
  }

  @override
  Future<Either<Failure, UserProfile>> updateDeviceInfo(DeviceInfo info) async {
    deviceUpdates.add(info);
    return Right(
      cached = UserProfile(
        id: 1,
        authUserId: 'test-uuid',
        platform: info.platform,
        appVersion: info.appVersion,
        fcmToken: info.fcmToken,
      ),
    );
  }
}

/// Records the screens logged instead of sending them to Firebase.
class FakeAnalyticsService implements AnalyticsService {
  final List<String> screens = [];

  @override
  Future<void> logScreen(String name) async => screens.add(name);
}

/// In-memory [ReasonRepository].
class FakeReasonRepository implements ReasonRepository {
  FakeReasonRepository([this.reasons = const []]);

  final List<Reason> reasons;

  @override
  Future<Either<Failure, List<Reason>>> getReasons() async => Right(reasons);
}

/// In-memory [AreaOfLifeRepository]. [saved] is what is "on the device"; a refresh
/// replaces it with [server] (or fails when [offline]) once [serverAnswer] completes,
/// so tests can look at the loading state first.
class FakeAreaOfLifeRepository implements AreaOfLifeRepository {
  FakeAreaOfLifeRepository({
    this.saved = const [],
    this.server = const [],
    this.offline = false,
    this.serverAnswer,
  });

  List<AreaOfLife> saved;
  List<AreaOfLife> server;
  bool offline;
  Future<void>? serverAnswer;
  int refreshCount = 0;

  final _changes = StreamController<List<AreaOfLife>>.broadcast();

  @override
  Stream<Either<Failure, List<AreaOfLife>>> watchAreas() async* {
    yield Right(saved);
    yield* _changes.stream.map(Right.new);
  }

  @override
  Future<Either<Failure, Unit>> refreshAreas() async {
    refreshCount++;
    await serverAnswer;
    if (offline) return const Left(ServerFailure('offline'));
    saved = server;
    _changes.add(saved);
    return const Right(unit);
  }
}

/// In-memory [SettingsRepository]; [saved] records what was stored last.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.settings = const UserSettings()]);

  UserSettings settings;
  UserSettings? saved;

  @override
  Future<Either<Failure, UserSettings>> getSettings() async => Right(settings);

  @override
  Future<Either<Failure, void>> saveSettings(UserSettings value) async {
    saved = value;
    settings = value;
    return const Right(null);
  }

  @override
  Future<Either<Failure, AppInfo>> getAppInfo() async =>
      const Right(AppInfo(name: 'Eala', version: '1.0.0', build: '1'));
}

SettingsBloc buildSettingsBloc(SettingsRepository repository) => SettingsBloc(
  GetSettingsUseCase(repository),
  SaveSettingsUseCase(repository),
  GetAppInfoUseCase(repository),
);

/// Registers the BLoCs the app's screens need, backed by [repository] (and
/// [reasonRepository], empty by default).
Future<void> registerFakeAlarmDependencies(
  AlarmRepository repository, {
  ReasonRepository? reasonRepository,
  SettingsRepository? settingsRepository,
  AreaOfLifeRepository? areaOfLifeRepository,
}) async {
  await instance.reset();
  instance.registerFactory<AlarmListBloc>(() => buildAlarmListBloc(repository));
  instance.registerLazySingleton<AnalyticsService>(FakeAnalyticsService.new);
  instance.registerLazySingleton<AuthRepository>(FakeAuthRepository.new);
  instance.registerLazySingleton<UserProfileRepository>(
    FakeUserProfileRepository.new,
  );
  instance.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      instance<AnalyticsService>(),
      EnsureSignedInUseCase(instance<AuthRepository>()),
      SyncUserProfileUseCase(instance<UserProfileRepository>()),
      UpdateDeviceInfoUseCase(instance<UserProfileRepository>()),
      GetAppInfoUseCase(FakeSettingsRepository()),
    ),
  );
  instance.registerFactory<MyAlarmsBloc>(
    () => MyAlarmsBloc(GetAlarmsUseCase(repository)),
  );
  instance.registerFactory<ReasonsBloc>(
    () => ReasonsBloc(
      GetReasonsUseCase(reasonRepository ?? FakeReasonRepository()),
    ),
  );
  instance.registerFactory<CreateReasonBloc>(() {
    final areas = areaOfLifeRepository ?? FakeAreaOfLifeRepository();
    return CreateReasonBloc(
      WatchAreasOfLifeUseCase(areas),
      RefreshAreasOfLifeUseCase(areas),
    );
  });
  instance.registerFactory<SettingsBloc>(
    () => buildSettingsBloc(settingsRepository ?? FakeSettingsRepository()),
  );
  instance.registerLazySingleton<AlarmPlatformClient>(AlarmPlatformClient.new);
}
