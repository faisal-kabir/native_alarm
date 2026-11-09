// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:eala/core/audio/sample_player.dart' as _i327;
import 'package:eala/core/database/app_database.dart' as _i81;
import 'package:eala/core/database/database_module.dart' as _i26;
import 'package:eala/core/firebase/analytics_service.dart' as _i36;
import 'package:eala/core/firebase/firebase_module.dart' as _i101;
import 'package:eala/core/notification/local_notification_presenter.dart'
    as _i153;
import 'package:eala/core/notification/notification_service.dart' as _i118;
import 'package:eala/core/platform/alarm_platform_client.dart' as _i156;
import 'package:eala/core/speech/dictation_controller.dart' as _i84;
import 'package:eala/core/speech/speech_module.dart' as _i942;
import 'package:eala/core/speech/speech_recognizer.dart' as _i965;
import 'package:eala/core/storage/storage_module.dart' as _i964;
import 'package:eala/core/supabase/own_user_id.dart' as _i712;
import 'package:eala/core/supabase/supabase_module.dart' as _i543;
import 'package:eala/features/alarm/data/datasources/alarm_local_data_source.dart'
    as _i276;
import 'package:eala/features/alarm/data/platform_alarm_scheduler.dart'
    as _i222;
import 'package:eala/features/alarm/data/repositories/alarm_repository_impl.dart'
    as _i695;
import 'package:eala/features/alarm/domain/repositories/alarm_repository.dart'
    as _i1032;
import 'package:eala/features/alarm/domain/repositories/alarm_scheduler.dart'
    as _i173;
import 'package:eala/features/alarm/domain/usecases/alarm_access_usecases.dart'
    as _i278;
import 'package:eala/features/alarm/domain/usecases/delete_alarm_usecase.dart'
    as _i962;
import 'package:eala/features/alarm/domain/usecases/get_alarms_usecase.dart'
    as _i586;
import 'package:eala/features/alarm/domain/usecases/save_alarm_usecase.dart'
    as _i357;
import 'package:eala/features/alarm/domain/usecases/watch_alarms_usecase.dart'
    as _i258;
import 'package:eala/features/alarm/presentation/bloc/alarm_list_bloc.dart'
    as _i646;
import 'package:eala/features/alarm_audio/data/datasources/alarm_audio_file_store.dart'
    as _i899;
import 'package:eala/features/alarm_audio/data/datasources/alarm_audio_local_data_source.dart'
    as _i51;
import 'package:eala/features/alarm_audio/data/datasources/alarm_audio_remote_data_source.dart'
    as _i466;
import 'package:eala/features/alarm_audio/data/repositories/alarm_audio_repository_impl.dart'
    as _i198;
import 'package:eala/features/alarm_audio/domain/repositories/alarm_audio_repository.dart'
    as _i1012;
import 'package:eala/features/alarm_audio/domain/usecases/refresh_alarm_audio_usecase.dart'
    as _i619;
import 'package:eala/features/alarm_audio/domain/usecases/watch_alarm_audio_usecase.dart'
    as _i393;
import 'package:eala/features/area_of_life/data/datasources/area_of_life_local_data_source.dart'
    as _i504;
import 'package:eala/features/area_of_life/data/datasources/area_of_life_remote_data_source.dart'
    as _i760;
import 'package:eala/features/area_of_life/data/repositories/area_of_life_repository_impl.dart'
    as _i925;
import 'package:eala/features/area_of_life/domain/repositories/area_of_life_repository.dart'
    as _i650;
import 'package:eala/features/area_of_life/domain/usecases/get_matter_suggestions_usecase.dart'
    as _i478;
import 'package:eala/features/area_of_life/domain/usecases/get_purpose_suggestions_usecase.dart'
    as _i879;
import 'package:eala/features/area_of_life/domain/usecases/refresh_areas_of_life_usecase.dart'
    as _i190;
import 'package:eala/features/area_of_life/domain/usecases/watch_areas_of_life_usecase.dart'
    as _i375;
import 'package:eala/features/auth/data/datasources/auth_remote_data_source.dart'
    as _i570;
import 'package:eala/features/auth/data/datasources/user_profile_local_data_source.dart'
    as _i125;
import 'package:eala/features/auth/data/datasources/user_profile_remote_data_source.dart'
    as _i693;
import 'package:eala/features/auth/data/repositories/auth_repository_impl.dart'
    as _i9;
import 'package:eala/features/auth/data/repositories/user_profile_repository_impl.dart'
    as _i172;
import 'package:eala/features/auth/domain/repositories/auth_repository.dart'
    as _i653;
import 'package:eala/features/auth/domain/repositories/user_profile_repository.dart'
    as _i512;
import 'package:eala/features/auth/domain/usecases/ensure_signed_in_usecase.dart'
    as _i131;
import 'package:eala/features/auth/domain/usecases/get_cached_user_profile_usecase.dart'
    as _i25;
import 'package:eala/features/auth/domain/usecases/sync_user_profile_usecase.dart'
    as _i157;
import 'package:eala/features/auth/domain/usecases/update_device_info_usecase.dart'
    as _i798;
import 'package:eala/features/create_alarm/data/datasources/alarm_remote_data_source.dart'
    as _i181;
import 'package:eala/features/create_alarm/data/repositories/remote_alarm_repository_impl.dart'
    as _i430;
import 'package:eala/features/create_alarm/domain/repositories/remote_alarm_repository.dart'
    as _i452;
import 'package:eala/features/create_alarm/domain/usecases/create_alarm_usecase.dart'
    as _i73;
import 'package:eala/features/create_alarm/domain/usecases/remove_alarm_usecase.dart'
    as _i8;
import 'package:eala/features/create_alarm/domain/usecases/reschedule_alarms_usecase.dart'
    as _i218;
import 'package:eala/features/create_alarm/domain/usecases/set_alarm_enabled_usecase.dart'
    as _i97;
import 'package:eala/features/create_alarm/domain/usecases/upload_pending_alarms_usecase.dart'
    as _i40;
import 'package:eala/features/create_alarm/presentation/bloc/create_alarm_bloc.dart'
    as _i494;
import 'package:eala/features/create_reason/presentation/bloc/create_reason_bloc.dart'
    as _i946;
import 'package:eala/features/create_reason/presentation/bloc/reason_ready_bloc.dart'
    as _i64;
import 'package:eala/features/dashboard/presentation/bloc/dashboard_bloc.dart'
    as _i875;
import 'package:eala/features/my_alarms/presentation/bloc/my_alarms_bloc.dart'
    as _i1005;
import 'package:eala/features/reason_detail/domain/usecases/delete_reason_with_alarm_usecase.dart'
    as _i874;
import 'package:eala/features/reason_detail/presentation/bloc/reason_detail_bloc.dart'
    as _i252;
import 'package:eala/features/reasons/data/datasources/reason_local_data_source.dart'
    as _i429;
import 'package:eala/features/reasons/data/datasources/reason_remote_data_source.dart'
    as _i981;
import 'package:eala/features/reasons/data/repositories/reason_repository_impl.dart'
    as _i534;
import 'package:eala/features/reasons/domain/entities/reason.dart' as _i219;
import 'package:eala/features/reasons/domain/repositories/reason_repository.dart'
    as _i23;
import 'package:eala/features/reasons/domain/usecases/create_reason_usecase.dart'
    as _i1004;
import 'package:eala/features/reasons/domain/usecases/refresh_reasons_usecase.dart'
    as _i4;
import 'package:eala/features/reasons/domain/usecases/rename_reason_usecase.dart'
    as _i836;
import 'package:eala/features/reasons/domain/usecases/update_reason_usecase.dart'
    as _i39;
import 'package:eala/features/reasons/domain/usecases/watch_reason_usecase.dart'
    as _i151;
import 'package:eala/features/reasons/domain/usecases/watch_reasons_usecase.dart'
    as _i305;
import 'package:eala/features/reasons/presentation/bloc/reasons_bloc.dart'
    as _i743;
import 'package:eala/features/settings/data/datasources/app_info_data_source.dart'
    as _i360;
import 'package:eala/features/settings/data/datasources/settings_local_data_source.dart'
    as _i209;
import 'package:eala/features/settings/data/repositories/settings_repository_impl.dart'
    as _i807;
import 'package:eala/features/settings/domain/repositories/settings_repository.dart'
    as _i582;
import 'package:eala/features/settings/domain/usecases/get_app_info_usecase.dart'
    as _i49;
import 'package:eala/features/settings/domain/usecases/get_settings_usecase.dart'
    as _i57;
import 'package:eala/features/settings/domain/usecases/save_settings_usecase.dart'
    as _i936;
import 'package:eala/features/settings/presentation/bloc/settings_bloc.dart'
    as _i678;
import 'package:eala/features/sound/data/datasources/sound_remote_data_source.dart'
    as _i546;
import 'package:eala/features/sound/data/repositories/sound_repository_impl.dart'
    as _i727;
import 'package:eala/features/sound/domain/repositories/sound_repository.dart'
    as _i1064;
import 'package:eala/features/sound/domain/usecases/get_sound_quote_usecase.dart'
    as _i262;
import 'package:eala/features/sound/domain/usecases/get_sound_types_usecase.dart'
    as _i902;
import 'package:eala/features/voice/data/datasources/voice_local_data_source.dart'
    as _i580;
import 'package:eala/features/voice/data/datasources/voice_remote_data_source.dart'
    as _i22;
import 'package:eala/features/voice/data/repositories/voice_repository_impl.dart'
    as _i63;
import 'package:eala/features/voice/domain/repositories/voice_repository.dart'
    as _i334;
import 'package:eala/features/voice/domain/usecases/refresh_voices_usecase.dart'
    as _i414;
import 'package:eala/features/voice/domain/usecases/watch_voices_usecase.dart'
    as _i904;
import 'package:firebase_analytics/firebase_analytics.dart' as _i398;
import 'package:firebase_crashlytics/firebase_crashlytics.dart' as _i141;
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i163;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:speech_to_text/speech_to_text.dart' as _i941;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    final firebaseModule = _$FirebaseModule();
    final speechModule = _$SpeechModule();
    final storageModule = _$StorageModule();
    final supabaseModule = _$SupabaseModule();
    gh.lazySingleton<_i81.AppDatabase>(() => databaseModule.database);
    gh.lazySingleton<_i892.FirebaseMessaging>(() => firebaseModule.messaging);
    gh.lazySingleton<_i398.FirebaseAnalytics>(() => firebaseModule.analytics);
    gh.lazySingleton<_i141.FirebaseCrashlytics>(
      () => firebaseModule.crashlytics,
    );
    gh.lazySingleton<_i163.FlutterLocalNotificationsPlugin>(
      () => firebaseModule.localNotifications,
    );
    gh.lazySingleton<_i156.AlarmPlatformClient>(
      () => _i156.AlarmPlatformClient(),
    );
    gh.lazySingleton<_i941.SpeechToText>(() => speechModule.speechToText);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => storageModule.secureStorage,
    );
    gh.lazySingleton<_i454.SupabaseClient>(() => supabaseModule.supabase);
    gh.lazySingleton<_i360.AppInfoDataSource>(
      () => _i360.AppInfoDataSourceImpl(),
    );
    gh.lazySingleton<_i899.AlarmAudioFileStore>(
      () => _i899.AlarmAudioFileStoreImpl(),
    );
    gh.lazySingleton<_i125.UserProfileLocalDataSource>(
      () => _i125.UserProfileLocalDataSourceImpl(
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.factory<_i327.SamplePlayer>(() => _i327.CachedSamplePlayer());
    gh.lazySingleton<_i965.SpeechRecognizer>(
      () => _i965.SpeechRecognizer(gh<_i941.SpeechToText>()),
    );
    gh.lazySingleton<_i504.AreaOfLifeLocalDataSource>(
      () => _i504.AreaOfLifeLocalDataSourceImpl(gh<_i81.AppDatabase>()),
    );
    gh.lazySingleton<_i153.LocalNotificationPresenter>(
      () => _i153.LocalNotificationPresenter(
        gh<_i163.FlutterLocalNotificationsPlugin>(),
      ),
    );
    gh.lazySingleton<_i570.AuthRemoteDataSource>(
      () => _i570.AuthRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i51.AlarmAudioLocalDataSource>(
      () => _i51.AlarmAudioLocalDataSourceImpl(gh<_i81.AppDatabase>()),
    );
    gh.lazySingleton<_i546.SoundRemoteDataSource>(
      () => _i546.SoundRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i22.VoiceRemoteDataSource>(
      () => _i22.VoiceRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i209.SettingsLocalDataSource>(
      () => _i209.SettingsLocalDataSourceImpl(gh<_i81.AppDatabase>()),
    );
    gh.lazySingleton<_i36.AnalyticsService>(
      () => _i36.FirebaseAnalyticsService(gh<_i398.FirebaseAnalytics>()),
    );
    gh.lazySingleton<_i580.VoiceLocalDataSource>(
      () => _i580.VoiceLocalDataSourceImpl(gh<_i81.AppDatabase>()),
    );
    gh.lazySingleton<_i693.UserProfileRemoteDataSource>(
      () => _i693.UserProfileRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i276.AlarmLocalDataSource>(
      () => _i276.AlarmLocalDataSourceImpl(gh<_i81.AppDatabase>()),
    );
    gh.lazySingleton<_i429.ReasonLocalDataSource>(
      () => _i429.ReasonLocalDataSourceImpl(gh<_i81.AppDatabase>()),
    );
    gh.lazySingleton<_i466.AlarmAudioRemoteDataSource>(
      () => _i466.AlarmAudioRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i653.AuthRepository>(
      () => _i9.AuthRepositoryImpl(gh<_i570.AuthRemoteDataSource>()),
    );
    gh.lazySingleton<_i760.AreaOfLifeRemoteDataSource>(
      () => _i760.AreaOfLifeRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i712.OwnUserId>(
      () => _i712.OwnUserId(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i118.NotificationService>(
      () => _i118.NotificationService(
        gh<_i892.FirebaseMessaging>(),
        gh<_i153.LocalNotificationPresenter>(),
      ),
    );
    gh.lazySingleton<_i181.AlarmRemoteDataSource>(
      () => _i181.AlarmRemoteDataSourceImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i712.OwnUserId>(),
      ),
    );
    gh.factory<_i84.DictationController>(
      () => _i84.SpeechDictationController(gh<_i965.SpeechRecognizer>()),
    );
    gh.lazySingleton<_i981.ReasonRemoteDataSource>(
      () => _i981.ReasonRemoteDataSourceImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i712.OwnUserId>(),
      ),
    );
    gh.lazySingleton<_i1064.SoundRepository>(
      () => _i727.SoundRepositoryImpl(gh<_i546.SoundRemoteDataSource>()),
    );
    gh.lazySingleton<_i582.SettingsRepository>(
      () => _i807.SettingsRepositoryImpl(
        gh<_i209.SettingsLocalDataSource>(),
        gh<_i360.AppInfoDataSource>(),
      ),
    );
    gh.lazySingleton<_i49.GetAppInfoUseCase>(
      () => _i49.GetAppInfoUseCase(gh<_i582.SettingsRepository>()),
    );
    gh.lazySingleton<_i57.GetSettingsUseCase>(
      () => _i57.GetSettingsUseCase(gh<_i582.SettingsRepository>()),
    );
    gh.lazySingleton<_i936.SaveSettingsUseCase>(
      () => _i936.SaveSettingsUseCase(gh<_i582.SettingsRepository>()),
    );
    gh.factory<_i678.SettingsBloc>(
      () => _i678.SettingsBloc(
        gh<_i57.GetSettingsUseCase>(),
        gh<_i936.SaveSettingsUseCase>(),
        gh<_i49.GetAppInfoUseCase>(),
      ),
    );
    gh.lazySingleton<_i1032.AlarmRepository>(
      () => _i695.AlarmRepositoryImpl(gh<_i276.AlarmLocalDataSource>()),
    );
    gh.lazySingleton<_i512.UserProfileRepository>(
      () => _i172.UserProfileRepositoryImpl(
        gh<_i693.UserProfileRemoteDataSource>(),
        gh<_i125.UserProfileLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i262.GetSoundQuoteUseCase>(
      () => _i262.GetSoundQuoteUseCase(gh<_i1064.SoundRepository>()),
    );
    gh.lazySingleton<_i902.GetSoundTypesUseCase>(
      () => _i902.GetSoundTypesUseCase(gh<_i1064.SoundRepository>()),
    );
    gh.lazySingleton<_i131.EnsureSignedInUseCase>(
      () => _i131.EnsureSignedInUseCase(gh<_i653.AuthRepository>()),
    );
    gh.lazySingleton<_i23.ReasonRepository>(
      () => _i534.ReasonRepositoryImpl(
        gh<_i981.ReasonRemoteDataSource>(),
        gh<_i429.ReasonLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i334.VoiceRepository>(
      () => _i63.VoiceRepositoryImpl(
        gh<_i22.VoiceRemoteDataSource>(),
        gh<_i580.VoiceLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i650.AreaOfLifeRepository>(
      () => _i925.AreaOfLifeRepositoryImpl(
        gh<_i760.AreaOfLifeRemoteDataSource>(),
        gh<_i504.AreaOfLifeLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i1004.CreateReasonUseCase>(
      () => _i1004.CreateReasonUseCase(gh<_i23.ReasonRepository>()),
    );
    gh.lazySingleton<_i4.RefreshReasonsUseCase>(
      () => _i4.RefreshReasonsUseCase(gh<_i23.ReasonRepository>()),
    );
    gh.lazySingleton<_i836.RenameReasonUseCase>(
      () => _i836.RenameReasonUseCase(gh<_i23.ReasonRepository>()),
    );
    gh.lazySingleton<_i39.UpdateReasonUseCase>(
      () => _i39.UpdateReasonUseCase(gh<_i23.ReasonRepository>()),
    );
    gh.lazySingleton<_i151.WatchReasonUseCase>(
      () => _i151.WatchReasonUseCase(gh<_i23.ReasonRepository>()),
    );
    gh.lazySingleton<_i305.WatchReasonsUseCase>(
      () => _i305.WatchReasonsUseCase(gh<_i23.ReasonRepository>()),
    );
    gh.lazySingleton<_i452.RemoteAlarmRepository>(
      () => _i430.RemoteAlarmRepositoryImpl(
        gh<_i181.AlarmRemoteDataSource>(),
        gh<_i429.ReasonLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i1012.AlarmAudioRepository>(
      () => _i198.AlarmAudioRepositoryImpl(
        gh<_i466.AlarmAudioRemoteDataSource>(),
        gh<_i51.AlarmAudioLocalDataSource>(),
        gh<_i899.AlarmAudioFileStore>(),
      ),
    );
    gh.factory<_i743.ReasonsBloc>(
      () => _i743.ReasonsBloc(
        gh<_i305.WatchReasonsUseCase>(),
        gh<_i4.RefreshReasonsUseCase>(),
      ),
    );
    gh.lazySingleton<_i962.DeleteAlarmUseCase>(
      () => _i962.DeleteAlarmUseCase(gh<_i1032.AlarmRepository>()),
    );
    gh.lazySingleton<_i586.GetAlarmsUseCase>(
      () => _i586.GetAlarmsUseCase(gh<_i1032.AlarmRepository>()),
    );
    gh.lazySingleton<_i357.SaveAlarmUseCase>(
      () => _i357.SaveAlarmUseCase(gh<_i1032.AlarmRepository>()),
    );
    gh.lazySingleton<_i258.WatchAlarmsUseCase>(
      () => _i258.WatchAlarmsUseCase(gh<_i1032.AlarmRepository>()),
    );
    gh.lazySingleton<_i25.GetCachedUserProfileUseCase>(
      () => _i25.GetCachedUserProfileUseCase(gh<_i512.UserProfileRepository>()),
    );
    gh.lazySingleton<_i157.SyncUserProfileUseCase>(
      () => _i157.SyncUserProfileUseCase(gh<_i512.UserProfileRepository>()),
    );
    gh.lazySingleton<_i798.UpdateDeviceInfoUseCase>(
      () => _i798.UpdateDeviceInfoUseCase(gh<_i512.UserProfileRepository>()),
    );
    gh.lazySingleton<_i173.AlarmScheduler>(
      () => _i222.PlatformAlarmScheduler(
        gh<_i156.AlarmPlatformClient>(),
        gh<_i1012.AlarmAudioRepository>(),
      ),
    );
    gh.lazySingleton<_i414.RefreshVoicesUseCase>(
      () => _i414.RefreshVoicesUseCase(gh<_i334.VoiceRepository>()),
    );
    gh.lazySingleton<_i904.WatchVoicesUseCase>(
      () => _i904.WatchVoicesUseCase(gh<_i334.VoiceRepository>()),
    );
    gh.lazySingleton<_i73.CreateAlarmUseCase>(
      () => _i73.CreateAlarmUseCase(
        gh<_i1032.AlarmRepository>(),
        gh<_i452.RemoteAlarmRepository>(),
        gh<_i173.AlarmScheduler>(),
      ),
    );
    gh.lazySingleton<_i8.RemoveAlarmUseCase>(
      () => _i8.RemoveAlarmUseCase(
        gh<_i1032.AlarmRepository>(),
        gh<_i452.RemoteAlarmRepository>(),
        gh<_i173.AlarmScheduler>(),
      ),
    );
    gh.lazySingleton<_i40.UploadPendingAlarmsUseCase>(
      () => _i40.UploadPendingAlarmsUseCase(
        gh<_i1032.AlarmRepository>(),
        gh<_i452.RemoteAlarmRepository>(),
      ),
    );
    gh.factory<_i64.ReasonReadyBloc>(
      () => _i64.ReasonReadyBloc(gh<_i836.RenameReasonUseCase>()),
    );
    gh.lazySingleton<_i278.HasAlarmAccessUseCase>(
      () => _i278.HasAlarmAccessUseCase(gh<_i173.AlarmScheduler>()),
    );
    gh.lazySingleton<_i278.RequestAlarmAccessUseCase>(
      () => _i278.RequestAlarmAccessUseCase(gh<_i173.AlarmScheduler>()),
    );
    gh.lazySingleton<_i478.GetMatterSuggestionsUseCase>(
      () => _i478.GetMatterSuggestionsUseCase(gh<_i650.AreaOfLifeRepository>()),
    );
    gh.lazySingleton<_i879.GetPurposeSuggestionsUseCase>(
      () =>
          _i879.GetPurposeSuggestionsUseCase(gh<_i650.AreaOfLifeRepository>()),
    );
    gh.lazySingleton<_i190.RefreshAreasOfLifeUseCase>(
      () => _i190.RefreshAreasOfLifeUseCase(gh<_i650.AreaOfLifeRepository>()),
    );
    gh.lazySingleton<_i375.WatchAreasOfLifeUseCase>(
      () => _i375.WatchAreasOfLifeUseCase(gh<_i650.AreaOfLifeRepository>()),
    );
    gh.lazySingleton<_i619.RefreshAlarmAudioUseCase>(
      () => _i619.RefreshAlarmAudioUseCase(gh<_i1012.AlarmAudioRepository>()),
    );
    gh.lazySingleton<_i393.WatchAlarmAudioUseCase>(
      () => _i393.WatchAlarmAudioUseCase(gh<_i1012.AlarmAudioRepository>()),
    );
    gh.lazySingleton<_i218.RescheduleAlarmsUseCase>(
      () => _i218.RescheduleAlarmsUseCase(
        gh<_i1032.AlarmRepository>(),
        gh<_i173.AlarmScheduler>(),
      ),
    );
    gh.lazySingleton<_i97.SetAlarmEnabledUseCase>(
      () => _i97.SetAlarmEnabledUseCase(
        gh<_i1032.AlarmRepository>(),
        gh<_i173.AlarmScheduler>(),
      ),
    );
    gh.lazySingleton<_i874.DeleteReasonWithAlarmUseCase>(
      () => _i874.DeleteReasonWithAlarmUseCase(
        gh<_i23.ReasonRepository>(),
        gh<_i1032.AlarmRepository>(),
        gh<_i452.RemoteAlarmRepository>(),
        gh<_i8.RemoveAlarmUseCase>(),
      ),
    );
    gh.factory<_i1005.MyAlarmsBloc>(
      () => _i1005.MyAlarmsBloc(
        gh<_i586.GetAlarmsUseCase>(),
        gh<_i258.WatchAlarmsUseCase>(),
        gh<_i305.WatchReasonsUseCase>(),
        gh<_i97.SetAlarmEnabledUseCase>(),
        gh<_i8.RemoveAlarmUseCase>(),
        gh<_i278.HasAlarmAccessUseCase>(),
        gh<_i278.RequestAlarmAccessUseCase>(),
      ),
    );
    gh.factory<_i646.AlarmListBloc>(
      () => _i646.AlarmListBloc(
        gh<_i586.GetAlarmsUseCase>(),
        gh<_i357.SaveAlarmUseCase>(),
        gh<_i962.DeleteAlarmUseCase>(),
      ),
    );
    gh.factoryParam<_i252.ReasonDetailBloc, _i219.Reason?, dynamic>(
      (reason, _) => _i252.ReasonDetailBloc(
        gh<_i151.WatchReasonUseCase>(),
        gh<_i39.UpdateReasonUseCase>(),
        gh<_i836.RenameReasonUseCase>(),
        gh<_i874.DeleteReasonWithAlarmUseCase>(),
        gh<_i258.WatchAlarmsUseCase>(),
        gh<_i375.WatchAreasOfLifeUseCase>(),
        gh<_i190.RefreshAreasOfLifeUseCase>(),
        gh<_i904.WatchVoicesUseCase>(),
        gh<_i414.RefreshVoicesUseCase>(),
        gh<_i902.GetSoundTypesUseCase>(),
        gh<_i879.GetPurposeSuggestionsUseCase>(),
        gh<_i478.GetMatterSuggestionsUseCase>(),
        reason,
      ),
    );
    gh.factory<_i946.CreateReasonBloc>(
      () => _i946.CreateReasonBloc(
        gh<_i375.WatchAreasOfLifeUseCase>(),
        gh<_i190.RefreshAreasOfLifeUseCase>(),
        gh<_i904.WatchVoicesUseCase>(),
        gh<_i414.RefreshVoicesUseCase>(),
        gh<_i879.GetPurposeSuggestionsUseCase>(),
        gh<_i478.GetMatterSuggestionsUseCase>(),
        gh<_i902.GetSoundTypesUseCase>(),
        gh<_i262.GetSoundQuoteUseCase>(),
        gh<_i1004.CreateReasonUseCase>(),
      ),
    );
    gh.factoryParam<_i494.CreateAlarmBloc, int?, dynamic>(
      (reasonId, _) => _i494.CreateAlarmBloc(
        gh<_i305.WatchReasonsUseCase>(),
        gh<_i393.WatchAlarmAudioUseCase>(),
        gh<_i586.GetAlarmsUseCase>(),
        gh<_i73.CreateAlarmUseCase>(),
        gh<_i278.HasAlarmAccessUseCase>(),
        gh<_i278.RequestAlarmAccessUseCase>(),
        reasonId,
      ),
    );
    gh.factory<_i875.DashboardBloc>(
      () => _i875.DashboardBloc(
        gh<_i36.AnalyticsService>(),
        gh<_i131.EnsureSignedInUseCase>(),
        gh<_i157.SyncUserProfileUseCase>(),
        gh<_i798.UpdateDeviceInfoUseCase>(),
        gh<_i49.GetAppInfoUseCase>(),
        gh<_i619.RefreshAlarmAudioUseCase>(),
        gh<_i218.RescheduleAlarmsUseCase>(),
        gh<_i40.UploadPendingAlarmsUseCase>(),
      ),
    );
    return this;
  }
}

class _$DatabaseModule extends _i26.DatabaseModule {}

class _$FirebaseModule extends _i101.FirebaseModule {}

class _$SpeechModule extends _i942.SpeechModule {}

class _$StorageModule extends _i964.StorageModule {}

class _$SupabaseModule extends _i543.SupabaseModule {}
