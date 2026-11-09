import 'package:equatable/equatable.dart';

import '../../domain/entities/alarm_draft.dart';

abstract class CreateAlarmEvent extends Equatable {
  const CreateAlarmEvent();

  @override
  List<Object?> get props => [];
}

/// The page opened: follow the cached reasons, alarm sounds and sound tracks, count
/// the alarms (the limit, and which Reasons already have one), check alarm access.
class CreateAlarmStartedEvent extends CreateAlarmEvent {
  const CreateAlarmStartedEvent();
}

class CreateAlarmReasonsWatchedEvent extends CreateAlarmEvent {
  const CreateAlarmReasonsWatchedEvent();
}

class CreateAlarmSoundsWatchedEvent extends CreateAlarmEvent {
  const CreateAlarmSoundsWatchedEvent();
}

/// A card's wheel moved.
class CreateAlarmTimeChangedEvent extends CreateAlarmEvent {
  final String cardId;
  final AlarmTime time;

  const CreateAlarmTimeChangedEvent(this.cardId, this.time);

  @override
  List<Object?> get props => [cardId, time];
}

/// A day was tapped in a card (0 = Sunday).
class CreateAlarmDayToggledEvent extends CreateAlarmEvent {
  final String cardId;
  final int day;

  const CreateAlarmDayToggledEvent(this.cardId, this.day);

  @override
  List<Object?> get props => [cardId, day];
}

/// "Add another time".
class CreateAlarmCardAddedEvent extends CreateAlarmEvent {
  const CreateAlarmCardAddedEvent();
}

/// A Reason was picked (or made, and returned by the reason maker).
class CreateAlarmReasonChosenEvent extends CreateAlarmEvent {
  final int reasonId;

  const CreateAlarmReasonChosenEvent(this.reasonId);

  @override
  List<Object?> get props => [reasonId];
}

class CreateAlarmSoundTrackChosenEvent extends CreateAlarmEvent {
  final int id;

  const CreateAlarmSoundTrackChosenEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateAlarmAlarmSoundChosenEvent extends CreateAlarmEvent {
  final int id;

  const CreateAlarmAlarmSoundChosenEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Ring again: 0 off, 1 once, 2 twice.
class CreateAlarmRingAgainChangedEvent extends CreateAlarmEvent {
  final int again;

  const CreateAlarmRingAgainChangedEvent(this.again);

  @override
  List<Object?> get props => [again];
}

class CreateAlarmEnabledChangedEvent extends CreateAlarmEvent {
  final bool enabled;

  const CreateAlarmEnabledChangedEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// "Enable Alarm Access": ask the system, then look again.
class CreateAlarmAccessRequestedEvent extends CreateAlarmEvent {
  const CreateAlarmAccessRequestedEvent();
}

/// "Save Alarm".
class CreateAlarmSavedEvent extends CreateAlarmEvent {
  const CreateAlarmSavedEvent();
}
