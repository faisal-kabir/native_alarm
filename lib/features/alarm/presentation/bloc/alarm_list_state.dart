import 'package:equatable/equatable.dart';

import '../../domain/entities/alarm.dart';

abstract class AlarmListState extends Equatable {
  const AlarmListState();

  @override
  List<Object?> get props => [];
}

class AlarmListInitial extends AlarmListState {
  const AlarmListInitial();
}

class AlarmListLoading extends AlarmListState {
  const AlarmListLoading();
}

class AlarmListLoaded extends AlarmListState {
  final List<Alarm> alarms;

  const AlarmListLoaded(this.alarms);

  @override
  List<Object?> get props => [alarms];
}

/// A load or write failed. [alarms] is the last known list so the page keeps showing it.
class AlarmListFailure extends AlarmListState {
  final String message;
  final List<Alarm> alarms;

  const AlarmListFailure(this.message, this.alarms);

  @override
  List<Object?> get props => [message, alarms];
}
