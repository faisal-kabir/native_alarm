import 'package:eala/main.dart';
import 'package:flutter/material.dart';

import '../../features/alarm/presentation/pages/alarm_list_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/create_reason/presentation/pages/create_reason_page.dart';
import 'route_names.dart';

import 'package:go_router/go_router.dart';

/// The page of every route. Always a [MaterialPage], so the app-wide slide transition
/// set in `AppTheme` (`pageTransitionsTheme`) applies: in from the right on push, out
/// to the right on pop. Without this go_router picks the page type itself, and here it
/// fell back to a page with no transition at all.
Page<void> appPage(GoRouterState state, Widget child) =>
    MaterialPage<void>(key: state.pageKey, child: child);

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
      pageBuilder: (context, state) => appPage(state, const CreateReasonPage()),
    ),
  ],
  errorBuilder: (context, state) =>
      const Scaffold(body: Center(child: Text('Page not found'))),
);
