// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'Eala';

  @override
  String get alarm_list_empty => 'No alarms yet. Tap + to add one.';

  @override
  String get common_allow => 'Allow';

  @override
  String get common_not_now => 'Not now';

  @override
  String get alarm_permission_title => 'Permission needed';

  @override
  String get alarm_permission_notifications =>
      'Allow notifications so the alarm can alert you.';

  @override
  String get alarm_permission_full_screen =>
      'Allow full-screen alarms so the alarm screen can appear over the lock screen.';

  @override
  String get alarm_permission_overlay =>
      'Allow \"Display over other apps\" so the alarm screen can open while you are using the phone.';

  @override
  String get alarm_permission_exact_alarm =>
      'Allow exact alarms so the alarm rings on time.';

  @override
  String get tab_alarms => 'Alarms';

  @override
  String get tab_reasons => 'Reasons';

  @override
  String get tab_settings => 'Settings';

  @override
  String get my_alarms_title => 'My Alarms';

  @override
  String get my_alarms_your_alarms => 'Your alarms';

  @override
  String my_alarms_slot_meter_label(int count) {
    return 'Up to $count';
  }

  @override
  String my_alarms_slot_meter_semantics(int count) {
    return 'Up to $count alarms';
  }

  @override
  String get my_alarms_thought_semantics => 'Today\'s thought';

  @override
  String get my_alarms_add_first_alarm_title => 'Set your first alarm';

  @override
  String get my_alarms_add_first_alarm_subtitle => 'Pick a time and a reason.';

  @override
  String get reasons_placeholder => 'Reasons screen will be here';

  @override
  String get settings_placeholder => 'Settings screen will be here';
}
