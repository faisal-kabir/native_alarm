import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/alarm.dart';
import '../repositories/alarm_repository.dart';

/// Loads the saved alarms. A one-time alarm whose time has passed has already rung,
/// so it is switched off (and saved that way), like the system clock app does.
@lazySingleton
class GetAlarmsUseCase implements UseCase<List<Alarm>, NoParams> {
  final AlarmRepository repository;

  GetAlarmsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Alarm>>> call(NoParams params) async {
    final result = await repository.getAlarms();
    return result.fold(Left.new, (alarms) async {
      final now = DateTime.now();
      final updated = <Alarm>[];
      for (final alarm in alarms) {
        final expired =
            alarm.enabled &&
            alarm.repeatWeekdays.isEmpty &&
            alarm.time.isBefore(now);
        if (expired) {
          final off = alarm.copyWith(enabled: false);
          await repository.saveAlarm(off);
          updated.add(off);
        } else {
          updated.add(alarm);
        }
      }
      return Right(updated);
    });
  }
}
