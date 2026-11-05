import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'local_notification_presenter.dart';
import 'push_content.dart';

/// Runs in its own isolate when a push message arrives while the app is in the
/// background or closed. It must be a top-level function.
///
/// `notification` messages are already shown by the system; only data-only messages
/// that carry a `title` and `body` need to be drawn here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.notification != null) return;

  final content = PushContent.fromMessage(message);
  if (content == null) return;

  await LocalNotificationPresenter(FlutterLocalNotificationsPlugin()).show(
    id: message.hashCode,
    title: content.title,
    body: content.body,
    payload: content.payload,
  );
}
