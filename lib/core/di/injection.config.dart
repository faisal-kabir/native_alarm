// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:eala/core/database/database_module.dart' as _i25;
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
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:isar_community/isar.dart' as _i214;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    await gh.singletonAsync<_i214.Isar>(
      () => databaseModule.isar,
      preResolve: true,
    );
    gh.lazySingleton<_i276.AlarmLocalDataSource>(
      () => _i276.AlarmLocalDataSourceImpl(gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i1032.AlarmRepository>(
      () => _i695.AlarmRepositoryImpl(gh<_i276.AlarmLocalDataSource>()),
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
