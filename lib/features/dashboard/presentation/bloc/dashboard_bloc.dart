import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/firebase/analytics_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Which tab of the mother screen is showing, and which screen Analytics sees. The
/// tabs' own data lives in their features (My Alarms, Reasons, Settings).
@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  /// Analytics screen names, in tab order.
  static const List<String> screenNames = ['my_alarms', 'reasons', 'settings'];

  final AnalyticsService analytics;

  DashboardBloc(this.analytics) : super(const DashboardState()) {
    on<DashboardTabChangedEvent>((event, emit) {
      analytics.logScreen(screenNames[event.index]);
      emit(DashboardState(selectedIndex: event.index));
    });
  }
}
