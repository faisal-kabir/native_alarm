import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../goal_topic/domain/entities/goal_topic.dart';
import '../../../goal_topic/domain/usecases/refresh_goal_topics_usecase.dart';
import '../../../goal_topic/domain/usecases/watch_general_whys_usecase.dart';
import '../../../goal_topic/domain/usecases/watch_goal_topics_usecase.dart';
import '../../../reasons/domain/entities/new_reason.dart';
import '../../../reasons/domain/entities/reason_draft.dart';
import '../../../reasons/domain/usecases/create_reason_usecase.dart';
import '../../../sound/domain/usecases/get_sound_types_usecase.dart';
import '../../../voice/domain/entities/voice.dart';
import '../../../voice/domain/usecases/refresh_voices_usecase.dart';
import '../../../voice/domain/usecases/watch_voices_usecase.dart';
import 'create_reason_event.dart';
import 'create_reason_state.dart';

/// The BLoC of the Create Goal mother page. Every step's data lives in
/// [CreateReasonState]; the steps are pages of one PageView.
@injectable
class CreateReasonBloc extends Bloc<CreateReasonEvent, CreateReasonState> {
  final WatchGoalTopicsUseCase watchTopicsUseCase;
  final WatchGeneralWhysUseCase watchGeneralWhysUseCase;
  final RefreshGoalTopicsUseCase refreshTopicsUseCase;
  final WatchVoicesUseCase watchVoicesUseCase;
  final RefreshVoicesUseCase refreshVoicesUseCase;
  final GetSoundTypesUseCase getSoundTypesUseCase;
  final CreateReasonUseCase createReasonUseCase;

  CreateReasonBloc(
    this.watchTopicsUseCase,
    this.watchGeneralWhysUseCase,
    this.refreshTopicsUseCase,
    this.watchVoicesUseCase,
    this.refreshVoicesUseCase,
    this.getSoundTypesUseCase,
    this.createReasonUseCase,
  ) : super(const CreateReasonState()) {
    on<LoadTopicsEvent>(_onLoadTopics);
    on<RefreshTopicsEvent>(_onRefreshTopics);
    on<TopicPickedEvent>(_onTopicPicked);
    on<TopicTypedEvent>(_onTopicTyped);
    on<LoadVoicesEvent>(_onLoadVoices);
    on<RefreshVoicesEvent>(_onRefreshVoices);
    on<PurposeChangedEvent>((event, emit) {
      if (event.text != state.purpose) {
        emit(state.copyWith(purpose: event.text));
      }
    });
    on<MatterChangedEvent>((event, emit) {
      if (event.text != state.matter) emit(state.copyWith(matter: event.text));
    });
    on<LoadSoundTypesEvent>(_onLoadSoundTypes);
    on<CreateReasonSubmittedEvent>(_onSubmitted);
    on<SoundSelectedEvent>((event, emit) {
      if (!state.soundTypes.any((s) => s.id == event.soundId)) return;
      emit(state.copyWith(selectedSoundId: () => event.soundId));
    });
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

  /// Shows the saved topics (and the general whys) at once and keeps following them:
  /// when the server update below brings something new, it is written to the saved copy
  /// and these streams deliver it to the page.
  Future<void> _onLoadTopics(
    LoadTopicsEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    add(const RefreshTopicsEvent());
    await Future.wait([
      emit.forEach<Either<Failure, List<GoalTopic>>>(
        watchTopicsUseCase(NoParams()),
        onData: (result) => result.fold(
          (failure) => state.copyWith(topicsStatus: LoadStatus.failed),
          (topics) {
            // A chip the server has removed since can not stay chosen.
            final stillThere = topics.any((t) => t.id == state.selectedTopicId);
            return state.copyWith(
              topics: topics,
              selectedTopicId: stillThere ? null : () => null,
            );
          },
        ),
      ),
      emit.forEach<Either<Failure, List<String>>>(
        watchGeneralWhysUseCase(NoParams()),
        onData: (result) => result.fold(
          (failure) => state,
          (whys) => state.copyWith(generalWhys: whys),
        ),
      ),
    ]);
  }

  Future<void> _onRefreshTopics(
    RefreshTopicsEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    if (state.topics.isEmpty && state.topicsStatus == LoadStatus.failed) {
      emit(state.copyWith(topicsStatus: LoadStatus.loading));
    }
    final result = await refreshTopicsUseCase(NoParams());
    // With topics on the device a failed update is silent: they stay on screen.
    emit(
      state.copyWith(
        topicsStatus: result.fold(
          (_) => LoadStatus.failed,
          (_) => LoadStatus.loaded,
        ),
      ),
    );
  }

  /// A goal picked from the old chip's suggestions belongs to it: it goes with it when
  /// the topic changes. Text the user wrote themselves stays.
  String? _purposeAfterTopicChange(GoalTopic? before, GoalTopic? after) {
    if (before == null || before.id == after?.id) return null;
    final fromSuggestion = before.goals.any((g) => sameWords(g, state.purpose));
    return fromSuggestion ? '' : null;
  }

  void _onTopicPicked(TopicPickedEvent event, Emitter<CreateReasonState> emit) {
    final id = event.topicId;
    if (id != null && !state.topics.any((t) => t.id == id)) return;
    final before = state.chip;
    final next = state.copyWith(selectedTopicId: () => id, topicText: '');
    emit(next.copyWith(purpose: _purposeAfterTopicChange(before, next.chip)));
  }

  static final RegExp _lineBreaks = RegExp(r'[\r\n]+');
  static final RegExp _leadingSpace = RegExp(r'^\s+');
  static final RegExp _trailingStops = RegExp(r'[.!?,;:]+$');

  void _onTopicTyped(TopicTypedEvent event, Emitter<CreateReasonState> emit) {
    const max = AppConstant.reasonNameMaxLength;
    final text = event.text
        .replaceAll(_lineBreaks, ' ')
        .replaceFirst(_leadingSpace, '');
    final clipped = text.length > max ? text.substring(0, max) : text;
    final before = state.chip;
    final next = state.copyWith(
      selectedTopicId: () => null,
      topicText: clipped,
    );
    emit(next.copyWith(purpose: _purposeAfterTopicChange(before, next.chip)));
  }

  /// Same local-first flow as the topics: the saved voices show at once and follow the
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

  void _onNextStep(NextStepEvent event, Emitter<CreateReasonState> emit) {
    if (!state.canContinue) return;
    final next = state.stepIndex + 1;
    if (next >= AppConstant.createReasonStepCount) return;
    // Leaving the topic step with the person's own words: they are tidied (a trailing
    // full stop or comma is not part of a topic).
    if (state.stepIndex == CreateReasonState.topicStep && state.chip == null) {
      final tidy = state.topicText.replaceFirst(_trailingStops, '');
      emit(state.copyWith(stepIndex: next, topicText: tidy));
      return;
    }
    emit(state.copyWith(stepIndex: next));
  }

  /// Saves everything the steps collected as a new goal (named after its topic, server
  /// and device). The page opens the "ready" screen once [SaveStatus.saved].
  Future<void> _onSubmitted(
    CreateReasonSubmittedEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    final voiceId = state.selectedVoiceId;
    final sound = state.selectedSound;
    final topic = state.topic;
    if (!state.answer.ready ||
        topic.isEmpty ||
        voiceId == null ||
        sound == null ||
        state.saveStatus == SaveStatus.saving) {
      return;
    }
    emit(state.copyWith(saveStatus: SaveStatus.saving));
    final result = await createReasonUseCase(
      NewReason(
        name: topic,
        draft: ReasonDraft(
          topic: topic,
          focus: state.focus,
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
  }

  void _onPreviousStep(
    PreviousStepEvent event,
    Emitter<CreateReasonState> emit,
  ) {
    if (state.stepIndex == 0) return;
    emit(state.copyWith(stepIndex: state.stepIndex - 1));
  }
}
