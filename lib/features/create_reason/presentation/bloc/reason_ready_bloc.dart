import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../reasons/domain/usecases/rename_reason_usecase.dart';
import 'reason_ready_event.dart';
import 'reason_ready_state.dart';

/// The "Your reason is ready." screen: holds the reason's name and saves renames
/// (the row of `reason` is updated by its id; the device copy follows).
@injectable
class ReasonReadyBloc extends Bloc<ReasonReadyEvent, ReasonReadyState> {
  final RenameReasonUseCase renameReasonUseCase;

  ReasonReadyBloc(this.renameReasonUseCase) : super(const ReasonReadyState()) {
    on<ReasonReadyStartedEvent>(
      (event, emit) => emit(ReasonReadyState(id: event.id, name: event.name)),
    );
    on<ReasonRenamedEvent>(_onRenamed);
  }

  /// Shows the new name at once; puts the old one back if the server says no.
  Future<void> _onRenamed(
    ReasonRenamedEvent event,
    Emitter<ReasonReadyState> emit,
  ) async {
    final name = event.name.trim();
    final previous = state.name;
    if (name.isEmpty || name == previous) return;
    emit(state.copyWith(name: name));
    final result = await renameReasonUseCase(
      RenameReasonParams(state.id, name),
    );
    result.fold(
      (_) => emit(
        state.copyWith(
          name: previous,
          renameFailures: state.renameFailures + 1,
        ),
      ),
      (_) {},
    );
  }
}
