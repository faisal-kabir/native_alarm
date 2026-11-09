import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../alarm/domain/usecases/alarm_access_usecases.dart';
import '../../../alarm/domain/usecases/get_alarms_usecase.dart';
import '../../../alarm_audio/domain/entities/alarm_audio.dart';
import '../../../alarm_audio/domain/usecases/watch_alarm_audio_usecase.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/domain/usecases/watch_reasons_usecase.dart';
import '../../domain/entities/alarm_draft.dart';
import '../../domain/entities/alarm_schedule.dart';
import '../../domain/usecases/create_alarm_usecase.dart';
import '../../domain/usecases/remove_alarm_usecase.dart';
import '../../domain/usecases/update_alarm_usecase.dart';
import 'create_alarm_event.dart';
import 'create_alarm_state.dart';

/// "Add Alarm" / "Edit Alarm". Holds the whole form (the schedule cards and every
/// choice) and reads only what the device already has: the cached reasons, alarm
/// sounds and sound tracks, so an alarm can be made offline. [reasonId] is a Reason a
/// new alarm arrives with; [editing] is a saved alarm to edit (everything filled in
/// from it, "Save Changes" through [UpdateAlarmUseCase], "Delete Alarm" through
/// [RemoveAlarmUseCase]).
@injectable
class CreateAlarmBloc extends Bloc<CreateAlarmEvent, CreateAlarmState> {
  final WatchReasonsUseCase watchReasonsUseCase;
  final WatchAlarmAudioUseCase watchAlarmAudioUseCase;
  final GetAlarmsUseCase getAlarmsUseCase;
  final CreateAlarmUseCase createAlarmUseCase;
  final UpdateAlarmUseCase updateAlarmUseCase;
  final RemoveAlarmUseCase removeAlarmUseCase;
  final HasAlarmAccessUseCase hasAlarmAccessUseCase;
  final RequestAlarmAccessUseCase requestAlarmAccessUseCase;

  CreateAlarmBloc(
    this.watchReasonsUseCase,
    this.watchAlarmAudioUseCase,
    this.getAlarmsUseCase,
    this.createAlarmUseCase,
    this.updateAlarmUseCase,
    this.removeAlarmUseCase,
    this.hasAlarmAccessUseCase,
    this.requestAlarmAccessUseCase,
    @factoryParam int? reasonId,
    @factoryParam Alarm? editing,
  ) : super(editing == null ? _first(reasonId) : _edit(editing)) {
    on<CreateAlarmStartedEvent>(_onStarted);
    on<CreateAlarmReasonsWatchedEvent>(_onWatchReasons);
    on<CreateAlarmSoundsWatchedEvent>(_onWatchSounds);
    on<CreateAlarmTimeChangedEvent>(
      (e, emit) => emit(
        state.copyWith(cards: setCardTime(state.cards, e.cardId, e.time)),
      ),
    );
    on<CreateAlarmDayToggledEvent>(
      (e, emit) => emit(
        state.copyWith(cards: toggleCardDay(state.cards, e.cardId, e.day)),
      ),
    );
    on<CreateAlarmCardAddedEvent>(
      (e, emit) => emit(
        state.copyWith(
          cards: addCard(state.cards, 't${state.nextCardId}'),
          nextCardId: state.nextCardId + 1,
        ),
      ),
    );
    on<CreateAlarmReasonChosenEvent>(
      (e, emit) => emit(
        state.copyWith(draft: state.draft.copyWith(reasonId: e.reasonId)),
      ),
    );
    on<CreateAlarmSoundTrackChosenEvent>(
      (e, emit) =>
          emit(state.copyWith(draft: state.draft.copyWith(soundTrackId: e.id))),
    );
    on<CreateAlarmAlarmSoundChosenEvent>(
      (e, emit) =>
          emit(state.copyWith(draft: state.draft.copyWith(alarmSoundId: e.id))),
    );
    on<CreateAlarmRingAgainChangedEvent>(
      (e, emit) =>
          emit(state.copyWith(draft: state.draft.copyWith(again: e.again))),
    );
    on<CreateAlarmEnabledChangedEvent>(
      (e, emit) =>
          emit(state.copyWith(draft: state.draft.copyWith(enabled: e.enabled))),
    );
    on<CreateAlarmAccessRequestedEvent>(_onAccessRequested);
    on<CreateAlarmSavedEvent>(_onSave);
    on<CreateAlarmDeleteRequestedEvent>(_onDelete);
  }

  /// A saved alarm, every choice filled in; its schedule as cards.
  static CreateAlarmState _edit(Alarm alarm) {
    final draft = editorDraftOf(alarm);
    var next = 0;
    final cards = groupDays(draft, () => 't${next++}');
    return CreateAlarmState(
      draft: draft,
      cards: cards,
      nextCardId: next,
      editing: alarm,
      initial: finalize(fromCards(draft, cards)),
    );
  }

  /// A new alarm: 6:30 AM, once, on, no ring again; one card.
  static CreateAlarmState _first(int? reasonId) {
    final draft = AlarmDraft(reasonId: reasonId);
    return CreateAlarmState(
      draft: draft,
      cards: groupDays(draft, () => 't0'),
      nextCardId: 1,
    );
  }

  Future<void> _onStarted(
    CreateAlarmStartedEvent event,
    Emitter<CreateAlarmState> emit,
  ) async {
    add(const CreateAlarmReasonsWatchedEvent());
    add(const CreateAlarmSoundsWatchedEvent());

    final editing = state.editing;
    final alarms = [
      for (final a in (await getAlarmsUseCase(
        NoParams(),
      )).getOrElse(() => const []))
        if (a.id != editing?.id) a,
    ];
    // Every way in checks for a free place first; this catches one that did not.
    if (editing == null && alarms.length >= AppConstant.maxAlarmCount) {
      emit(state.copyWith(status: CreateAlarmStatus.full));
      return;
    }
    final access = (await hasAlarmAccessUseCase(NoParams()))
        .getOrElse(() => true);
    emit(
      state.copyWith(
        takenReasonIds: {
          for (final a in alarms)
            if (a.reasonId != null) a.reasonId!,
        },
        accessDenied: !access,
      ),
    );
  }

  Future<void> _onWatchReasons(
    CreateAlarmReasonsWatchedEvent event,
    Emitter<CreateAlarmState> emit,
  ) => emit.forEach<Either<Failure, List<Reason>>>(
    watchReasonsUseCase(NoParams()),
    onData: (result) => result.fold(
      (_) => state,
      (reasons) => state.copyWith(reasons: reasons),
    ),
  );

  /// Both lists, from the device; a new alarm starts on each list's first row until
  /// one is chosen (an edited one keeps what it was saved with).
  Future<void> _onWatchSounds(
    CreateAlarmSoundsWatchedEvent event,
    Emitter<CreateAlarmState> emit,
  ) async {
    Future<void> follow(
      AlarmAudioKind kind,
      CreateAlarmState Function(List<AlarmAudio>) apply,
    ) => emit.forEach<Either<Failure, List<AlarmAudio>>>(
      watchAlarmAudioUseCase(kind),
      onData: (result) => result.fold((_) => state, apply),
    );

    await Future.wait([
      follow(
        AlarmAudioKind.soundTrack,
        (list) => state.copyWith(
          soundTracks: list,
          draft:
              !state.isEdit &&
                  state.draft.soundTrackId == null &&
                  list.isNotEmpty
              ? state.draft.copyWith(soundTrackId: list.first.id)
              : null,
        ),
      ),
      follow(
        AlarmAudioKind.alarmSound,
        (list) => state.copyWith(
          alarmSounds: list,
          draft:
              !state.isEdit &&
                  state.draft.alarmSoundId == null &&
                  list.isNotEmpty
              ? state.draft.copyWith(alarmSoundId: list.first.id)
              : null,
        ),
      ),
    ]);
  }

  Future<void> _onAccessRequested(
    CreateAlarmAccessRequestedEvent event,
    Emitter<CreateAlarmState> emit,
  ) async {
    await requestAlarmAccessUseCase(NoParams());
    final access = (await hasAlarmAccessUseCase(NoParams()))
        .getOrElse(() => true);
    emit(state.copyWith(accessDenied: !access));
  }

  Future<void> _onSave(
    CreateAlarmSavedEvent event,
    Emitter<CreateAlarmState> emit,
  ) async {
    final reason = state.reason;
    if (reason == null || state.status != CreateAlarmStatus.editing) return;
    final editing = state.editing;
    if (editing != null && !state.dirty) return;
    emit(state.copyWith(status: CreateAlarmStatus.saving));
    final now = DateTime.now();
    final result = editing == null
        ? await createAlarmUseCase(
            CreateAlarmParams(draft: state.view, title: reason.name, now: now),
          )
        : await updateAlarmUseCase(
            UpdateAlarmParams(
              alarm: editing,
              draft: state.view,
              title: reason.name,
              now: now,
            ),
          );
    emit(
      result.fold(
        (failure) => failure is AlarmLimitFailure
            ? state.copyWith(status: CreateAlarmStatus.full)
            : state.copyWith(
                status: CreateAlarmStatus.editing,
                saveFailures: state.saveFailures + 1,
              ),
        (_) => state.copyWith(status: CreateAlarmStatus.saved),
      ),
    );
  }

  Future<void> _onDelete(
    CreateAlarmDeleteRequestedEvent event,
    Emitter<CreateAlarmState> emit,
  ) async {
    final editing = state.editing;
    if (editing == null || state.status != CreateAlarmStatus.editing) return;
    emit(state.copyWith(status: CreateAlarmStatus.deleting));
    final result = await removeAlarmUseCase(editing);
    emit(
      result.fold(
        (_) => state.copyWith(
          status: CreateAlarmStatus.editing,
          deleteFailures: state.deleteFailures + 1,
        ),
        (_) => state.copyWith(status: CreateAlarmStatus.deleted),
      ),
    );
  }
}
