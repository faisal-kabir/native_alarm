import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../alarm/domain/usecases/get_alarms_usecase.dart';
import '../../../alarm/domain/usecases/watch_alarms_usecase.dart';
import '../../../create_alarm/domain/entities/alarm_schedule.dart';
import '../../../create_alarm/domain/usecases/set_alarm_enabled_usecase.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/domain/usecases/watch_reasons_usecase.dart';
import 'my_alarms_event.dart';
import 'my_alarms_state.dart';

/// The "My Alarms" tab's data: the saved alarms, followed ([WatchAlarmsUseCase]; the
/// load, [GetAlarmsUseCase], switches off one-off alarms that have rung) and the
/// cached reasons they play, and each alarm's on / off switch
/// ([SetAlarmEnabledUseCase]). This screen has no storage of its own.
@injectable
class MyAlarmsBloc extends Bloc<MyAlarmsEvent, MyAlarmsState> {
  final GetAlarmsUseCase getAlarmsUseCase;
  final WatchAlarmsUseCase watchAlarmsUseCase;
  final WatchReasonsUseCase watchReasonsUseCase;
  final SetAlarmEnabledUseCase setAlarmEnabledUseCase;

  /// The latest reasons, kept for the next load.
  List<Reason> _reasons = const [];

  MyAlarmsBloc(
    this.getAlarmsUseCase,
    this.watchAlarmsUseCase,
    this.watchReasonsUseCase,
    this.setAlarmEnabledUseCase,
  ) : super(const MyAlarmsInitial()) {
    on<LoadMyAlarmsEvent>(_onLoad);
    on<WatchMyAlarmsEvent>(_onWatch);
    on<WatchMyAlarmsReasonsEvent>(_onWatchReasons);
    on<MyAlarmsAlarmToggledEvent>(_onToggled);
  }

  /// The list's order: switched-on alarms by their next ring (the first is the next
  /// alarm), then the switched-off ones by time of day.
  static List<Alarm> _ordered(List<Alarm> alarms) {
    final now = DateTime.now();
    int minutes(Alarm a) => a.time.hour * 60 + a.time.minute;
    return [...alarms]..sort((a, b) {
      if (a.enabled != b.enabled) return a.enabled ? -1 : 1;
      final byTime = a.enabled
          ? nextRingOf(a, now).compareTo(nextRingOf(b, now))
          : minutes(a).compareTo(minutes(b));
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  }

  Future<void> _onLoad(
    LoadMyAlarmsEvent event,
    Emitter<MyAlarmsState> emit,
  ) async {
    final result = await getAlarmsUseCase(NoParams());
    result.fold((failure) {
      if (state is! MyAlarmsLoaded) emit(MyAlarmsFailure(failure.message));
    }, (_) {});
  }

  Future<void> _onWatch(
    WatchMyAlarmsEvent event,
    Emitter<MyAlarmsState> emit,
  ) async {
    if (state is! MyAlarmsLoaded) emit(const MyAlarmsLoading());
    await emit.forEach<Either<Failure, List<Alarm>>>(
      watchAlarmsUseCase(NoParams()),
      onData: (result) => result.fold(
        (failure) =>
            state is MyAlarmsLoaded ? state : MyAlarmsFailure(failure.message),
        (alarms) => MyAlarmsLoaded(
          alarms: _ordered(alarms),
          reasons: _reasons,
          alarmLimit: AppConstant.maxAlarmCount,
          toggleFailures: switch (state) {
            final MyAlarmsLoaded s => s.toggleFailures,
            _ => 0,
          },
        ),
      ),
    );
  }

  /// The switch moves at once; the device and the saved alarm follow, and if they
  /// refuse, the switch goes back and the page says so.
  Future<void> _onToggled(
    MyAlarmsAlarmToggledEvent event,
    Emitter<MyAlarmsState> emit,
  ) async {
    final before = state;
    if (before is! MyAlarmsLoaded) return;
    List<Alarm> replace(Alarm alarm) => [
      for (final a in before.alarms) a.id == alarm.id ? alarm : a,
    ];
    emit(
      before.copyWith(
        alarms: replace(event.alarm.copyWith(enabled: event.enabled)),
      ),
    );
    final result = await setAlarmEnabledUseCase(
      SetAlarmEnabledParams(
        event.alarm,
        enabled: event.enabled,
        now: DateTime.now(),
      ),
    );
    final now = state;
    if (now is! MyAlarmsLoaded) return;
    emit(
      result.fold(
        (_) => now.copyWith(
          alarms: before.alarms,
          toggleFailures: now.toggleFailures + 1,
        ),
        (saved) => now.copyWith(alarms: _ordered(replace(saved))),
      ),
    );
  }

  Future<void> _onWatchReasons(
    WatchMyAlarmsReasonsEvent event,
    Emitter<MyAlarmsState> emit,
  ) => emit.forEach<Either<Failure, List<Reason>>>(
    watchReasonsUseCase(NoParams()),
    onData: (result) => result.fold((_) => state, (reasons) {
      _reasons = reasons;
      final now = state;
      return now is MyAlarmsLoaded ? now.copyWith(reasons: reasons) : now;
    }),
  );
}
