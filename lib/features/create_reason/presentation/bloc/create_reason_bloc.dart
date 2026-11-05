import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../area_of_life/domain/usecases/refresh_areas_of_life_usecase.dart';
import '../../../area_of_life/domain/usecases/watch_areas_of_life_usecase.dart';
import 'create_reason_event.dart';
import 'create_reason_state.dart';

/// The BLoC of the Create Reason mother page. Every step's data lives in
/// [CreateReasonState]; the steps are pages of one PageView.
@injectable
class CreateReasonBloc extends Bloc<CreateReasonEvent, CreateReasonState> {
  /// How many step pages exist so far. Raise it by one whenever a step page is added
  /// to `CreateReasonPage` (and give `CreateReasonState.canContinue` its case).
  static const int builtStepCount = 1;

  final WatchAreasOfLifeUseCase watchAreasUseCase;
  final RefreshAreasOfLifeUseCase refreshAreasUseCase;

  CreateReasonBloc(this.watchAreasUseCase, this.refreshAreasUseCase)
    : super(const CreateReasonState()) {
    on<LoadAreasEvent>(_onLoadAreas);
    on<RefreshAreasEvent>(_onRefreshAreas);
    on<AreaSelectedEvent>((event, emit) {
      if (!state.areas.any((a) => a.id == event.areaId)) return;
      emit(state.copyWith(selectedAreaId: () => event.areaId));
    });
    on<NextStepEvent>(_onNextStep);
    on<PreviousStepEvent>(_onPreviousStep);
  }

  /// Shows the saved areas at once and keeps following them: when the server update
  /// below brings something new, it is written to the saved copy and this stream
  /// delivers it to the page.
  Future<void> _onLoadAreas(
    LoadAreasEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    add(const RefreshAreasEvent());
    await emit.forEach<Either<Failure, List<AreaOfLife>>>(
      watchAreasUseCase(NoParams()),
      onData: (result) => result.fold(
        (failure) => state.copyWith(areasStatus: AreasStatus.failed),
        (areas) {
          // A choice the server has removed since can not stay chosen.
          final stillThere = areas.any((a) => a.id == state.selectedAreaId);
          return state.copyWith(
            areas: areas,
            selectedAreaId: stillThere ? null : () => null,
          );
        },
      ),
    );
  }

  Future<void> _onRefreshAreas(
    RefreshAreasEvent event,
    Emitter<CreateReasonState> emit,
  ) async {
    if (state.areas.isEmpty && state.areasStatus == AreasStatus.failed) {
      emit(state.copyWith(areasStatus: AreasStatus.loading));
    }
    final result = await refreshAreasUseCase(NoParams());
    // With areas on the device a failed update is silent: they stay on screen.
    emit(
      state.copyWith(
        areasStatus: result.fold(
          (_) => AreasStatus.failed,
          (_) => AreasStatus.loaded,
        ),
      ),
    );
  }

  void _onNextStep(NextStepEvent event, Emitter<CreateReasonState> emit) {
    final next = state.stepIndex + 1;
    if (!state.canContinue || next >= builtStepCount) return;
    emit(state.copyWith(stepIndex: next));
  }

  void _onPreviousStep(
    PreviousStepEvent event,
    Emitter<CreateReasonState> emit,
  ) {
    if (state.stepIndex == 0) return;
    emit(state.copyWith(stepIndex: state.stepIndex - 1));
  }
}
