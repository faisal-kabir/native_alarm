import 'package:equatable/equatable.dart';

import '../../../reasons/domain/entities/reason_draft.dart';

abstract class ReasonDetailEvent extends Equatable {
  const ReasonDetailEvent();

  @override
  List<Object?> get props => [];
}

/// The screen opened (on the cached reason the bloc was made with): follow its saved
/// copy, and get the areas, voices and tones the sheets offer.
class ReasonDetailStartedEvent extends ReasonDetailEvent {
  const ReasonDetailStartedEvent();
}

/// The cached areas of life (followed while the screen is open).
class ReasonDetailAreasWatchedEvent extends ReasonDetailEvent {
  const ReasonDetailAreasWatchedEvent();
}

/// The cached voices (followed while the screen is open).
class ReasonDetailVoicesWatchedEvent extends ReasonDetailEvent {
  const ReasonDetailVoicesWatchedEvent();
}

/// Asks the server for the sound types (tones); also "Try again".
class ReasonDetailSoundTypesRequestedEvent extends ReasonDetailEvent {
  const ReasonDetailSoundTypesRequestedEvent();
}

/// A sheet chose something: [draft] is what the screen now holds (not saved yet).
/// Choosing the saved value again is no change at all.
class ReasonDetailDraftChangedEvent extends ReasonDetailEvent {
  final ReasonDraft draft;

  const ReasonDetailDraftChangedEvent(this.draft);

  @override
  List<Object?> get props => [draft];
}

/// "Discard": back to the saved values.
class ReasonDetailDiscardedEvent extends ReasonDetailEvent {
  const ReasonDetailDiscardedEvent();
}

/// "Save Changes": everything held is saved at once.
class ReasonDetailSavedEvent extends ReasonDetailEvent {
  const ReasonDetailSavedEvent();
}

/// "Delete" was confirmed: the reason goes (server, then device).
class ReasonDetailDeleteRequestedEvent extends ReasonDetailEvent {
  const ReasonDetailDeleteRequestedEvent();
}

/// A new (trimmed, non-empty, different) name; saved at once, on its own.
class ReasonDetailRenamedEvent extends ReasonDetailEvent {
  final String name;

  const ReasonDetailRenamedEvent(this.name);

  @override
  List<Object?> get props => [name];
}
