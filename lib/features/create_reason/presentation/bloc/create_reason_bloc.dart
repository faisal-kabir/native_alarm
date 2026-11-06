import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../area_of_life/domain/entities/purpose_suggestion.dart';
import '../../../area_of_life/domain/usecases/get_purpose_suggestions_usecase.dart';
import '../../../area_of_life/domain/usecases/refresh_areas_of_life_usecase.dart';
import '../../../area_of_life/domain/usecases/watch_areas_of_life_usecase.dart';
import '../../../voice/domain/entities/voice.dart';
import '../../../voice/domain/usecases/refresh_voices_usecase.dart';
import '../../../voice/domain/usecases/watch_voices_usecase.dart';
import 'create_reason_event.dart';
import 'create_reason_state.dart';

/// The BLoC of the Create Reason mother page. Every step's data lives in
/// [CreateReasonState]; the steps are pages of one PageView.
@injectable
class CreateReasonBloc extends Bloc<CreateReasonEvent, CreateReasonState> {
  /// How many step pages exist so far. Raise it by one whenever a step page is added
  /// to `CreateReasonPage` (and give `CreateReasonState.canContinue` its case).
  static const int builtStepCount = 3;

  final WatchAreasOfLifeUseCase watchAreasUseCase;
  final RefreshAreasOfLifeUseCase refreshAreasUseCase;
  final WatchVoicesUseCase watchVoicesUseCase;
  final RefreshVoicesUseCase refreshVoicesUseCase;
  final GetPurposeSuggestionsUseCase getPurposeSuggestionsUseCase;

  CreateReasonBloc(
    this.watchAreasUseCase,
    this.refreshAreasUseCase,
    this.watchVoicesUseCase,
    this.refreshVoicesUseCase,
    this.getPurposeSuggestionsUseCase,
  ) : super(const CreateReasonState()) {
    on<LoadVoicesEvent>(_onLoadVoices);
    on<RefreshVoicesEvent>(_onRefreshVoices);
    on<LoadSuggestionsEvent>(_onLoadSuggestions);
    on<LoadAreasEvent>(_onLoadAreas);
    on<RefreshAreasEvent>(_onRefreshAreas);
    on<AreaSelectedEvent>(_onAreaSelected);
    on<PurposeChangedEvent>(_onPurposeChanged);
    on<SuggestionPickedEvent>(_onSuggestionPicked);
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
        purposeSuggestion: fromSuggestion ? () => null : null,
      ),
    );
  }

  /// Any change that makes the text differ from the picked suggestion turns it into
  /// the user's own text (the flag the next steps use).
  void _onPurposeChanged(
    PurposeChangedEvent event,
    Emitter<CreateReasonState> emit,
  ) {
    if (event.text == state.purpose) return;
    final quote = state.purposeSuggestion;
    final unchanged = quote != null && event.text.trim() == _pickText(quote);
    emit(
      state.copyWith(
        purpose: event.text,
        purposeSuggestion: unchanged ? null : () => null,
      ),
    );
  }

  void _onSuggestionPicked(
    SuggestionPickedEvent event,
    Emitter<CreateReasonState> emit,
  ) {
    for (final quote in state.suggestions) {
      if (quote.id == event.quoteId) {
        emit(
          state.copyWith(
            purpose: _pickText(quote),
            purposeSuggestion: () => quote,
          ),
        );
        return;
      }
    }
  }

  /// The text a picked suggestion puts in the field (within the length limit).
  static String _pickText(PurposeSuggestion quote) =>
      clipToWord(quote.text.trim(), AppConstant.purposeMaxLength);

  void _onNextStep(NextStepEvent event, Emitter<CreateReasonState> emit) {
    if (!state.canContinue) return;
    // Leaving the area step: get the suggestions of the chosen area ready for the next step
    // (unless this very area's suggestions are already on their way).
    final areaId = state.selectedAreaId;
    if (state.stepIndex == 0 &&
        areaId != null &&
        !(state.suggestionsAreaId == areaId &&
            state.suggestionsStatus == LoadStatus.loading)) {
      add(LoadSuggestionsEvent(areaId));
    }
    final next = state.stepIndex + 1;
    if (next >= builtStepCount) return;
    emit(state.copyWith(stepIndex: next));
  }

  void _onPreviousStep(
    PreviousStepEvent event,
    Emitter<CreateReasonState> emit,
  ) {
    if (state.stepIndex == 0) return;
    emit(state.copyWith(stepIndex: state.stepIndex - 1));
  }
}
