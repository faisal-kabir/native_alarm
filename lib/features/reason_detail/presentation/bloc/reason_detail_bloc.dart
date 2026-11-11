import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/load_status.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../alarm/domain/usecases/watch_alarms_usecase.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../domain/usecases/delete_reason_with_alarm_usecase.dart';
import '../../../create_alarm/domain/usecases/sync_system_alarms_usecase.dart';
import '../../../reasons/domain/usecases/rename_reason_usecase.dart';
import '../../../reasons/domain/usecases/update_reason_usecase.dart';
import '../../../reasons/domain/usecases/watch_reason_usecase.dart';
import '../../../sound/domain/usecases/get_sound_types_usecase.dart';
import '../../../voice/domain/entities/voice.dart';
import '../../../voice/domain/usecases/refresh_voices_usecase.dart';
import '../../../voice/domain/usecases/watch_voices_usecase.dart';
import 'reason_detail_event.dart';
import 'reason_detail_state.dart';

/// A reason's own screen. It shows the cached reason at once and follows its saved
/// copy; the sheets' choices are HELD in [ReasonDetailState.draft] (nothing is saved by
/// a sheet) until "Save Changes" saves them all in one go. A rename is saved on its
/// own, at once.
@injectable
class ReasonDetailBloc extends Bloc<ReasonDetailEvent, ReasonDetailState> {
  final WatchReasonUseCase watchReasonUseCase;
  final UpdateReasonUseCase updateReasonUseCase;
  final RenameReasonUseCase renameReasonUseCase;
  final DeleteReasonWithAlarmUseCase deleteReasonUseCase;
  final WatchAlarmsUseCase watchAlarmsUseCase;
  final SyncSystemAlarmsUseCase syncSystemAlarmsUseCase;
  final WatchVoicesUseCase watchVoicesUseCase;
  final RefreshVoicesUseCase refreshVoicesUseCase;
  final GetSoundTypesUseCase getSoundTypesUseCase;

  ReasonDetailBloc(
    this.watchReasonUseCase,
    this.updateReasonUseCase,
    this.renameReasonUseCase,
    this.deleteReasonUseCase,
    this.watchAlarmsUseCase,
    this.syncSystemAlarmsUseCase,
    this.watchVoicesUseCase,
    this.refreshVoicesUseCase,
    this.getSoundTypesUseCase,
    @factoryParam Reason? reason,
  ) : super(ReasonDetailState(reason: reason!)) {
    on<ReasonDetailStartedEvent>(_onStarted);
    on<ReasonDetailVoicesWatchedEvent>(_onWatchVoices);
    on<ReasonDetailAlarmsWatchedEvent>(_onWatchAlarms);
    on<ReasonDetailSoundTypesRequestedEvent>(_onLoadSoundTypes);
    on<ReasonDetailDraftChangedEvent>(
      (event, emit) => emit(state.copyWith(draft: event.draft)),
    );
    on<ReasonDetailDiscardedEvent>(
      (event, emit) => emit(state.copyWith(draft: state.reason.draft)),
    );
    on<ReasonDetailSavedEvent>(_onSave);
    on<ReasonDetailRenamedEvent>(_onRename);
    on<ReasonDetailDeleteRequestedEvent>(_onDelete);
  }

  Future<void> _onDelete(
    ReasonDetailDeleteRequestedEvent event,
    Emitter<ReasonDetailState> emit,
  ) async {
    if (state.deleting || state.deleted) return;
    emit(state.copyWith(deleting: true));
    final result = await deleteReasonUseCase(state.reason);
    emit(
      result.fold(
        (_) => state.copyWith(
          deleting: false,
          deleteFailures: state.deleteFailures + 1,
        ),
        (_) => state.copyWith(deleting: false, deleted: true),
      ),
    );
  }

  /// Follows the saved reason: a save, a rename or a background refresh shows here.
  /// Held changes stay held; with none, the screen follows the new values.
  Future<void> _onStarted(
    ReasonDetailStartedEvent event,
    Emitter<ReasonDetailState> emit,
  ) async {
    add(const ReasonDetailVoicesWatchedEvent());
    add(const ReasonDetailAlarmsWatchedEvent());
    add(const ReasonDetailSoundTypesRequestedEvent());
    await emit.forEach<Either<Failure, Reason?>>(
      watchReasonUseCase(state.reason.id),
      onData: (result) {
        final saved = result.fold((_) => null, (reason) => reason);
        if (saved == null) return state;
        return state.copyWith(
          reason: saved,
          draft: state.dirty ? null : saved.draft,
        );
      },
    );
  }

  Future<void> _onWatchVoices(
    ReasonDetailVoicesWatchedEvent event,
    Emitter<ReasonDetailState> emit,
  ) async {
    refreshVoicesUseCase(NoParams());
    await emit.forEach<Either<Failure, List<Voice>>>(
      watchVoicesUseCase(NoParams()),
      onData: (result) =>
          result.fold((_) => state, (voices) => state.copyWith(voices: voices)),
    );
  }

  Future<void> _onWatchAlarms(
    ReasonDetailAlarmsWatchedEvent event,
    Emitter<ReasonDetailState> emit,
  ) => emit.forEach<Either<Failure, List<Alarm>>>(
    watchAlarmsUseCase(NoParams()),
    onData: (result) =>
        result.fold((_) => state, (alarms) => state.copyWith(alarms: alarms)),
  );

  Future<void> _onLoadSoundTypes(
    ReasonDetailSoundTypesRequestedEvent event,
    Emitter<ReasonDetailState> emit,
  ) async {
    emit(state.copyWith(soundTypesStatus: LoadStatus.loading));
    final result = await getSoundTypesUseCase(NoParams());
    emit(
      result.fold(
        (_) => state.copyWith(soundTypesStatus: LoadStatus.failed),
        (sounds) => state.copyWith(
          soundTypes: sounds,
          soundTypesStatus: LoadStatus.loaded,
        ),
      ),
    );
  }

  Future<void> _onSave(
    ReasonDetailSavedEvent event,
    Emitter<ReasonDetailState> emit,
  ) async {
    if (!state.dirty || state.saving) return;
    emit(state.copyWith(saving: true));
    final result = await updateReasonUseCase(
      UpdateReasonParams(state.reason.id, state.draft),
    );
    emit(
      result.fold(
        (_) =>
            state.copyWith(saving: false, saveFailures: state.saveFailures + 1),
        (saved) =>
            state.copyWith(reason: saved, draft: saved.draft, saving: false),
      ),
    );
  }

  Future<void> _onRename(
    ReasonDetailRenamedEvent event,
    Emitter<ReasonDetailState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty || name == state.reason.name) return;
    final result = await renameReasonUseCase(
      RenameReasonParams(state.reason.id, name),
    );
    emit(
      result.fold(
        (_) => state.copyWith(renameFailures: state.renameFailures + 1),
        (saved) => state.copyWith(reason: saved),
      ),
    );
    // Its alarm rings with its name: the device's alarm follows.
    if (result.isRight() && state.alarm != null) {
      await syncSystemAlarmsUseCase(SyncSystemAlarmsParams(DateTime.now()));
    }
  }
}
