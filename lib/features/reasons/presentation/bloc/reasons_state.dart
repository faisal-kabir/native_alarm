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

  const ReasonsLoaded(this.reasons);

  @override
  List<Object?> get props => [reasons];
}

class ReasonsFailure extends ReasonsState {
  final String message;

  const ReasonsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
