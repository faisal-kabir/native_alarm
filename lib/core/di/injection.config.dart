// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:eala/core/database/app_database.dart' as _i81;
import 'package:eala/core/database/database_module.dart' as _i25;
import 'package:eala/core/platform/alarm_platform_client.dart' as _i156;
import 'package:eala/features/alarm/data/datasources/alarm_local_data_source.dart'
    as _i276;
import 'package:eala/features/alarm/data/repositories/alarm_repository_impl.dart'
    as _i695;
import 'package:eala/features/alarm/domain/repositories/alarm_repository.dart'
    as _i1032;
import 'package:eala/features/alarm/domain/usecases/delete_alarm_usecase.dart'
    as _i962;
import 'package:eala/features/alarm/domain/usecases/get_alarms_usecase.dart'
    as _i586;
import 'package:eala/features/alarm/domain/usecases/save_alarm_usecase.dart'
    as _i357;
import 'package:eala/features/alarm/presentation/bloc/alarm_list_bloc.dart'
    as _i646;
import 'package:eala/features/dashboard/presentation/bloc/dashboard_bloc.dart'
    as _i874;
import 'package:eala/features/my_alarms/presentation/bloc/my_alarms_bloc.dart'
    as _i1005;
import 'package:eala/features/reasons/data/datasources/reason_local_data_source.dart'
    as _i429;
import 'package:eala/features/reasons/data/repositories/reason_repository_impl.dart'
    as _i534;
import 'package:eala/features/reasons/domain/repositories/reason_repository.dart'
    as _i23;
import 'package:eala/features/reasons/domain/usecases/get_reasons_usecase.dart'
    as _i838;
import 'package:eala/features/reasons/presentation/bloc/reasons_bloc.dart'
    as _i743;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    gh.factory<_i874.DashboardBloc>(() => _i874.DashboardBloc());
    gh.lazySingleton<_i81.AppDatabase>(() => databaseModule.database);
    gh.lazySingleton<_i156.AlarmPlatformClient>(
      () => _i156.AlarmPlatformClient(),
    );
    gh.lazySingleton<_i276.AlarmLocalDataSource>(
      () => _i276.AlarmLocalDataSourceImpl(gh<_i81.AppDatabase>()),
    );
    gh.lazySingleton<_i429.ReasonLocalDataSource>(
      () => _i429.ReasonLocalDataSourceImpl(gh<_i81.AppDatabase>()),
    );
    gh.lazySingleton<_i23.ReasonRepository>(
      () => _i534.ReasonRepositoryImpl(gh<_i429.ReasonLocalDataSource>()),
    );
    gh.lazySingleton<_i1032.AlarmRepository>(
      () => _i695.AlarmRepositoryImpl(gh<_i276.AlarmLocalDataSource>()),
    );
    gh.lazySingleton<_i838.GetReasonsUseCase>(
      () => _i838.GetReasonsUseCase(gh<_i23.ReasonRepository>()),
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
    gh.factory<_i1005.MyAlarmsBloc>(
      () => _i1005.MyAlarmsBloc(gh<_i586.GetAlarmsUseCase>()),
    );
    gh.factory<_i743.ReasonsBloc>(
      () => _i743.ReasonsBloc(gh<_i838.GetReasonsUseCase>()),
    );
    gh.factory<_i646.AlarmListBloc>(
      () => _i646.AlarmListBloc(
        gh<_i586.GetAlarmsUseCase>(),
        gh<_i357.SaveAlarmUseCase>(),
        gh<_i962.DeleteAlarmUseCase>(),
      ),
    );
    return this;
  }
}

class _$DatabaseModule extends _i25.DatabaseModule {}
