import 'package:equatable/equatable.dart';

/// What the server should know about this installation: written to the user's row
/// (`platform`, `app_version`, `fcm_token`).
class DeviceInfo extends Equatable {
  /// `ios` or `android`.
  final String platform;

  /// Version and build, e.g. `1.0.0+1`.
  final String appVersion;

  /// Null while Firebase has not issued a token; then the saved one is left alone.
  final String? fcmToken;

  const DeviceInfo({
    required this.platform,
    required this.appVersion,
    this.fcmToken,
  });

  @override
  List<Object?> get props => [platform, appVersion, fcmToken];
}
