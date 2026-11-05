import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';

/// Product analytics. Active users, sessions and engagement are collected by Firebase
/// Analytics automatically once it is initialised; this service adds what it cannot
/// see by itself.
abstract class AnalyticsService {
  /// Records that the user is looking at the screen called [name].
  Future<void> logScreen(String name);
}

@LazySingleton(as: AnalyticsService)
class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics analytics;

  FirebaseAnalyticsService(this.analytics);

  @override
  Future<void> logScreen(String name) async {
    try {
      await analytics.logScreenView(screenName: name);
    } catch (_) {
      // Analytics must never break the app.
    }
  }
}
