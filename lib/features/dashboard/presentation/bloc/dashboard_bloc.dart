import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Which tab of the mother screen is showing. The tabs' own data lives in their
/// features (My Alarms, Reasons, Settings).
@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(const DashboardState()) {
    on<DashboardTabChangedEvent>(
      (event, emit) => emit(DashboardState(selectedIndex: event.index)),
    );
  }
}
