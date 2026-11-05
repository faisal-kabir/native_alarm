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
