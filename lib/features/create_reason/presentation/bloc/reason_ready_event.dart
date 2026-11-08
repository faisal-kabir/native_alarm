import 'package:equatable/equatable.dart';

abstract class ReasonReadyEvent extends Equatable {
  const ReasonReadyEvent();

  @override
  List<Object?> get props => [];
}

/// The ready screen opened for the saved reason [id], named [name].
class ReasonReadyStartedEvent extends ReasonReadyEvent {
  final int id;
  final String name;

  const ReasonReadyStartedEvent(this.id, this.name);

  @override
  List<Object?> get props => [id, name];
}

/// The user gave the reason a new (trimmed, non-empty, different) name.
class ReasonRenamedEvent extends ReasonReadyEvent {
  final String name;

  const ReasonRenamedEvent(this.name);

  @override
  List<Object?> get props => [name];
}
