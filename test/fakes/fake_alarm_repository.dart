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

import 'package:eala/core/audio/sample_player.dart';
import 'package:eala/core/speech/dictation_controller.dart';

import 'package:eala/features/area_of_life/domain/entities/area_of_life.dart';
import 'package:eala/features/area_of_life/domain/entities/purpose_suggestion.dart';
import 'package:eala/features/area_of_life/domain/usecases/get_purpose_suggestions_usecase.dart';
import 'package:eala/features/voice/domain/entities/voice.dart';
import 'package:eala/features/voice/domain/repositories/voice_repository.dart';
import 'package:eala/features/voice/domain/usecases/refresh_voices_usecase.dart';
import 'package:eala/features/voice/domain/usecases/watch_voices_usecase.dart';
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
    this.areaSuggestions = const {},
    this.suggestionsAnswer,
    this.suggestionsOffline = false,
  });

  /// Suggestions by area id; [suggestionsAnswer] delays them, [suggestionsOffline] makes them fail.
  Map<int, List<PurposeSuggestion>> areaSuggestions;
  Future<void>? suggestionsAnswer;
  bool suggestionsOffline;
  final List<int> suggestionRequests = [];

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

  @override
  Future<Either<Failure, List<PurposeSuggestion>>> getPurposeSuggestions(
    int areaId,
  ) async {
    suggestionRequests.add(areaId);
    await suggestionsAnswer;
    if (suggestionsOffline) return const Left(ServerFailure('offline'));
    return Right(areaSuggestions[areaId] ?? const []);
  }
}

/// In-memory [VoiceRepository], same idea as [FakeAreaOfLifeRepository].
class FakeVoiceRepository implements VoiceRepository {
  FakeVoiceRepository({
    this.saved = const [],
    this.server = const [],
    this.offline = false,
  });

  List<Voice> saved;
  List<Voice> server;
  bool offline;

  final _changes = StreamController<List<Voice>>.broadcast();

  @override
  Stream<Either<Failure, List<Voice>>> watchVoices() async* {
    yield Right(saved);
    yield* _changes.stream.map(Right.new);
  }

  @override
  Future<Either<Failure, Unit>> refreshVoices() async {
    // Like a real request, answer on a later turn (the watcher subscribes first).
    await Future<void>.delayed(Duration.zero);
    if (offline) return const Left(ServerFailure('offline'));
    saved = server;
    _changes.add(saved);
    return const Right(unit);
  }
}

/// A microphone for tests: [start] begins listening at once (or fails when
/// [available] is false); [speak] plays words in, [commit] / [cancel] end the take.
class FakeDictation extends DictationController {
  bool available = true;

  @override
  Future<bool> start() async {
    if (!available) return false;
    begin();
    return true;
  }

  void speak(List<String> said, [String saying = '']) {
    setWords(said, saying);
    setLevel(0.7);
  }

  @override
  void commit() => finish(keep: true);

  @override
  void cancel() => finish(keep: false);
}

/// A sample player for tests: records what was played; [fail] makes playing throw;
/// [finish] ends the current sample.
class FakeSamplePlayer implements SamplePlayer {
  final played = <String>[];
  int stops = 0;
  bool fail = false;
  bool disposed = false;
  final _done = StreamController<void>.broadcast();

  @override
  Stream<void> get onComplete => _done.stream;

  @override
  Future<void> play(String url) async {
    if (fail) throw Exception('cannot play');
    played.add(url);
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async => disposed = true;

  void finish() => _done.add(null);
}

/// The [FakeSamplePlayer] the last screen asked for.
FakeSamplePlayer? lastFakeSamplePlayer;

/// The [FakeDictation] the last screen asked for.
FakeDictation? lastFakeDictation;

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
  VoiceRepository? voiceRepository,
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
    final voices = voiceRepository ?? FakeVoiceRepository();
    return CreateReasonBloc(
      WatchAreasOfLifeUseCase(areas),
      RefreshAreasOfLifeUseCase(areas),
      WatchVoicesUseCase(voices),
      RefreshVoicesUseCase(voices),
      GetPurposeSuggestionsUseCase(areas),
    );
  });
  instance.registerFactory<SamplePlayer>(
    () => lastFakeSamplePlayer = FakeSamplePlayer(),
  );
  instance.registerFactory<DictationController>(
    () => lastFakeDictation = FakeDictation(),
  );
  instance.registerFactory<SettingsBloc>(
    () => buildSettingsBloc(settingsRepository ?? FakeSettingsRepository()),
  );
  instance.registerLazySingleton<AlarmPlatformClient>(AlarmPlatformClient.new);
}
