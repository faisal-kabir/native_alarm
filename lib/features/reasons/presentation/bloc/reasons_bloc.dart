import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_reasons_usecase.dart';
import 'reasons_event.dart';
import 'reasons_state.dart';

@injectable
class ReasonsBloc extends Bloc<ReasonsEvent, ReasonsState> {
  final GetReasonsUseCase getReasonsUseCase;

  ReasonsBloc(this.getReasonsUseCase) : super(const ReasonsInitial()) {
    on<LoadReasonsEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadReasonsEvent event,
    Emitter<ReasonsState> emit,
  ) async {
    if (state is! ReasonsLoaded) emit(const ReasonsLoading());
    final result = await getReasonsUseCase(NoParams());
    result.fold(
      (failure) => emit(ReasonsFailure(failure.message)),
      (reasons) => emit(ReasonsLoaded(reasons)),
    );
  }
}
