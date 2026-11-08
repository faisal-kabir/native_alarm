import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/load_status.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../area_of_life/domain/entities/purpose_suggestion.dart';
import '../../../area_of_life/domain/usecases/get_matter_suggestions_usecase.dart';
import '../../../area_of_life/domain/usecases/get_purpose_suggestions_usecase.dart';
import '../../../area_of_life/domain/usecases/refresh_areas_of_life_usecase.dart';
import '../../../area_of_life/domain/usecases/watch_areas_of_life_usecase.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/domain/usecases/delete_reason_usecase.dart';
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
  final DeleteReasonUseCase deleteReasonUseCase;
  final WatchAreasOfLifeUseCase watchAreasUseCase;
  final RefreshAreasOfLifeUseCase refreshAreasUseCase;
  final WatchVoicesUseCase watchVoicesUseCase;
  final RefreshVoicesUseCase refreshVoicesUseCase;
  final GetSoundTypesUseCase getSoundTypesUseCase;
  final GetPurposeSuggestionsUseCase getPurposeSuggestionsUseCase;
  final GetMatterSuggestionsUseCase getMatterSuggestionsUseCase;

  ReasonDetailBloc(
    this.watchReasonUseCase,
    this.updateReasonUseCase,
    this.renameReasonUseCase,
    this.deleteReasonUseCase,
    this.watchAreasUseCase,
    this.refreshAreasUseCase,
    this.watchVoicesUseCase,
    this.refreshVoicesUseCase,
    this.getSoundTypesUseCase,
    this.getPurposeSuggestionsUseCase,
    this.getMatterSuggestionsUseCase,
    @factoryParam Reason? reason,
  ) : super(ReasonDetailState(reason: reason!)) {
    on<ReasonDetailStartedEvent>(_onStarted);
    on<ReasonDetailAreasWatchedEvent>(_onWatchAreas);
    on<ReasonDetailVoicesWatchedEvent>(_onWatchVoices);
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
    final result = await deleteReasonUseCase(state.reason.id);
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
    add(const ReasonDetailAreasWatchedEvent());
    add(const ReasonDetailVoicesWatchedEvent());
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

  Future<void> _onWatchAreas(
    ReasonDetailAreasWatchedEvent event,
    Emitter<ReasonDetailState> emit,
  ) async {
    // The cached list shows at once; a background update follows (a new device may
    // have none cached yet).
    refreshAreasUseCase(NoParams());
    await emit.forEach<Either<Failure, List<AreaOfLife>>>(
      watchAreasUseCase(NoParams()),
      onData: (result) =>
          result.fold((_) => state, (areas) => state.copyWith(areas: areas)),
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
  }

  /// An area's purpose ideas, asked once per area while the screen is open (the
  /// purpose sheet and the why sheet both need them). Failures are not kept.
  final Map<int, List<PurposeSuggestion>> _purposeIdeas = {};

  Future<List<PurposeSuggestion>> _purposeIdeasOf(int areaId) async {
    final known = _purposeIdeas[areaId];
    if (known != null) return known;
    final result = await getPurposeSuggestionsUseCase(
      PurposeSuggestionsParams(areaId),
    );
    return result.fold(
      (failure) => throw failure,
      (list) => _purposeIdeas[areaId] = list,
    );
  }

  static String _purposeText(PurposeSuggestion s) =>
      clipToWord(s.text.trim(), AppConstant.purposeMaxLength);

  /// Ideas for the purpose of a reason in area [areaId] (for the purpose sheet).
  Future<List<String>> purposeSuggestions(int areaId) async => [
    for (final s in await _purposeIdeasOf(areaId)) _purposeText(s),
  ];

  /// Ideas for "why it matters", for area [areaId] and [purpose]: the ideas made for
  /// the purpose idea it reads like, or the area's general ones for the user's own words.
  Future<List<String>> whySuggestions(int areaId, String purpose) async {
    int? purposeId;
    try {
      for (final s in await _purposeIdeasOf(areaId)) {
        if (sameWords(_purposeText(s), purpose)) purposeId = s.id;
      }
    } on Failure {
      // Without the purpose ideas, the area's general ideas are asked for.
    }
    final result = await getMatterSuggestionsUseCase(
      MatterSuggestionsParams(areaId, purposeId),
    );
    return result.fold(
      (failure) => throw failure,
      (list) => [for (final s in list) s.text.trim()],
    );
  }
}
