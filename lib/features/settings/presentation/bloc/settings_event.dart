import 'package:equatable/equatable.dart';

/// The notification choices on the Settings screen.
enum SettingsNotification { billing, alarms, quotes }

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Reads the saved settings and the app version; sent when the tab opens.
class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

/// A notification switch was flipped.
class NotificationToggledEvent extends SettingsEvent {
  final SettingsNotification notification;
  final bool enabled;

  const NotificationToggledEvent(this.notification, this.enabled);

  @override
  List<Object?> get props => [notification, enabled];
}
