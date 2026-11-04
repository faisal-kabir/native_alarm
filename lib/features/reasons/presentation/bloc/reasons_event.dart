import 'package:equatable/equatable.dart';

abstract class ReasonsEvent extends Equatable {
  const ReasonsEvent();

  @override
  List<Object?> get props => [];
}

/// Reads the saved reasons; sent when the tab opens.
class LoadReasonsEvent extends ReasonsEvent {
  const LoadReasonsEvent();
}
