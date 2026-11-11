import 'package:equatable/equatable.dart';

abstract class CreateReasonEvent extends Equatable {
  const CreateReasonEvent();

  @override
  List<Object?> get props => [];
}

/// The page opened: show the saved topics (and the general whys) and start updating
/// them from the server.
class LoadTopicsEvent extends CreateReasonEvent {
  const LoadTopicsEvent();
}

/// Ask the server for the topics again (the "Try again" button).
class RefreshTopicsEvent extends CreateReasonEvent {
  const RefreshTopicsEvent();
}

/// The page opened: show the saved voices and start updating them from the server.
/// Voices are needed by a later step, so they are ready before the user gets there.
class LoadVoicesEvent extends CreateReasonEvent {
  const LoadVoicesEvent();
}

/// Ask the server for the voices again.
class RefreshVoicesEvent extends CreateReasonEvent {
  const RefreshVoicesEvent();
}

/// The user tapped a chip ([topicId]) or tapped the chosen one again (null): the
/// answer to "What do you want to wake up for?" is that chip, and any typed text goes.
class TopicPickedEvent extends CreateReasonEvent {
  final int? topicId;

  const TopicPickedEvent(this.topicId);

  @override
  List<Object?> get props => [topicId];
}

/// The user typed (or cleared) their own words as the topic: any chip goes. Typing a
/// chip's exact name is that chip.
class TopicTypedEvent extends CreateReasonEvent {
  final String text;

  const TopicTypedEvent(this.text);

  @override
  List<Object?> get props => [text];
}

/// "Continue": go to the next step.
class NextStepEvent extends CreateReasonEvent {
  const NextStepEvent();
}

/// Back (button or system gesture) while not on the first step.
class PreviousStepEvent extends CreateReasonEvent {
  const PreviousStepEvent();
}

/// The goal text changed in the field (typed, spoken, or set by a pick).
class PurposeChangedEvent extends CreateReasonEvent {
  final String text;

  const PurposeChangedEvent(this.text);

  @override
  List<Object?> get props => [text];
}

/// The microphone started or stopped listening on a text step.
class DictationChangedEvent extends CreateReasonEvent {
  final bool listening;

  const DictationChangedEvent(this.listening);

  @override
  List<Object?> get props => [listening];
}

/// The user chose a voice (tapping its row or its play button).
class VoiceSelectedEvent extends CreateReasonEvent {
  final int voiceId;

  const VoiceSelectedEvent(this.voiceId);

  @override
  List<Object?> get props => [voiceId];
}

/// The "why it matters" text changed in the field (typed, spoken, or a pick).
class MatterChangedEvent extends CreateReasonEvent {
  final String text;

  const MatterChangedEvent(this.text);

  @override
  List<Object?> get props => [text];
}

/// The page opened: load the sound types (the last step needs them).
class LoadSoundTypesEvent extends CreateReasonEvent {
  const LoadSoundTypesEvent();
}

/// The user chose a sound type.
class SoundSelectedEvent extends CreateReasonEvent {
  final int soundId;

  const SoundSelectedEvent(this.soundId);

  @override
  List<Object?> get props => [soundId];
}

/// The user chose a length (seconds).
class LengthSelectedEvent extends CreateReasonEvent {
  final int seconds;

  const LengthSelectedEvent(this.seconds);

  @override
  List<Object?> get props => [seconds];
}

/// "Create Goal" on the last step: save the goal.
class CreateReasonSubmittedEvent extends CreateReasonEvent {
  const CreateReasonSubmittedEvent();
}
