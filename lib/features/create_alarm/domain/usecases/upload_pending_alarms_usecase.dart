import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/repositories/alarm_repository.dart';
import '../repositories/remote_alarm_repository.dart';

class UploadPendingAlarmsParams {
  const UploadPendingAlarmsParams(this.now);

  final DateTime now;
}

/// Sends the server every alarm made offline (no [Alarm.remoteId] yet, with a
/// Reason), run when the app opens with a session. Each one sent is saved again as the
/// server answered it; one that fails waits for the next open. Answers how many were
/// sent; two calls at once run only once.
@lazySingleton
class UploadPendingAlarmsUseCase
    implements UseCase<int, UploadPendingAlarmsParams> {
  final AlarmRepository repository;
  final RemoteAlarmRepository remote;

  UploadPendingAlarmsUseCase(this.repository, this.remote);

  Future<Either<Failure, int>>? _running;

  @override
  Future<Either<Failure, int>> call(UploadPendingAlarmsParams params) =>
      _running ??= _run(params.now).whenComplete(() => _running = null);

  Future<Either<Failure, int>> _run(DateTime now) async =>
      (await repository.getAlarms()).fold((failure) async => Left(failure), (
        alarms,
      ) async {
        var sent = 0;
        Failure? failure;
        for (final alarm in alarms.where(
          (a) => a.remoteId == null && a.reasonId != null,
        )) {
          final uploaded = await remote.upload(alarm, now: now);
          await uploaded.fold((f) async => failure ??= f, (saved) async {
            if ((await repository.saveAlarm(saved)).isRight()) sent++;
          });
        }
        final first = failure;
        return first == null ? Right(sent) : Left(first);
      });
}
