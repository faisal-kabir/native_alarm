import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../area_of_life/domain/entities/purpose_suggestion.dart';
import '../../../voice/domain/entities/voice.dart';

/// Where a list loaded from the server stands (only matters while there is nothing to
/// show yet).
enum LoadStatus {
  /// Waiting for the first answer from the server.
  loading,

  /// The server answered and the areas are up to date.
  loaded,

  /// The server could not be reached and nothing is available to show.
  failed,
}

/// Everything the Create Reason flow collects, step by step, in one place: the mother
/// page's BLoC keeps it all so the last step can save the reason in one go.
class CreateReasonState extends Equatable {
  /// 0-based index of the step showing now.
  final int stepIndex;

  /// Voices (saved copy, live), loaded as soon as the page opens because a later step
  /// needs them. Their `audio` and `avatar` are server paths: use `voice.audioUrl` /
  /// `voice.avatarUrl`.
  final List<Voice> voices;
  final LoadStatus voicesStatus;

  /// The purpose suggestions of area [suggestionsAreaId], loaded when the user continues from the area
  /// step. Never saved on the device: they are fully dynamic. Only use [areaSuggestions] while
  /// [suggestionsAreaId] is the selected area.
  final List<PurposeSuggestion> areaSuggestions;
  final int? suggestionsAreaId;
  final LoadStatus suggestionsStatus;

  /// Step 1 data: the areas of life (saved copy, live) and the user's choice.
  final List<AreaOfLife> areas;
  final LoadStatus areasStatus;
  final int? selectedAreaId;

  /// Step 2 data: "What are you working toward?" as the user wrote, spoke or picked it.
  final String purpose;

  /// The suggestion whose text is in [purpose] **unchanged**. Null as soon as
  /// the user types, speaks or edits: see [purposeFromSuggestion].
  final PurposeSuggestion? purposeSuggestion;

  /// The microphone is listening on the purpose step (Continue waits for it).
  final bool dictating;

  /// Step 3 data: the chosen voice (from [voices]).
  final int? selectedVoiceId;

  const CreateReasonState({
    this.stepIndex = 0,
    this.areas = const [],
    this.areasStatus = LoadStatus.loading,
    this.selectedAreaId,
    this.voices = const [],
    this.voicesStatus = LoadStatus.loading,
    this.areaSuggestions = const [],
    this.suggestionsAreaId,
    this.suggestionsStatus = LoadStatus.loading,
    this.purpose = '',
    this.purposeSuggestion,
    this.dictating = false,
    this.selectedVoiceId,
  });

  Voice? get selectedVoice {
    for (final voice in voices) {
      if (voice.id == selectedVoiceId) return voice;
    }
    return null;
  }

  /// True when the purpose is exactly a picked suggestion; false when the user wrote it
  /// (typed or spoken) or changed a picked suggestion. The next steps suggest
  /// differently for the two cases.
  bool get purposeFromSuggestion => purposeSuggestion != null;

  /// The suggestions to show on the purpose step: only those of the selected area.
  List<PurposeSuggestion> get suggestions =>
      suggestionsAreaId == selectedAreaId ? areaSuggestions : const [];

  bool get _purposeReady {
    final text = purpose.trim();
    return text.length >= AppConstant.purposeMinLength &&
        wordCount(text) >= AppConstant.purposeMinWords;
  }

  AreaOfLife? get selectedArea {
    for (final area in areas) {
      if (area.id == selectedAreaId) return area;
    }
    return null;
  }

  /// Whether the current step is complete, so "Continue" is enabled.
  bool get canContinue => switch (stepIndex) {
    0 => selectedArea != null,
    1 => _purposeReady && !dictating,
    2 => selectedVoice != null,
    _ => false,
  };

  /// How far through the flow the current step is, 0..1 (for the top progress bar).
  double get progress => (stepIndex + 1) / AppConstant.createReasonStepCount;

  CreateReasonState copyWith({
    int? stepIndex,
    List<AreaOfLife>? areas,
    LoadStatus? areasStatus,
    int? Function()? selectedAreaId,
    List<Voice>? voices,
    LoadStatus? voicesStatus,
    List<PurposeSuggestion>? areaSuggestions,
    int? Function()? suggestionsAreaId,
    LoadStatus? suggestionsStatus,
    String? purpose,
    PurposeSuggestion? Function()? purposeSuggestion,
    bool? dictating,
    int? Function()? selectedVoiceId,
  }) => CreateReasonState(
    stepIndex: stepIndex ?? this.stepIndex,
    areas: areas ?? this.areas,
    areasStatus: areasStatus ?? this.areasStatus,
    selectedAreaId: selectedAreaId == null
        ? this.selectedAreaId
        : selectedAreaId(),
    voices: voices ?? this.voices,
    voicesStatus: voicesStatus ?? this.voicesStatus,
    areaSuggestions: areaSuggestions ?? this.areaSuggestions,
    suggestionsAreaId: suggestionsAreaId == null
        ? this.suggestionsAreaId
        : suggestionsAreaId(),
    suggestionsStatus: suggestionsStatus ?? this.suggestionsStatus,
    purpose: purpose ?? this.purpose,
    purposeSuggestion: purposeSuggestion == null
        ? this.purposeSuggestion
        : purposeSuggestion(),
    dictating: dictating ?? this.dictating,
    selectedVoiceId: selectedVoiceId == null
        ? this.selectedVoiceId
        : selectedVoiceId(),
  );

  @override
  List<Object?> get props => [
    stepIndex,
    areas,
    areasStatus,
    selectedAreaId,
    voices,
    voicesStatus,
    areaSuggestions,
    suggestionsAreaId,
    suggestionsStatus,
    purpose,
    purposeSuggestion,
    dictating,
    selectedVoiceId,
  ];
}
