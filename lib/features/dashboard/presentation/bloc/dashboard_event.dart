import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// The visible tab changed (a tab was tapped or the pages were swiped).
class DashboardTabChangedEvent extends DashboardEvent {
  final int index;

  const DashboardTabChangedEvent(this.index);

  @override
  List<Object?> get props => [index];
}
