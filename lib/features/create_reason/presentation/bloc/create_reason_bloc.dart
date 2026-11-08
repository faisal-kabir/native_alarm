import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../area_of_life/domain/usecases/get_matter_suggestions_usecase.dart';
import '../../../area_of_life/domain/usecases/get_purpose_suggestions_usecase.dart';
import '../../../area_of_life/domain/usecases/refresh_areas_of_life_usecase.dart';
import '../../../area_of_life/domain/usecases/watch_areas_of_life_usecase.dart';
import '../../../reasons/domain/entities/new_reason.dart';
import '../../../reasons/domain/entities/reason_draft.dart';
import '../../../reasons/domain/usecases/create_reason_usecase.dart';
import '../../../sound/domain/usecases/get_sound_quote_usecase.dart';
import '../../../sound/domain/usecases/get_sound_types_usecase.dart';
import '../../../voice/domain/entities/voice.dart';
import '../../../voice/domain/usecases/refresh_voices_usecase.dart';
import '../../../voice/domain/usecases/watch_voices_usecase.dart';
import 'create_reason_event.dart';
import 'create_reason_state.dart';

/// The BLoC of the Create Reason mother page. Every step's data lives in
/// [CreateReasonState]; the steps are pages of one PageView.
@injectable
class CreateReasonBloc extends Bloc<CreateReasonEvent, CreateReasonState> {
  final WatchAreasOfLifeUseCase watchAreasUseCase;
  final RefreshAreasOfLifeUseCase refreshAreasUseCase;
  final WatchVoicesUseCase watchVoicesUseCase;
  final RefreshVoicesUseCase refreshVoicesUseCase;
  final GetPurposeSuggestionsUseCase getPurposeSuggestionsUseCase;
  final GetMatterSuggestionsUseCase getMatterSuggestionsUseCase;
  final GetSoundTypesUseCase getSoundTypesUseCase;
  final GetSoundQuoteUseCase getSoundQuoteUseCase;
  final CreateReasonUseCase createReasonUseCase;

  CreateReasonBloc(
    this.watchAreasUseCase,
    this.refreshAreasUseCase,
    this.watchVoicesUseCase,
    this.refreshVoicesUseCase,
    this.getPurposeSuggestionsUseCase,
    this.getMatterSuggestionsUseCase,
    this.getSoundTypesUseCase,
    this.getSoundQuoteUseCase,
    this.createReasonUseCase,
  ) : super(const CreateReasonState()) {
    on<LoadVoicesEvent>(_onLoadVoices);
    on<RefreshVoicesEvent>(_onRefreshVoices);
    on<LoadSuggestionsEvent>(_onLoadSuggestions);
    on<LoadAreasEvent>(_onLoadAreas);
    on<RefreshAreasEvent>(_onRefreshAreas);
    on<AreaSelectedEvent>(_onAreaSelected);
    on<PurposeChangedEvent>(_onPurposeChanged);
    on<SuggestionPickedEvent>(_onSuggestionPicked);
    on<MatterChangedEvent>((event, emit) {
      if (event.text != state.matter) emit(state.copyWith(matter: event.text));
    });
    on<LoadMatterSuggestionsEvent>(_onLoadMatterSuggestions);
    on<LoadSoundTypesEvent>(_onLoadSoundTypes);
    on<CreateReasonSubmittedEvent>(_onSubmitted);
    on<SoundSelectedEvent>((event, emit) {
      if (!state.soundTypes.any((s) => s.id == event.soundId)) return;
      emit(state.copyWith(selectedSoundId: () => event.soundId));
      _ensureSoundQuote();
    });
    on<LoadSoundQuoteEvent>(_onLoadSoundQuote);
    on<LengthSelectedEvent>((event, emit) {
      if (AppConstant.reasonLengthsSeconds.contains(event.seconds)) {
        emit(state.copyWith(lengthSeconds: event.seconds));
      }
    });
    on<VoiceSelectedEvent>((event, emit) {
      if (!state.voices.any((v) => v.id == event.voiceId)) return;
      emit(state.copyWith(selectedVoiceId: () => event.voiceId));
    });
    on<DictationChangedEvent>(
      (event, emit) => emit(state.copyWith(dictating: event.listening)),
    );
    on<NextStepEvent>(_onNextStep);
    on<PreviousStepEvent>(_onPreviousStep);
  }

  /// Shows the saved areas at once and keeps following them: when the server update
  /// below brings something new, it is written to the saved copy and this stream
  /// delivers it to the page.
  Future<void> _onLoadAreas(
    LoadAreasEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    add(const RefreshAreasEvent());
    await emit.forEach<Either<Failure, List<AreaOfLife>>>(
      watchAreasUseCase(NoParams()),
      onData: (result) => result.fold(
        (failure) => state.copyWith(areasStatus: LoadStatus.failed),
        (areas) {
          // A choice the server has removed since can not stay chosen.
          final stillThere = areas.any((a) => a.id == state.selectedAreaId);
          return state.copyWith(
            areas: areas,
            selectedAreaId: stillThere ? null : () => null,
          );
        },
      ),
    );
  }

  Future<void> _onRefreshAreas(
    RefreshAreasEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    if (state.areas.isEmpty && state.areasStatus == LoadStatus.failed) {
      emit(state.copyWith(areasStatus: LoadStatus.loading));
    }
    final result = await refreshAreasUseCase(NoParams());
    // With areas on the device a failed update is silent: they stay on screen.
    emit(
      state.copyWith(
        areasStatus: result.fold(
          (_) => LoadStatus.failed,
          (_) => LoadStatus.loaded,
        ),
      ),
    );
  }

  /// Same local-first flow as the areas: the saved voices show at once and follow the
  /// server update that runs behind them.
  Future<void> _onLoadVoices(
    LoadVoicesEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    add(const RefreshVoicesEvent());
    await emit.forEach<Either<Failure, List<Voice>>>(
      watchVoicesUseCase(NoParams()),
      onData: (result) => result.fold(
        (failure) => state.copyWith(voicesStatus: LoadStatus.failed),
        (voices) {
          // A choice the server has removed since can not stay chosen.
          final stillThere = voices.any((v) => v.id == state.selectedVoiceId);
          return state.copyWith(
            voices: voices,
            selectedVoiceId: stillThere ? null : () => null,
          );
        },
      ),
    );
  }

  Future<void> _onRefreshVoices(
    RefreshVoicesEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    if (state.voices.isEmpty && state.voicesStatus == LoadStatus.failed) {
      emit(state.copyWith(voicesStatus: LoadStatus.loading));
    }
    final result = await refreshVoicesUseCase(NoParams());
    emit(
      state.copyWith(
        voicesStatus: result.fold(
          (_) => LoadStatus.failed,
          (_) => LoadStatus.loaded,
        ),
      ),
    );
  }

  /// The suggestions are not saved anywhere, so every call asks the server. Starting for
  /// another area clears the old suggestions first, and an answer for an area that is no
  /// longer the current one (the user went back and chose differently) is dropped.
  Future<void> _onLoadSuggestions(
    LoadSuggestionsEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    emit(
      state.copyWith(
        areaSuggestions: const [],
        suggestionsAreaId: () => event.areaId,
        suggestionsStatus: LoadStatus.loading,
      ),
    );
    final result = await getPurposeSuggestionsUseCase(
      PurposeSuggestionsParams(event.areaId),
    );
    if (state.suggestionsAreaId != event.areaId) return;
    result.fold(
      (failure) => emit(state.copyWith(suggestionsStatus: LoadStatus.failed)),
      (areaSuggestions) => emit(
        state.copyWith(
          areaSuggestions: areaSuggestions,
          suggestionsStatus: LoadStatus.loaded,
        ),
      ),
    );
  }

  void _onAreaSelected(
    AreaSelectedEvent event,
    Emitter<CreateReasonState> emit,
  ) {
    if (!state.areas.any((a) => a.id == event.areaId)) return;
    if (event.areaId == state.selectedAreaId) return;
    // A picked suggestion belongs to the old area: it goes with it. Text the user
    // wrote themselves stays.
    final fromSuggestion = state.purposeFromSuggestion;
    emit(
      state.copyWith(
        selectedAreaId: () => event.areaId,
        purpose: fromSuggestion ? '' : null,
      ),
    );
  }

  /// Whether the text is a suggestion is worked out from the text itself
  /// (`CreateReasonState.purposeSuggestion`), so typing it back counts too.
  void _onPurposeChanged(
    PurposeChangedEvent event,
    Emitter<CreateReasonState> emit,
  ) {
    if (event.text != state.purpose) emit(state.copyWith(purpose: event.text));
  }

  void _onSuggestionPicked(
    SuggestionPickedEvent event,
    Emitter<CreateReasonState> emit,
  ) {
    for (final suggestion in state.suggestions) {
      if (suggestion.id == event.suggestionId) {
        emit(
          state.copyWith(purpose: CreateReasonState.suggestionText(suggestion)),
        );
        return;
      }
    }
  }

  /// Like the purpose suggestions: never saved, every call asks the server, the old
  /// ones are cleared first, and a late answer for another key is dropped.
  Future<void> _onLoadMatterSuggestions(
    LoadMatterSuggestionsEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    final key = (event.areaId, event.purposeSuggestionId);
    emit(
      state.copyWith(
        matterSuggestions: const [],
        matterSuggestionsFor: () => key,
        matterSuggestionsStatus: LoadStatus.loading,
      ),
    );
    final result = await getMatterSuggestionsUseCase(
      MatterSuggestionsParams(event.areaId, event.purposeSuggestionId),
    );
    if (state.matterSuggestionsFor != key) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(matterSuggestionsStatus: LoadStatus.failed)),
      (suggestions) => emit(
        state.copyWith(
          matterSuggestions: suggestions,
          matterSuggestionsStatus: LoadStatus.loaded,
        ),
      ),
    );
  }

  void _onNextStep(NextStepEvent event, Emitter<CreateReasonState> emit) {
    if (!state.canContinue) return;
    // Leaving the area step: get the suggestions of the chosen area ready for the next step
    // (unless this very area's suggestions are already on their way).
    final areaId = state.selectedAreaId;
    if (state.stepIndex == CreateReasonState.areaStep &&
        areaId != null &&
        !(state.suggestionsAreaId == areaId &&
            state.suggestionsStatus == LoadStatus.loading)) {
      add(LoadSuggestionsEvent(areaId));
    }
    // Leaving the purpose step: get the "why it matters" suggestions ready for the
    // area and the purpose (its picked suggestion, or none when it is the user's own).
    final matterKey = state.matterSuggestionsKey;
    if (state.stepIndex == CreateReasonState.purposeStep &&
        matterKey != null &&
        !(state.matterSuggestionsFor == matterKey &&
            state.matterSuggestionsStatus == LoadStatus.loading)) {
      add(LoadMatterSuggestionsEvent(matterKey.$1, matterKey.$2));
    }
    final next = state.stepIndex + 1;
    if (next >= AppConstant.createReasonStepCount) return;
    emit(state.copyWith(stepIndex: next));
    if (next == CreateReasonState.soundStep) _ensureSoundQuote();
  }

  /// Saves everything the steps collected as a new reason (unique name, server and
  /// device). The page opens the "ready" screen once [SaveStatus.saved].
  Future<void> _onSubmitted(
    CreateReasonSubmittedEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    final area = state.selectedArea;
    final voiceId = state.selectedVoiceId;
    final sound = state.selectedSound;
    if (area == null ||
        voiceId == null ||
        sound == null ||
        state.saveStatus == SaveStatus.saving) {
      return;
    }
    emit(state.copyWith(saveStatus: SaveStatus.saving));
    final result = await createReasonUseCase(
      NewReason(
        baseName: area.name.trim().isEmpty ? area.title : area.name,
        draft: ReasonDraft(
          areaId: area.id,
          purpose: state.purpose.trim(),
          why: state.matter.trim(),
          soundTypeId: sound.id,
          voiceId: voiceId,
          lengthSeconds: state.lengthSeconds,
        ),
      ),
    );
    result.fold(
      (failure) => emit(state.copyWith(saveStatus: SaveStatus.failed)),
      (reason) => emit(
        state.copyWith(
          saveStatus: SaveStatus.saved,
          createdReason: () => reason,
        ),
      ),
    );
  }

  Future<void> _onLoadSoundTypes(
    LoadSoundTypesEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    emit(state.copyWith(soundTypesStatus: LoadStatus.loading));
    final result = await getSoundTypesUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(soundTypesStatus: LoadStatus.failed)),
      (sounds) {
        // The first sound is chosen until the user picks one.
        final keep = sounds.any((s) => s.id == state.selectedSoundId);
        emit(
          state.copyWith(
            soundTypes: sounds,
            soundTypesStatus: LoadStatus.loaded,
            selectedSoundId: keep
                ? null
                : () => sounds.isEmpty ? null : sounds.first.id,
          ),
        );
      },
    );
    if (state.stepIndex == CreateReasonState.soundStep) _ensureSoundQuote();
  }

  /// Asks for the example line of the current area and sound unless it is already
  /// there or on its way.
  void _ensureSoundQuote() {
    final key = state.soundQuoteKey;
    if (key == null) return;
    if (state.soundQuoteFor == key &&
        state.soundQuoteStatus != LoadStatus.failed) {
      return;
    }
    add(LoadSoundQuoteEvent(key.$1, key.$2));
  }

  /// Never saved: every sound change asks the server; a late answer for another area
  /// or sound is dropped.
  Future<void> _onLoadSoundQuote(
    LoadSoundQuoteEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    final key = (event.areaId, event.soundId);
    emit(
      state.copyWith(
        soundQuote: () => null,
        soundQuoteFor: () => key,
        soundQuoteStatus: LoadStatus.loading,
      ),
    );
    final result = await getSoundQuoteUseCase(
      SoundQuoteParams(event.areaId, event.soundId),
    );
    if (state.soundQuoteFor != key) return;
    result.fold(
      (failure) => emit(state.copyWith(soundQuoteStatus: LoadStatus.failed)),
      (quote) => emit(
        state.copyWith(
          soundQuote: () => quote,
          soundQuoteStatus: LoadStatus.loaded,
        ),
      ),
    );
  }

  void _onPreviousStep(
    PreviousStepEvent event,
    Emitter<CreateReasonState> emit,
  ) {
    if (state.stepIndex == 0) return;
    emit(state.copyWith(stepIndex: state.stepIndex - 1));
  }
}
