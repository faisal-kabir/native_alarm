import 'package:equatable/equatable.dart';

/// Which notifications the user wants. They do not affect alarms.
class UserSettings extends Equatable {
  /// Trial and billing notices.
  final bool notifyBilling;

  /// Reminders about upcoming alarms.
  final bool notifyAlarms;

  /// "Thoughts for the day".
  final bool notifyQuotes;

  const UserSettings({
    this.notifyBilling = true,
    this.notifyAlarms = true,
    this.notifyQuotes = false,
  });

  UserSettings copyWith({
    bool? notifyBilling,
    bool? notifyAlarms,
    bool? notifyQuotes,
  }) => UserSettings(
    notifyBilling: notifyBilling ?? this.notifyBilling,
    notifyAlarms: notifyAlarms ?? this.notifyAlarms,
    notifyQuotes: notifyQuotes ?? this.notifyQuotes,
  );

  @override
  List<Object?> get props => [notifyBilling, notifyAlarms, notifyQuotes];
}
