import 'package:eala/main.dart';
import 'package:flutter/material.dart';

import '../../features/alarm/presentation/pages/alarm_list_page.dart';
import '../../features/alarm/domain/entities/alarm.dart';
import '../../features/create_alarm/presentation/pages/create_alarm_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/create_reason/presentation/pages/create_reason_page.dart';
import '../../features/create_reason/presentation/pages/reason_ready_page.dart';
import '../../features/reason_detail/presentation/pages/reason_detail_page.dart';
import '../../features/reasons/domain/entities/reason.dart';
import 'route_names.dart';

import 'package:go_router/go_router.dart';

/// The page of every route. Always a [MaterialPage], so the app-wide slide transition
/// set in `AppTheme` (`pageTransitionsTheme`) applies: in from the right on push, out
/// to the right on pop. Without this go_router picks the page type itself, and here it
/// fell back to a page with no transition at all.
Page<void> appPage(GoRouterState state, Widget child) =>
    MaterialPage<void>(key: state.pageKey, child: child);

/// The reason screens open with their [Reason] (a full, cached object); without one
/// (a lost link) they go home.
String? _needsReason(BuildContext context, GoRouterState state) =>
    state.extra is Reason ? null : RouteNames.dashboardPath;

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: RouteNames.dashboardPath,
  routes: [
    GoRoute(
      path: RouteNames.dashboardPath,
      name: RouteNames.dashboard,
      pageBuilder: (context, state) => appPage(state, const DashboardPage()),
    ),
    GoRoute(
      path: RouteNames.alarmListPath,
      name: RouteNames.alarmList,
      pageBuilder: (context, state) => appPage(state, const AlarmListPage()),
    ),
    GoRoute(
      path: RouteNames.createReasonPath,
      name: RouteNames.createReason,
      pageBuilder: (context, state) => appPage(
        state,
        CreateReasonPage(
          returnReason: state.extra == CreateReasonPage.returnReasonExtra,
        ),
      ),
    ),
    GoRoute(
      path: RouteNames.reasonReadyPath,
      name: RouteNames.reasonReady,
      redirect: _needsReason,
      pageBuilder: (context, state) =>
          appPage(state, ReasonReadyPage(reason: state.extra! as Reason)),
    ),
    GoRoute(
      path: RouteNames.reasonDetailPath,
      name: RouteNames.reasonDetail,
      redirect: _needsReason,
      pageBuilder: (context, state) =>
          appPage(state, ReasonDetailPage(reason: state.extra! as Reason)),
    ),
    GoRoute(
      path: RouteNames.createAlarmPath,
      name: RouteNames.createAlarm,
      // `extra`: the id of a Reason the alarm starts with (optional).
      pageBuilder: (context, state) => appPage(
        state,
        CreateAlarmPage(
          reasonId: state.extra is int ? state.extra! as int : null,
        ),
      ),
    ),
    GoRoute(
      path: RouteNames.editAlarmPath,
      name: RouteNames.editAlarm,
      // `extra`: the saved alarm to edit; without one (a lost link) it goes home.
      redirect: (context, state) =>
          state.extra is Alarm ? null : RouteNames.dashboardPath,
      pageBuilder: (context, state) =>
          appPage(state, CreateAlarmPage(alarm: state.extra! as Alarm)),
    ),
  ],
  errorBuilder: (context, state) =>
      const Scaffold(body: Center(child: Text('Page not found'))),
);
