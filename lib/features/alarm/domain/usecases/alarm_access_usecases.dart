import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/alarm_scheduler.dart';

/// Whether the app may ring alarms. An answer that can not be had counts as yes, so
/// nothing is blocked by a missing reply.
@lazySingleton
class HasAlarmAccessUseCase implements UseCase<bool, NoParams> {
  final AlarmScheduler scheduler;

  HasAlarmAccessUseCase(this.scheduler);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      return Right(await scheduler.hasAccess());
    } catch (_) {
      return const Right(true);
    }
  }
}

/// Asks the system for permission to ring alarms.
@lazySingleton
class RequestAlarmAccessUseCase implements UseCase<Unit, NoParams> {
  final AlarmScheduler scheduler;

  RequestAlarmAccessUseCase(this.scheduler);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    try {
      await scheduler.requestAccess();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
