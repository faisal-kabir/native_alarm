import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../alarm/domain/usecases/alarm_access_usecases.dart';
import '../../../alarm/domain/usecases/get_alarms_usecase.dart';
import '../../../alarm/domain/usecases/watch_alarms_usecase.dart';
import '../../../create_alarm/domain/usecases/remove_alarm_usecase.dart';
import '../../../create_alarm/domain/usecases/set_alarm_enabled_usecase.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/domain/usecases/watch_reasons_usecase.dart';
import 'my_alarms_event.dart';
import 'my_alarms_state.dart';

/// The "My Alarms" tab's data: the saved alarms, followed ([WatchAlarmsUseCase]; the
/// load, [GetAlarmsUseCase], switches off one-off alarms that have rung), the cached
/// reasons they play, whether the system lets alarms ring, each alarm's on / off
/// switch ([SetAlarmEnabledUseCase]) and its delete ([RemoveAlarmUseCase]). The page
/// lays the list out (`arrangeAlarms`); this screen has no storage of its own.
@injectable
class MyAlarmsBloc extends Bloc<MyAlarmsEvent, MyAlarmsState> {
  final GetAlarmsUseCase getAlarmsUseCase;
  final WatchAlarmsUseCase watchAlarmsUseCase;
  final WatchReasonsUseCase watchReasonsUseCase;
  final SetAlarmEnabledUseCase setAlarmEnabledUseCase;
  final RemoveAlarmUseCase removeAlarmUseCase;
  final HasAlarmAccessUseCase hasAlarmAccessUseCase;
  final RequestAlarmAccessUseCase requestAlarmAccessUseCase;

  /// The latest reasons and access, kept for the next list.
  List<Reason> _reasons = const [];
  bool _accessDenied = false;

  MyAlarmsBloc(
    this.getAlarmsUseCase,
    this.watchAlarmsUseCase,
    this.watchReasonsUseCase,
    this.setAlarmEnabledUseCase,
    this.removeAlarmUseCase,
    this.hasAlarmAccessUseCase,
    this.requestAlarmAccessUseCase,
  ) : super(const MyAlarmsInitial()) {
    on<LoadMyAlarmsEvent>(_onLoad);
    on<WatchMyAlarmsEvent>(_onWatch);
    on<WatchMyAlarmsReasonsEvent>(_onWatchReasons);
    on<MyAlarmsAlarmToggledEvent>(_onToggled);
    on<MyAlarmsAccessRequestedEvent>(_onAccessRequested);
    on<MyAlarmsAlarmDeletedEvent>(_onDeleted);
  }

  Future<void> _onLoad(
    LoadMyAlarmsEvent event,
    Emitter<MyAlarmsState> emit,
  ) async {
    final result = await getAlarmsUseCase(NoParams());
    result.fold((failure) {
      if (state is! MyAlarmsLoaded) emit(MyAlarmsFailure(failure.message));
    }, (_) {});
    await _checkAccess(emit);
  }

  Future<void> _onAccessRequested(
    MyAlarmsAccessRequestedEvent event,
    Emitter<MyAlarmsState> emit,
  ) async {
    await requestAlarmAccessUseCase(NoParams());
    await _checkAccess(emit);
  }

  Future<void> _checkAccess(Emitter<MyAlarmsState> emit) async {
    final access = await hasAlarmAccessUseCase(NoParams());
    _accessDenied = !access.getOrElse(() => true);
    final now = state;
    if (now is MyAlarmsLoaded) emit(now.copyWith(accessDenied: _accessDenied));
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
        (alarms) => switch (state) {
          final MyAlarmsLoaded s => s.copyWith(alarms: alarms),
          _ => MyAlarmsLoaded(
            alarms: alarms,
            reasons: _reasons,
            accessDenied: _accessDenied,
            alarmLimit: AppConstant.maxAlarmCount,
          ),
        },
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
        (saved) => now.copyWith(alarms: replace(saved)),
      ),
    );
  }

  /// The card has already gone, so the list drops the alarm at once (the server takes a
  /// moment); the saved list then follows. If it can not be deleted (offline), the
  /// alarm comes back and the page says so.
  Future<void> _onDeleted(
    MyAlarmsAlarmDeletedEvent event,
    Emitter<MyAlarmsState> emit,
  ) async {
    final before = state;
    if (before is MyAlarmsLoaded) {
      emit(
        before.copyWith(
          alarms: [
            for (final a in before.alarms)
              if (a.id != event.alarm.id) a,
          ],
        ),
      );
    }
    final result = await removeAlarmUseCase(event.alarm);
    final now = state;
    if (result.isLeft() && now is MyAlarmsLoaded) {
      emit(
        now.copyWith(
          alarms: [...now.alarms, event.alarm],
          deleteFailures: now.deleteFailures + 1,
        ),
      );
    }
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
