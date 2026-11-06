import 'package:equatable/equatable.dart';

abstract class CreateReasonEvent extends Equatable {
  const CreateReasonEvent();

  @override
  List<Object?> get props => [];
}

/// The page opened: show the saved areas of life and start updating them from the
/// server.
class LoadAreasEvent extends CreateReasonEvent {
  const LoadAreasEvent();
}

/// Ask the server for the areas again (the "Try again" button).
class RefreshAreasEvent extends CreateReasonEvent {
  const RefreshAreasEvent();
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

/// Load the purpose suggestions of [areaId] from the server (sent on "Continue" from the area step).
class LoadSuggestionsEvent extends CreateReasonEvent {
  final int areaId;

  const LoadSuggestionsEvent(this.areaId);

  @override
  List<Object?> get props => [areaId];
}

/// The user chose an area of life.
class AreaSelectedEvent extends CreateReasonEvent {
  final int areaId;

  const AreaSelectedEvent(this.areaId);

  @override
  List<Object?> get props => [areaId];
}

/// "Continue": go to the next step.
class NextStepEvent extends CreateReasonEvent {
  const NextStepEvent();
}

/// Back (button or system gesture) while not on the first step.
class PreviousStepEvent extends CreateReasonEvent {
  const PreviousStepEvent();
}

/// The purpose text changed in the field (typed, spoken, or set by a pick).
class PurposeChangedEvent extends CreateReasonEvent {
  final String text;

  const PurposeChangedEvent(this.text);

  @override
  List<Object?> get props => [text];
}

/// The user tapped a suggestion: its text becomes the purpose.
class SuggestionPickedEvent extends CreateReasonEvent {
  final int quoteId;

  const SuggestionPickedEvent(this.quoteId);

  @override
  List<Object?> get props => [quoteId];
}

/// The microphone started or stopped listening on the purpose step.
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

/// Load the "why it matters" suggestions of [areaId] for purpose suggestion
/// [purposeSuggestionId] (null: the user wrote their own purpose). Sent on "Continue"
/// from the purpose step.
class LoadMatterSuggestionsEvent extends CreateReasonEvent {
  final int areaId;
  final int? purposeSuggestionId;

  const LoadMatterSuggestionsEvent(this.areaId, this.purposeSuggestionId);

  @override
  List<Object?> get props => [areaId, purposeSuggestionId];
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

/// Load the example line of [areaId] in sound [soundId] ("Try again" too).
class LoadSoundQuoteEvent extends CreateReasonEvent {
  final int areaId;
  final int soundId;

  const LoadSoundQuoteEvent(this.areaId, this.soundId);

  @override
  List<Object?> get props => [areaId, soundId];
}

/// The user chose a length (seconds).
class LengthSelectedEvent extends CreateReasonEvent {
  final int seconds;

  const LengthSelectedEvent(this.seconds);

  @override
  List<Object?> get props => [seconds];
}

/// "Create Reason" on the last step: save the reason.
class CreateReasonSubmittedEvent extends CreateReasonEvent {
  const CreateReasonSubmittedEvent();
}
