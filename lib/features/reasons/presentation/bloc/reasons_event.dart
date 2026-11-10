import 'package:equatable/equatable.dart';

abstract class ReasonsEvent extends Equatable {
  const ReasonsEvent();

  @override
  List<Object?> get props => [];
}

/// Starts following the saved reasons; sent when the tab opens.
class LoadReasonsEvent extends ReasonsEvent {
  const LoadReasonsEvent();
}

/// Brings the saved reasons up to date with the server in the background (sent with
/// [LoadReasonsEvent] and when the app comes back to the front). The list keeps
/// showing the saved copy; offline nothing changes.
class RefreshReasonsEvent extends ReasonsEvent {
  const RefreshReasonsEvent();
}

/// Starts following the saved alarms, for each reason's alarm mark; sent with
/// [LoadReasonsEvent].
class ReasonsAlarmsWatchedEvent extends ReasonsEvent {
  const ReasonsAlarmsWatchedEvent();
}
