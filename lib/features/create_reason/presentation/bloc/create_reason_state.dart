import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/utils/load_status.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../area_of_life/domain/entities/matter_suggestion.dart';
import '../../../area_of_life/domain/entities/purpose_suggestion.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../sound/domain/entities/sound_quote.dart';
import '../../../sound/domain/entities/sound_type.dart';
import '../../../voice/domain/entities/voice.dart';

// The steps' list statuses live in core; re-exported for the steps.
export '../../../../core/utils/load_status.dart';

/// Where saving the reason stands ("Create Reason" on the last step).
enum SaveStatus { idle, saving, saved, failed }

/// Everything the Create Reason flow collects, step by step, in one place: the mother
/// page's BLoC keeps it all so the last step can save the reason in one go.
class CreateReasonState extends Equatable {
  /// The steps, by their index in the page (the order of `CreateReasonPage._steps`).
  static const int areaStep = 0;
  static const int purposeStep = 1;
  static const int voiceStep = 2;
  static const int matterStep = 3;
  static const int soundStep = 4;

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

  /// The microphone is listening on the purpose step (Continue waits for it).
  final bool dictating;

  /// Step 3 data: the chosen voice (from [voices]).
  final int? selectedVoiceId;

  /// Step 4 data (optional): "Why does it matter to you?" as written, spoken or picked.
  final String matter;

  /// The "why it matters" suggestions loaded for [matterSuggestionsFor] (area id, picked
  /// purpose suggestion id or null), when the user continued from the purpose step.
  /// Never saved on the device. Use [matterSuggestionsShown].
  final List<MatterSuggestion> matterSuggestions;
  final (int, int?)? matterSuggestionsFor;
  final LoadStatus matterSuggestionsStatus;

  /// Step 5 data: the sound types (loaded when the page opens), the chosen one (the
  /// first until the user picks), the example line for [soundQuoteFor] (area id, sound
  /// id; loaded fresh every time, never saved) and the chosen length in seconds.
  final List<SoundType> soundTypes;
  final LoadStatus soundTypesStatus;
  final int? selectedSoundId;
  final SoundQuote? soundQuote;
  final (int, int)? soundQuoteFor;
  final LoadStatus soundQuoteStatus;
  final int lengthSeconds;

  /// Saving the reason, and the saved reason (server id, unique name) once it is.
  final SaveStatus saveStatus;
  final Reason? createdReason;

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
    this.dictating = false,
    this.selectedVoiceId,
    this.matter = '',
    this.matterSuggestions = const [],
    this.matterSuggestionsFor,
    this.matterSuggestionsStatus = LoadStatus.loading,
    this.soundTypes = const [],
    this.soundTypesStatus = LoadStatus.loading,
    this.selectedSoundId,
    this.soundQuote,
    this.soundQuoteFor,
    this.soundQuoteStatus = LoadStatus.loading,
    this.lengthSeconds = AppConstant.defaultReasonLengthSeconds,
    this.saveStatus = SaveStatus.idle,
    this.createdReason,
  });

  /// What the "why it matters" suggestions must be loaded for now: the selected area
  /// and the picked purpose suggestion (null when the purpose is the user's own).
  (int, int?)? get matterSuggestionsKey {
    final areaId = selectedAreaId;
    return areaId == null ? null : (areaId, purposeSuggestion?.id);
  }

  /// The "why it matters" suggestions for the current area and purpose only.
  List<MatterSuggestion> get matterSuggestionsShown =>
      matterSuggestionsFor == matterSuggestionsKey
      ? matterSuggestions
      : const [];

  /// The optional "why it matters" text is started but still too short to keep.
  bool get matterTooShort {
    final text = matter.trim();
    return text.isNotEmpty && text.length < AppConstant.matterMinLength;
  }

  /// On the optional step with nothing written, "Continue" reads "Skip for now".
  bool get continueSkips => stepIndex == matterStep && matter.trim().isEmpty;

  /// The chosen sound type: the picked one, else the first.
  SoundType? get selectedSound {
    for (final sound in soundTypes) {
      if (sound.id == selectedSoundId) return sound;
    }
    return soundTypes.isEmpty ? null : soundTypes.first;
  }

  /// What the example line must be loaded for now: the selected area and sound.
  (int, int)? get soundQuoteKey {
    final areaId = selectedAreaId;
    final soundId = selectedSound?.id;
    return areaId == null || soundId == null ? null : (areaId, soundId);
  }

  /// The example line for the current area and sound only.
  SoundQuote? get soundQuoteShown =>
      soundQuoteFor == soundQuoteKey ? soundQuote : null;

  /// On the last step the button reads "Create Reason".
  bool get isLastStep => stepIndex == AppConstant.createReasonStepCount - 1;

  Voice? get selectedVoice {
    for (final voice in voices) {
      if (voice.id == selectedVoiceId) return voice;
    }
    return null;
  }

  /// The suggestion whose text the purpose is right now, however it got there: picked,
  /// or typed / spoken / edited until it reads the same (spaces and letter case aside).
  /// Null when the text matches none of the selected area's suggestions.
  PurposeSuggestion? get purposeSuggestion {
    if (purpose.trim().isEmpty) return null;
    for (final suggestion in suggestions) {
      if (sameWords(suggestionText(suggestion), purpose)) return suggestion;
    }
    return null;
  }

  /// True when the purpose is one of the suggestions (see [purposeSuggestion]); false
  /// when it is the user's own text. The next steps suggest differently for the two.
  bool get purposeFromSuggestion => purposeSuggestion != null;

  /// The text a suggestion puts in the field (within the length limit).
  static String suggestionText(PurposeSuggestion suggestion) =>
      clipToWord(suggestion.text.trim(), AppConstant.purposeMaxLength);

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
    areaStep => selectedArea != null,
    purposeStep => _purposeReady && !dictating,
    voiceStep => selectedVoice != null,
    matterStep => !matterTooShort && !dictating,
    soundStep => selectedSound != null && saveStatus != SaveStatus.saving,
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
    bool? dictating,
    int? Function()? selectedVoiceId,
    String? matter,
    List<MatterSuggestion>? matterSuggestions,
    (int, int?)? Function()? matterSuggestionsFor,
    LoadStatus? matterSuggestionsStatus,
    List<SoundType>? soundTypes,
    LoadStatus? soundTypesStatus,
    int? Function()? selectedSoundId,
    SoundQuote? Function()? soundQuote,
    (int, int)? Function()? soundQuoteFor,
    LoadStatus? soundQuoteStatus,
    int? lengthSeconds,
    SaveStatus? saveStatus,
    Reason? Function()? createdReason,
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
    dictating: dictating ?? this.dictating,
    selectedVoiceId: selectedVoiceId == null
        ? this.selectedVoiceId
        : selectedVoiceId(),
    matter: matter ?? this.matter,
    matterSuggestions: matterSuggestions ?? this.matterSuggestions,
    matterSuggestionsFor: matterSuggestionsFor == null
        ? this.matterSuggestionsFor
        : matterSuggestionsFor(),
    matterSuggestionsStatus:
        matterSuggestionsStatus ?? this.matterSuggestionsStatus,
    soundTypes: soundTypes ?? this.soundTypes,
    soundTypesStatus: soundTypesStatus ?? this.soundTypesStatus,
    selectedSoundId: selectedSoundId == null
        ? this.selectedSoundId
        : selectedSoundId(),
    soundQuote: soundQuote == null ? this.soundQuote : soundQuote(),
    soundQuoteFor: soundQuoteFor == null ? this.soundQuoteFor : soundQuoteFor(),
    soundQuoteStatus: soundQuoteStatus ?? this.soundQuoteStatus,
    lengthSeconds: lengthSeconds ?? this.lengthSeconds,
    saveStatus: saveStatus ?? this.saveStatus,
    createdReason: createdReason == null ? this.createdReason : createdReason(),
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
    dictating,
    selectedVoiceId,
    matter,
    matterSuggestions,
    matterSuggestionsFor,
    matterSuggestionsStatus,
    soundTypes,
    soundTypesStatus,
    selectedSoundId,
    soundQuote,
    soundQuoteFor,
    soundQuoteStatus,
    lengthSeconds,
    saveStatus,
    createdReason,
  ];
}
