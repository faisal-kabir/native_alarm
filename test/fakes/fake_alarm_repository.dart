import 'package:dartz/dartz.dart';
import 'package:eala/features/create_alarm/domain/usecases/set_alarm_enabled_usecase.dart';
import 'package:eala/features/alarm/domain/repositories/alarm_scheduler.dart';
import 'package:eala/features/alarm/domain/usecases/alarm_access_usecases.dart';
import 'package:eala/features/alarm_audio/domain/usecases/watch_alarm_audio_usecase.dart';
import 'package:eala/features/create_alarm/domain/usecases/create_alarm_usecase.dart';
import 'package:eala/features/create_alarm/domain/repositories/remote_alarm_repository.dart';
import 'package:eala/features/create_alarm/domain/usecases/reschedule_alarms_usecase.dart';
import 'package:eala/features/create_alarm/domain/usecases/upload_pending_alarms_usecase.dart';
import 'package:eala/features/create_alarm/presentation/bloc/create_alarm_bloc.dart';
import 'package:eala/features/alarm_audio/domain/entities/alarm_audio.dart';
import 'package:eala/features/alarm_audio/domain/repositories/alarm_audio_repository.dart';
import 'package:eala/features/alarm_audio/domain/usecases/refresh_alarm_audio_usecase.dart';
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
import 'package:eala/features/area_of_life/domain/entities/matter_suggestion.dart';
import 'package:eala/features/area_of_life/domain/usecases/get_matter_suggestions_usecase.dart';
import 'package:eala/features/area_of_life/domain/entities/purpose_suggestion.dart';
import 'package:eala/features/area_of_life/domain/usecases/get_purpose_suggestions_usecase.dart';
import 'package:eala/features/sound/domain/entities/sound_quote.dart';
import 'package:eala/features/sound/domain/entities/sound_type.dart';
import 'package:eala/features/sound/domain/repositories/sound_repository.dart';
import 'package:eala/features/sound/domain/usecases/get_sound_quote_usecase.dart';
import 'package:eala/features/sound/domain/usecases/get_sound_types_usecase.dart';
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
import 'package:eala/features/reasons/domain/entities/new_reason.dart';
import 'package:eala/features/reasons/domain/entities/reason_draft.dart';
import 'package:eala/features/reasons/domain/entities/reason_name.dart';
import 'package:eala/features/reasons/domain/usecases/create_reason_usecase.dart';
import 'package:eala/features/reasons/domain/usecases/refresh_reasons_usecase.dart';
import 'package:eala/features/reason_detail/domain/usecases/delete_reason_with_alarm_usecase.dart';
import 'package:eala/features/alarm/domain/usecases/watch_alarms_usecase.dart';
import 'package:eala/features/reasons/domain/usecases/rename_reason_usecase.dart';
import 'package:eala/features/reasons/domain/usecases/update_reason_usecase.dart';
import 'package:eala/features/reasons/domain/usecases/watch_reason_usecase.dart';
import 'package:eala/features/reason_detail/presentation/bloc/reason_detail_bloc.dart';
import 'package:eala/features/reasons/domain/usecases/watch_reasons_usecase.dart';
import 'package:eala/features/create_reason/presentation/bloc/reason_ready_bloc.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_bloc.dart';

/// In-memory [AlarmRepository] so BLoC tests run without a database.
class FakeAlarmRepository implements AlarmRepository {
  final Map<String, Alarm> store = {};
  final _changes = StreamController<void>.broadcast();

  @override
  Future<Either<Failure, List<Alarm>>> getAlarms() async =>
      Right(store.values.toList());

  @override
  Stream<Either<Failure, List<Alarm>>> watchAlarms() async* {
    yield Right(store.values.toList());
    await for (final _ in _changes.stream) {
      yield Right(store.values.toList());
    }
  }

  @override
  Future<Either<Failure, Alarm>> saveAlarm(Alarm alarm) async {
    store[alarm.id] = alarm;
    _changes.add(null);
    return Right(alarm);
  }

  @override
  Future<Either<Failure, void>> deleteAlarm(String alarmId) async {
    store.remove(alarmId);
    _changes.add(null);
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

/// A reason for tests, with its area, tone and voice joined in.
Reason testReason({
  int id = 1,
  String name = 'Reason',
  String area = 'Area',
  int? areaColor,
  String tone = 'Tone',
  String purpose = 'Sleep well every night',
  String why = '',
  int voiceId = 1,
  String voice = 'Astra',
  int lengthSeconds = 30,
  int? alarmId,
}) => Reason(
  id: id,
  alarmId: alarmId,
  name: name,
  purpose: purpose,
  why: why,
  lengthSeconds: lengthSeconds,
  areaId: 1,
  area: AreaOfLife(
    id: 1,
    name: area.toLowerCase(),
    title: area,
    color: areaColor,
  ),
  soundTypeId: 1,
  sound: SoundType(id: 1, title: tone),
  voiceId: voiceId,
  voice: Voice(id: voiceId, name: voice, voiceId: 'v$voiceId'),
);

/// In-memory [ReasonRepository]: [reasons] is the device list (watched). A created or
/// updated reason is joined with [areas], [sounds] and [voices] by id (as the server
/// does); a created one gets the next id and its numbered name. [offline] makes the
/// writes fail. [created], [renames] and [updates] record the calls.
class FakeReasonRepository implements ReasonRepository {
  FakeReasonRepository([
    List<Reason> reasons = const [],
    this.areas = const [],
    this.sounds = const [],
    this.voices = const [],
  ]) : reasons = [...reasons];

  final List<Reason> reasons;
  final List<AreaOfLife> areas;
  final List<SoundType> sounds;
  final List<Voice> voices;
  final List<NewReason> created = [];
  final List<(int, String)> renames = [];
  final List<(int, ReasonDraft)> updates = [];
  final List<int> deletes = [];
  bool offline = false;
  int _nextId = 100;
  final StreamController<List<Reason>> _changes = StreamController.broadcast();

  /// What the server holds; a refresh copies it over [reasons] (null: no change).
  List<Reason>? server;
  int refreshes = 0;

  static T? _find<T>(List<T> list, bool Function(T) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }

  Reason _join(int id, String name, ReasonDraft d) => Reason(
    id: id,
    name: name,
    purpose: d.purpose,
    why: d.why,
    lengthSeconds: d.lengthSeconds,
    areaId: d.areaId,
    area: _find(areas, (a) => a.id == d.areaId),
    soundTypeId: d.soundTypeId,
    sound: _find(sounds, (s) => s.id == d.soundTypeId),
    voiceId: d.voiceId,
    voice: _find(voices, (v) => v.id == d.voiceId),
  );

  void _put(Reason reason) {
    final i = reasons.indexWhere((r) => r.id == reason.id);
    i < 0 ? reasons.add(reason) : reasons[i] = reason;
    _changes.add(List.of(reasons));
  }

  @override
  Stream<Either<Failure, List<Reason>>> watchReasons() async* {
    await Future<void>.delayed(Duration.zero);
    yield Right(List.of(reasons));
    yield* _changes.stream.map((list) => Right(list));
  }

  @override
  Stream<Either<Failure, Reason?>> watchReason(int id) async* {
    await Future<void>.delayed(Duration.zero);
    yield Right(_find(reasons, (r) => r.id == id));
    yield* _changes.stream.map((list) => Right(_find(list, (r) => r.id == id)));
  }

  @override
  Future<Either<Failure, Unit>> refreshReasons() async {
    refreshes++;
    if (offline) return const Left(ServerFailure('offline'));
    final list = server;
    if (list != null) {
      reasons
        ..clear()
        ..addAll(list);
      _changes.add(List.of(reasons));
    }
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Reason>> createReason(NewReason reason) async {
    if (offline) return const Left(ServerFailure('offline'));
    created.add(reason);
    final name = nextReasonName(reason.baseName, [
      for (final r in reasons) r.name,
    ]);
    final saved = _join(_nextId++, name, reason.draft);
    _put(saved);
    return Right(saved);
  }

  @override
  Future<Either<Failure, Reason>> renameReason(int id, String name) async {
    if (offline) return const Left(ServerFailure('offline'));
    renames.add((id, name));
    final r = _find(reasons, (r) => r.id == id)!;
    final saved = _join(id, name, r.draft);
    _put(saved);
    return Right(saved);
  }

  @override
  Future<Either<Failure, Unit>> deleteReason(int id) async {
    if (offline) return const Left(ServerFailure('offline'));
    deletes.add(id);
    reasons.removeWhere((r) => r.id == id);
    _changes.add(List.of(reasons));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Reason>> updateReason(
    int id,
    ReasonDraft draft,
  ) async {
    if (offline) return const Left(ServerFailure('offline'));
    updates.add((id, draft));
    final r = _find(reasons, (r) => r.id == id)!;
    final saved = _join(id, r.name, draft);
    _put(saved);
    return Right(saved);
  }
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
    this.matterSuggestions = const [],
    this.matterOffline = false,
  });

  /// All `matter_suggestion` rows; [getMatterSuggestions] filters them like the
  /// server (area, and purpose suggestion id or none). [matterOffline] fails it.
  List<MatterSuggestion> matterSuggestions;
  bool matterOffline;
  final List<(int, int?)> matterRequests = [];

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

  @override
  Future<Either<Failure, List<MatterSuggestion>>> getMatterSuggestions(
    int areaId,
    int? purposeSuggestionId,
  ) async {
    matterRequests.add((areaId, purposeSuggestionId));
    await Future<void>.delayed(Duration.zero);
    if (matterOffline) return const Left(ServerFailure('offline'));
    return Right([
      for (final s in matterSuggestions)
        if (s.areaId == areaId && s.purposeSuggestionId == purposeSuggestionId)
          s,
    ]);
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
  Future<void> playFile(String path) => play(path);

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

/// In-memory [SoundRepository]: [sounds] and [quotes]; [quoteAnswer] delays the
/// example line, [offline] fails both calls.
class FakeSoundRepository implements SoundRepository {
  FakeSoundRepository({
    this.sounds = const [],
    this.quotes = const [],
    this.quoteAnswer,
    this.offline = false,
  });

  List<SoundType> sounds;
  List<SoundQuote> quotes;
  Future<void>? quoteAnswer;
  bool offline;
  final List<(int, int)> quoteRequests = [];

  @override
  Future<Either<Failure, List<SoundType>>> getSoundTypes() async {
    await Future<void>.delayed(Duration.zero);
    if (offline) return const Left(ServerFailure('offline'));
    return Right(sounds);
  }

  @override
  Future<Either<Failure, SoundQuote?>> getSoundQuote(
    int areaId,
    int soundId,
  ) async {
    quoteRequests.add((areaId, soundId));
    await (quoteAnswer ?? Future<void>.delayed(Duration.zero));
    if (offline) return const Left(ServerFailure('offline'));
    for (final q in quotes) {
      if (q.areaId == areaId && q.soundId == soundId) return Right(q);
    }
    return const Right(null);
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
  VoiceRepository? voiceRepository,
  SoundRepository? soundRepository,
  AlarmAudioRepository? alarmAudioRepository,
  AlarmScheduler? alarmScheduler,
  FakeRemoteAlarmRepository? remoteAlarmRepository,
}) async {
  await instance.reset();
  final remote = remoteAlarmRepository ?? FakeRemoteAlarmRepository();
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
      RefreshAlarmAudioUseCase(FakeAlarmAudioRepository()),
      RescheduleAlarmsUseCase(
        repository,
        alarmScheduler ?? FakeAlarmScheduler(),
      ),
      UploadPendingAlarmsUseCase(repository, remote),
    ),
  );
  final reasons = reasonRepository ?? FakeReasonRepository();
  instance.registerFactory<MyAlarmsBloc>(
    () => MyAlarmsBloc(
      GetAlarmsUseCase(repository),
      WatchAlarmsUseCase(repository),
      WatchReasonsUseCase(reasons),
      SetAlarmEnabledUseCase(
        repository,
        alarmScheduler ?? FakeAlarmScheduler(),
      ),
    ),
  );
  instance.registerFactory<ReasonsBloc>(
    () => ReasonsBloc(
      WatchReasonsUseCase(reasons),
      RefreshReasonsUseCase(reasons),
    ),
  );
  instance.registerFactory<ReasonReadyBloc>(
    () => ReasonReadyBloc(RenameReasonUseCase(reasons)),
  );
  instance.registerFactoryParam<ReasonDetailBloc, Reason?, dynamic>((
    reason,
    _,
  ) {
    final areas = areaOfLifeRepository ?? FakeAreaOfLifeRepository();
    final voices = voiceRepository ?? FakeVoiceRepository();
    final sound = soundRepository ?? FakeSoundRepository();
    return ReasonDetailBloc(
      WatchReasonUseCase(reasons),
      UpdateReasonUseCase(reasons),
      RenameReasonUseCase(reasons),
      DeleteReasonWithAlarmUseCase(
        reasons,
        repository,
        remote,
        alarmScheduler ?? FakeAlarmScheduler(),
      ),
      WatchAlarmsUseCase(repository),
      WatchAreasOfLifeUseCase(areas),
      RefreshAreasOfLifeUseCase(areas),
      WatchVoicesUseCase(voices),
      RefreshVoicesUseCase(voices),
      GetSoundTypesUseCase(sound),
      GetPurposeSuggestionsUseCase(areas),
      GetMatterSuggestionsUseCase(areas),
      reason,
    );
  });
  instance.registerFactory<CreateReasonBloc>(() {
    final areas = areaOfLifeRepository ?? FakeAreaOfLifeRepository();
    final voices = voiceRepository ?? FakeVoiceRepository();
    final sound = soundRepository ?? FakeSoundRepository();
    return CreateReasonBloc(
      WatchAreasOfLifeUseCase(areas),
      RefreshAreasOfLifeUseCase(areas),
      WatchVoicesUseCase(voices),
      RefreshVoicesUseCase(voices),
      GetPurposeSuggestionsUseCase(areas),
      GetMatterSuggestionsUseCase(areas),
      GetSoundTypesUseCase(sound),
      GetSoundQuoteUseCase(sound),
      CreateReasonUseCase(reasons),
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
  instance.registerFactoryParam<CreateAlarmBloc, int?, dynamic>((reasonId, _) {
    final scheduler = alarmScheduler ?? FakeAlarmScheduler();
    return CreateAlarmBloc(
      WatchReasonsUseCase(reasons),
      WatchAlarmAudioUseCase(
        alarmAudioRepository ?? FakeAlarmAudioRepository(),
      ),
      GetAlarmsUseCase(repository),
      CreateAlarmUseCase(repository, remote, scheduler),
      HasAlarmAccessUseCase(scheduler),
      RequestAlarmAccessUseCase(scheduler),
      reasonId,
    );
  });
}

/// The server's alarms in tests: each upload gets the next id (from 1); [fail] makes
/// it fail as offline does.
class FakeRemoteAlarmRepository implements RemoteAlarmRepository {
  bool fail = false;
  final uploaded = <Alarm>[];
  final removed = <int>[];

  @override
  Future<Either<Failure, Alarm>> upload(
    Alarm alarm, {
    required DateTime now,
  }) async {
    if (fail) return const Left(ServerFailure('offline'));
    uploaded.add(alarm);
    return Right(alarm.copyWith(remoteId: uploaded.length));
  }

  @override
  Future<Either<Failure, Unit>> remove(int remoteId) async {
    if (fail) return const Left(ServerFailure('offline'));
    removed.add(remoteId);
    return const Right(unit);
  }
}

/// The device's alarm system in tests: records what was set to ring; [access] is the
/// permission, [fail] makes scheduling throw.
class FakeAlarmScheduler implements AlarmScheduler {
  FakeAlarmScheduler({this.access = true});

  bool access;
  bool fail = false;
  int requests = 0;
  final cancelled = <String>[];
  final scheduled = <(Alarm, String)>[];

  @override
  Future<bool> hasAccess() async => access;

  @override
  Future<void> requestAccess() async {
    requests++;
    access = true;
  }

  @override
  Future<void> schedule(Alarm alarm, {required String title}) async {
    if (fail) throw Exception('native refused');
    scheduled.add((alarm, title));
  }

  @override
  Future<void> cancel(String alarmId) async {
    if (fail) throw Exception('native refused');
    cancelled.add(alarmId);
  }
}

/// Alarm sounds and sound tracks that are never on a server: refreshes are counted.
class FakeAlarmAudioRepository implements AlarmAudioRepository {
  FakeAlarmAudioRepository([this.lists = const {}]);

  /// What the device has, per list.
  final Map<AlarmAudioKind, List<AlarmAudio>> lists;
  int refreshes = 0;

  @override
  Stream<Either<Failure, List<AlarmAudio>>> watchAudio(AlarmAudioKind kind) =>
      Stream.value(Right(lists[kind] ?? const []));

  @override
  Future<Either<Failure, Unit>> refreshAudio() async {
    refreshes++;
    return const Right(unit);
  }
}
