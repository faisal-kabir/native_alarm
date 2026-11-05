import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Starts Firebase and wires Crashlytics to every kind of uncaught error. Call it
/// first in `main()`, before anything that can fail.
///
/// Crashlytics reports are switched off in debug builds so development crashes do
/// not pollute the dashboard; Analytics (active users) stays on in every build.
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

  // Errors thrown inside Flutter widgets/framework code.
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  // Errors that escape every other handler (async code, platform channels).
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}
