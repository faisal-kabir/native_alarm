import 'package:equatable/equatable.dart';

import '../../domain/entities/app_info.dart';
import '../../domain/entities/user_settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final UserSettings settings;

  /// Null only if the platform could not report it.
  final AppInfo? appInfo;

  const SettingsLoaded(this.settings, this.appInfo);

  @override
  List<Object?> get props => [settings, appInfo];
}

class SettingsFailure extends SettingsState {
  final String message;

  const SettingsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
