import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../alarm/domain/usecases/watch_alarms_usecase.dart';
import '../../domain/entities/reason.dart';
import '../../domain/usecases/refresh_reasons_usecase.dart';
import '../../domain/usecases/watch_reasons_usecase.dart';
import 'reasons_event.dart';
import 'reasons_state.dart';

@injectable
class ReasonsBloc extends Bloc<ReasonsEvent, ReasonsState> {
  final WatchReasonsUseCase watchReasonsUseCase;
  final RefreshReasonsUseCase refreshReasonsUseCase;
  final WatchAlarmsUseCase watchAlarmsUseCase;

  ReasonsBloc(
    this.watchReasonsUseCase,
    this.refreshReasonsUseCase,
    this.watchAlarmsUseCase,
  ) : super(const ReasonsInitial()) {
    on<LoadReasonsEvent>(_onLoad);
    on<RefreshReasonsEvent>(_onRefresh);
    on<ReasonsAlarmsWatchedEvent>(_onWatchAlarms);
  }

  /// The latest alarm marks, kept for when the reasons arrive after the alarms.
  Map<int, bool> _alarmOn = const {};

  /// The list always shows the device's copy; this only updates that copy.
  Future<void> _onRefresh(
    RefreshReasonsEvent event,
    Emitter<ReasonsState> emit,
  ) async {
    final result = await refreshReasonsUseCase(NoParams());
    result.fold(
      (failure) => debugPrint('Reasons not refreshed: ${failure.message}'),
      (_) {},
    );
  }

  /// Follows the saved reasons: a reason created or renamed anywhere shows up here
  /// at once.
  Future<void> _onLoad(
    LoadReasonsEvent event,
    Emitter<ReasonsState> emit,
  ) async {
    if (state is! ReasonsLoaded) emit(const ReasonsLoading());
    add(const RefreshReasonsEvent());
    add(const ReasonsAlarmsWatchedEvent());
    await emit.forEach<Either<Failure, List<Reason>>>(
      watchReasonsUseCase(NoParams()),
      onData: (result) => result.fold(
        (failure) => ReasonsFailure(failure.message),
        (reasons) => ReasonsLoaded(reasons, alarmOn: _alarmOn),
      ),
    );
  }

  /// Follows the saved alarms: a reason's mark turns on, off or goes as its alarm
  /// does. Emits only when a mark changed.
  Future<void> _onWatchAlarms(
    ReasonsAlarmsWatchedEvent event,
    Emitter<ReasonsState> emit,
  ) => emit.forEach<Either<Failure, List<Alarm>>>(
    watchAlarmsUseCase(NoParams()),
    onData: (result) {
      final alarms = result.fold((_) => null, (alarms) => alarms);
      if (alarms != null) {
        _alarmOn = {
          for (final a in alarms)
            if (a.reasonId != null) a.reasonId!: a.enabled,
        };
      }
      final current = state;
      return current is ReasonsLoaded
          ? ReasonsLoaded(current.reasons, alarmOn: _alarmOn)
          : current;
    },
  );
}
