import 'package:equatable/equatable.dart';

abstract class MyAlarmsEvent extends Equatable {
  const MyAlarmsEvent();

  @override
  List<Object?> get props => [];
}

/// Reads the saved alarms; sent on open and whenever the app comes back.
class LoadMyAlarmsEvent extends MyAlarmsEvent {
  const LoadMyAlarmsEvent();
}
