import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/usecases/delete_alarm_usecase.dart';
import '../../domain/usecases/get_alarms_usecase.dart';
import '../../domain/usecases/save_alarm_usecase.dart';
import 'alarm_list_event.dart';
import 'alarm_list_state.dart';

/// Owns the saved alarm list. Native scheduling stays in the page; this BLoC only
/// keeps the list in local storage so it survives an app restart.
@injectable
class AlarmListBloc extends Bloc<AlarmListEvent, AlarmListState> {
  final GetAlarmsUseCase getAlarmsUseCase;
  final SaveAlarmUseCase saveAlarmUseCase;
  final DeleteAlarmUseCase deleteAlarmUseCase;

  List<Alarm> _alarms = const [];

  AlarmListBloc(
    this.getAlarmsUseCase,
    this.saveAlarmUseCase,
    this.deleteAlarmUseCase,
  ) : super(const AlarmListInitial()) {
    on<LoadAlarmsEvent>(_onLoad);
    on<SaveAlarmEvent>(_onSave);
    on<DeleteAlarmEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadAlarmsEvent event,
    Emitter<AlarmListState> emit,
  ) async {
    emit(const AlarmListLoading());
    final result = await getAlarmsUseCase(NoParams());
    result.fold((failure) => emit(AlarmListFailure(failure.message, _alarms)), (
      alarms,
    ) {
      _alarms = alarms;
      emit(AlarmListLoaded(_alarms));
    });
  }

  Future<void> _onSave(
    SaveAlarmEvent event,
    Emitter<AlarmListState> emit,
  ) async {
    // Show the change right away, then persist it.
    final index = _alarms.indexWhere((a) => a.id == event.alarm.id);
    final next = List<Alarm>.from(_alarms);
    if (index == -1) {
      next.add(event.alarm);
    } else {
      next[index] = event.alarm;
    }
    next.sort((a, b) => a.time.compareTo(b.time));
    _alarms = List.unmodifiable(next);
    emit(AlarmListLoaded(_alarms));

    final result = await saveAlarmUseCase(event.alarm);
    result.fold(
      (failure) => emit(AlarmListFailure(failure.message, _alarms)),
      (_) {},
    );
  }

  Future<void> _onDelete(
    DeleteAlarmEvent event,
    Emitter<AlarmListState> emit,
  ) async {
    // Emitted before any await so a swiped-away Dismissible leaves the tree at once.
    _alarms = List.unmodifiable(_alarms.where((a) => a.id != event.alarmId));
    emit(AlarmListLoaded(_alarms));

    final result = await deleteAlarmUseCase(event.alarmId);
    result.fold(
      (failure) => emit(AlarmListFailure(failure.message, _alarms)),
      (_) {},
    );
  }
}
