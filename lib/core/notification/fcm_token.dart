import 'dart:async';

/// The device's Firebase Cloud Messaging token, readable from anywhere in the app:
///
/// ```dart
/// import 'package:eala/core/notification/fcm_token.dart';
/// final token = fcmToken; // null until Firebase has issued one
/// ```
///
/// `NotificationService` fills it at startup and again whenever Firebase refreshes the
/// token (always through [setFcmToken]). It stays null if the user denied
/// notifications, the device has no Google services, or (iOS) the APNs token is not
/// available (e.g. the simulator).
String? fcmToken;

final StreamController<String> _fcmTokenChanges =
    StreamController<String>.broadcast();

/// Emits every new token, so code that has to pass it on (e.g. save it to the
/// server) can react the moment it arrives or is refreshed.
Stream<String> get fcmTokenChanges => _fcmTokenChanges.stream;

/// Stores [token] in [fcmToken] and announces it on [fcmTokenChanges].
void setFcmToken(String? token) {
  fcmToken = token;
  if (token != null) _fcmTokenChanges.add(token);
}
