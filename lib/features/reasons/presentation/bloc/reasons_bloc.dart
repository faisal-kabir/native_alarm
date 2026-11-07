import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/reason.dart';
import '../../domain/usecases/refresh_reasons_usecase.dart';
import '../../domain/usecases/watch_reasons_usecase.dart';
import 'reasons_event.dart';
import 'reasons_state.dart';

@injectable
class ReasonsBloc extends Bloc<ReasonsEvent, ReasonsState> {
  final WatchReasonsUseCase watchReasonsUseCase;
  final RefreshReasonsUseCase refreshReasonsUseCase;

  ReasonsBloc(this.watchReasonsUseCase, this.refreshReasonsUseCase)
    : super(const ReasonsInitial()) {
    on<LoadReasonsEvent>(_onLoad);
    on<RefreshReasonsEvent>(_onRefresh);
  }

  /// The list always shows the device's copy; this only updates that copy.
  Future<void> _onRefresh(
    RefreshReasonsEvent event,
    Emitter<ReasonsState> emit,
  ) async {
    final result = await refreshReasonsUseCase(NoParams());
    result.fold(
      (failure) => debugPrint('Reasons not refreshed: ${failure.message}'),
      (_) {},
    );
  }

  /// Follows the saved reasons: a reason created or renamed anywhere shows up here
  /// at once.
  Future<void> _onLoad(
    LoadReasonsEvent event,
    Emitter<ReasonsState> emit,
  ) async {
    if (state is! ReasonsLoaded) emit(const ReasonsLoading());
    add(const RefreshReasonsEvent());
    await emit.forEach<Either<Failure, List<Reason>>>(
      watchReasonsUseCase(NoParams()),
      onData: (result) => result.fold(
        (failure) => ReasonsFailure(failure.message),
        ReasonsLoaded.new,
      ),
    );
  }
}
