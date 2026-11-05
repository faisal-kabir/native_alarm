import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'fcm_token.dart';
import 'local_notification_presenter.dart';
import 'push_content.dart';

/// Connects Firebase Cloud Messaging to the device: asks for permission, keeps
/// [fcmToken] up to date, and shows push messages that arrive while the app is open
/// through [LocalNotificationPresenter].
///
/// While the app is in the background or closed, the system shows `notification`
/// messages by itself; data-only messages are shown by
/// `firebaseMessagingBackgroundHandler`.
@lazySingleton
class NotificationService {
  final FirebaseMessaging messaging;
  final LocalNotificationPresenter presenter;

  NotificationService(this.messaging, this.presenter);

  bool _started = false;

  /// Starts everything. Never throws: a notification problem must not stop the app.
  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    try {
      await presenter.initialize();
      await messaging.requestPermission();
      // iOS: we draw foreground messages ourselves, so the system must not also.
      await messaging.setForegroundNotificationPresentationOptions();

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      // `onTokenRefresh` / `getToken` are marked deprecated in favour of
      // register()/onRegistered, but those return the Firebase Installation ID, a
      // different identifier. The Firebase console ("Send test message") and the
      // HTTP v1 `token` field need this FCM registration token.
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen(_storeToken);

      await _loadToken();
    } catch (e, stack) {
      debugPrint('NotificationService.initialize failed: $e\n$stack');
    }
  }

  Future<void> _loadToken() async {
    // On iOS the FCM token only exists after Apple has issued an APNs token.
    if (Platform.isIOS) {
      for (var attempt = 0; attempt < 5; attempt++) {
        if (await messaging.getAPNSToken() != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    // ignore: deprecated_member_use
    _storeToken(await messaging.getToken());
  }

  void _storeToken(String? token) {
    fcmToken = token;
    if (token != null) debugPrint('FCM token: $token');
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final content = PushContent.fromMessage(message);
    if (content == null) return;
    await presenter.show(
      id: message.hashCode,
      title: content.title,
      body: content.body,
      payload: content.payload,
    );
  }
}
