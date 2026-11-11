import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/utils/load_status.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../goal_topic/domain/entities/goal_topic.dart';
import '../../../goal_topic/domain/goal_topic_search.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/domain/entities/reason_draft.dart';
import '../../../sound/domain/entities/sound_type.dart';
import '../../../voice/domain/entities/voice.dart';

// The steps' list statuses live in core; re-exported for the steps.
export '../../../../core/utils/load_status.dart';

/// Where saving the reason stands ("Create Goal" on the last step).
enum SaveStatus { idle, saving, saved, failed }

/// Everything the Create Goal flow collects, step by step, in one place: the mother
/// page's BLoC keeps it all so the last step can save the goal in one go.
class CreateReasonState extends Equatable {
  /// The steps, by their index in the page (the order of `CreateReasonPage._steps`).
  static const int topicStep = 0;
  static const int purposeStep = 1;
  static const int matterStep = 2;
  static const int voiceStep = 3;
  static const int soundStep = 4;

  /// 0-based index of the step showing now.
  final int stepIndex;

  /// Step 1 data: the topic chips (saved copy, live), the general whys (for a topic
  /// the person wrote themselves), and the answer: a tapped chip ([selectedTopicId])
  /// or the person's own words ([topicText]); never both.
  final List<GoalTopic> topics;
  final LoadStatus topicsStatus;
  final List<String> generalWhys;
  final int? selectedTopicId;
  final String topicText;

  /// Voices (saved copy, live), loaded as soon as the page opens because a later step
  /// needs them. Their `audio` and `avatar` are server paths: use `voice.audioUrl` /
  /// `voice.avatarUrl`.
  final List<Voice> voices;
  final LoadStatus voicesStatus;

  /// Step 2 data: "What are you working toward?" as the user wrote, spoke or picked it.
  final String purpose;

  /// The microphone is listening on a text step (Continue waits for it).
  final bool dictating;

  /// Step 3 data (optional): "Why does it matter to you?" as written, spoken or picked.
  final String matter;

  /// Step 4 data: the chosen voice (from [voices]).
  final int? selectedVoiceId;

  /// Step 5 data: the sound types (tones; loaded when the page opens), the chosen one
  /// (the first until the user picks) and the chosen length in seconds.
  final List<SoundType> soundTypes;
  final LoadStatus soundTypesStatus;
  final int? selectedSoundId;
  final int lengthSeconds;

  /// Saving the goal, and the saved goal (server id, name) once it is.
  final SaveStatus saveStatus;
  final Reason? createdReason;

  const CreateReasonState({
    this.stepIndex = 0,
    this.topics = const [],
    this.topicsStatus = LoadStatus.loading,
    this.generalWhys = const [],
    this.selectedTopicId,
    this.topicText = '',
    this.voices = const [],
    this.voicesStatus = LoadStatus.loading,
    this.purpose = '',
    this.dictating = false,
    this.matter = '',
    this.selectedVoiceId,
    this.soundTypes = const [],
    this.soundTypesStatus = LoadStatus.loading,
    this.selectedSoundId,
    this.lengthSeconds = AppConstant.defaultReasonLengthSeconds,
    this.saveStatus = SaveStatus.idle,
    this.createdReason,
  });

  /// The chip the answer is: the tapped one, else the one whose exact name was typed;
  /// null when the topic is the person's own words (or nothing yet).
  GoalTopic? get chip {
    for (final topic in topics) {
      if (topic.id == selectedTopicId) return topic;
    }
    return selectedTopicId != null ? null : topicNamed(topics, topicText);
  }

  /// The first step's answer, as the later steps read it.
  TopicAnswer get answer => TopicAnswer(chip: chip, text: topicText);

  /// What the goal is about, in words: the chip's label or the typed text (trimmed,
  /// at most [AppConstant.reasonNameMaxLength] characters).
  String get topic => clipToWord(answer.label, AppConstant.reasonNameMaxLength);

  /// How the goal must be spoken to.
  GoalFocus get focus => answer.gentle ? GoalFocus.gentle : GoalFocus.general;

  /// The goals the Goal step suggests: the chip's own; none for the person's own words.
  List<String> get goalSuggestions => chip?.goals ?? const [];

  /// The whys the Why step suggests: the chip's own, or the general ones.
  List<String> get whySuggestions => chip?.whys ?? generalWhys;

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

  /// On the last step the button reads "Create Goal".
  bool get isLastStep => stepIndex == AppConstant.createReasonStepCount - 1;

  Voice? get selectedVoice {
    for (final voice in voices) {
      if (voice.id == selectedVoiceId) return voice;
    }
    return null;
  }

  bool get _purposeReady {
    final text = purpose.trim();
    return text.length >= AppConstant.purposeMinLength &&
        wordCount(text) >= AppConstant.purposeMinWords;
  }

  /// Whether the current step is complete, so "Continue" is enabled.
  bool get canContinue => switch (stepIndex) {
    topicStep => answer.ready,
    purposeStep => _purposeReady && !dictating,
    matterStep => !matterTooShort && !dictating,
    voiceStep => selectedVoice != null,
    soundStep => selectedSound != null && saveStatus != SaveStatus.saving,
    _ => false,
  };

  /// How far through the flow the current step is, 0..1 (for the top progress bar).
  double get progress => (stepIndex + 1) / AppConstant.createReasonStepCount;

  CreateReasonState copyWith({
    int? stepIndex,
    List<GoalTopic>? topics,
    LoadStatus? topicsStatus,
    List<String>? generalWhys,
    int? Function()? selectedTopicId,
    String? topicText,
    List<Voice>? voices,
    LoadStatus? voicesStatus,
    String? purpose,
    bool? dictating,
    String? matter,
    int? Function()? selectedVoiceId,
    List<SoundType>? soundTypes,
    LoadStatus? soundTypesStatus,
    int? Function()? selectedSoundId,
    int? lengthSeconds,
    SaveStatus? saveStatus,
    Reason? Function()? createdReason,
  }) => CreateReasonState(
    stepIndex: stepIndex ?? this.stepIndex,
    topics: topics ?? this.topics,
    topicsStatus: topicsStatus ?? this.topicsStatus,
    generalWhys: generalWhys ?? this.generalWhys,
    selectedTopicId: selectedTopicId == null
        ? this.selectedTopicId
        : selectedTopicId(),
    topicText: topicText ?? this.topicText,
    voices: voices ?? this.voices,
    voicesStatus: voicesStatus ?? this.voicesStatus,
    purpose: purpose ?? this.purpose,
    dictating: dictating ?? this.dictating,
    matter: matter ?? this.matter,
    selectedVoiceId: selectedVoiceId == null
        ? this.selectedVoiceId
        : selectedVoiceId(),
    soundTypes: soundTypes ?? this.soundTypes,
    soundTypesStatus: soundTypesStatus ?? this.soundTypesStatus,
    selectedSoundId: selectedSoundId == null
        ? this.selectedSoundId
        : selectedSoundId(),
    lengthSeconds: lengthSeconds ?? this.lengthSeconds,
    saveStatus: saveStatus ?? this.saveStatus,
    createdReason: createdReason == null ? this.createdReason : createdReason(),
  );

  @override
  List<Object?> get props => [
    stepIndex,
    topics,
    topicsStatus,
    generalWhys,
    selectedTopicId,
    topicText,
    voices,
    voicesStatus,
    purpose,
    dictating,
    matter,
    selectedVoiceId,
    soundTypes,
    soundTypesStatus,
    selectedSoundId,
    lengthSeconds,
    saveStatus,
    createdReason,
  ];
}
