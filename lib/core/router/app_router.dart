import 'package:eala/main.dart';
import 'package:flutter/material.dart';
import '../../features/alarm/presentation/pages/alarm_list_page.dart';
import 'route_names.dart';
import 'package:go_router/go_router.dart';


final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: RouteNames.alarmList,
  routes: [
    GoRoute(
      path: RouteNames.alarmListPath,
      name: RouteNames.alarmList,
      builder: (context, state) => const AlarmListPage(),
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(
      child: Text('Page not found'),
    ),
  ),
);
