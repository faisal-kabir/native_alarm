import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// Shows notifications on the device with flutter_local_notifications. Firebase
/// Messaging does not draw a notification while the app is open, so push messages
/// that arrive then are shown through this class.
@lazySingleton
class LocalNotificationPresenter {
  /// Android channel for push messages. The same id is the default channel in
  /// AndroidManifest.xml, so messages shown by the system use it too.
  static const String channelId = 'eala_general';
  static const String channelName = 'General notifications';

  final FlutterLocalNotificationsPlugin plugin;

  LocalNotificationPresenter(this.plugin);

  bool _initialized = false;

  /// Prepares the plugin and creates the Android channel. Safe to call repeatedly.
  Future<void> initialize() async {
    if (_initialized) return;
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_alarm_white'),
        // Permission is requested once, by NotificationService.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            importance: Importance.high,
          ),
        );
    _initialized = true;
  }

  /// Shows one notification. [id] replaces an earlier one with the same id.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    await plugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_alarm_white',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
