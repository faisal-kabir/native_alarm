import 'package:equatable/equatable.dart';

import '../../domain/entities/reason.dart';

abstract class ReasonsState extends Equatable {
  const ReasonsState();

  @override
  List<Object?> get props => [];
}

class ReasonsInitial extends ReasonsState {
  const ReasonsInitial();
}

class ReasonsLoading extends ReasonsState {
  const ReasonsLoading();
}

class ReasonsLoaded extends ReasonsState {
  final List<Reason> reasons;

  /// Reason id → whether the alarm that plays it is on, for each reason an alarm on
  /// this device plays (the row's alarm mark).
  final Map<int, bool> alarmOn;

  const ReasonsLoaded(this.reasons, {this.alarmOn = const {}});

  @override
  List<Object?> get props => [reasons, alarmOn];
}

class ReasonsFailure extends ReasonsState {
  final String message;

  const ReasonsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
