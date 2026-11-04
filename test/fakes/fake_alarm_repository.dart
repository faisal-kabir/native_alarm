import 'package:dartz/dartz.dart';
import 'package:eala/core/di/injection.dart';
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

/// In-memory [ReasonRepository].
class FakeReasonRepository implements ReasonRepository {
  FakeReasonRepository([this.reasons = const []]);

  final List<Reason> reasons;

  @override
  Future<Either<Failure, List<Reason>>> getReasons() async => Right(reasons);
}

/// Registers the BLoCs the app's screens need, backed by [repository] (and
/// [reasonRepository], empty by default).
Future<void> registerFakeAlarmDependencies(
  AlarmRepository repository, {
  ReasonRepository? reasonRepository,
}) async {
  await instance.reset();
  instance.registerFactory<AlarmListBloc>(() => buildAlarmListBloc(repository));
  instance.registerFactory<DashboardBloc>(DashboardBloc.new);
  instance.registerFactory<MyAlarmsBloc>(
    () => MyAlarmsBloc(GetAlarmsUseCase(repository)),
  );
  instance.registerFactory<ReasonsBloc>(
    () => ReasonsBloc(
      GetReasonsUseCase(reasonRepository ?? FakeReasonRepository()),
    ),
  );
  instance.registerLazySingleton<AlarmPlatformClient>(AlarmPlatformClient.new);
}
