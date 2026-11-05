/// The device's Firebase Cloud Messaging token, readable from anywhere in the app:
///
/// ```dart
/// import 'package:eala/core/notification/fcm_token.dart';
/// final token = fcmToken; // null until Firebase has issued one
/// ```
///
/// `NotificationService` fills it at startup and again whenever Firebase refreshes the
/// token. It stays null if the user denied notifications, the device has no Google
/// services, or (iOS) the APNs token is not available (e.g. the simulator).
String? fcmToken;
