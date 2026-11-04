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
  String get settings_placeholder => 'Settings screen will be here';

  @override
  String get my_alarms_add_alarm => 'Add alarm';

  @override
  String get reasons_title => 'My Reasons';

  @override
  String get reasons_add_first_title => 'Add your first Reason';

  @override
  String get reasons_add_first_subtitle => 'The why behind your day.';

  @override
  String get reasons_add_label => 'New Reason';

  @override
  String get reason_area_health => 'Health';

  @override
  String get reason_area_healing => 'Healing';

  @override
  String get reason_area_fitness => 'Fitness';

  @override
  String get reason_area_career => 'Career';

  @override
  String get reason_area_family => 'Family';

  @override
  String get reason_area_money => 'Money';

  @override
  String get reason_area_growth => 'Growth';

  @override
  String get reason_area_business => 'Business';

  @override
  String get reason_area_study => 'Learning & Skills';

  @override
  String get reason_area_relationships => 'Relationships';

  @override
  String get reason_tone_encouraging => 'Encouraging';

  @override
  String get reason_tone_calm => 'Calm';

  @override
  String get reason_tone_focused => 'Focused';

  @override
  String get reason_tone_challenge => 'Challenge';

  @override
  String get reason_tone_playful => 'Playful';

  @override
  String reason_row_subtitle(String area, String tone) {
    return '$area · $tone';
  }

  @override
  String reason_row_semantics(
    String name,
    String area,
    String tone,
    String note,
  ) {
    return '$name. $area, $tone tone.$note';
  }

  @override
  String get reason_alarm_on_note => ' Played by an alarm.';

  @override
  String get reason_alarm_off_note => ' Its alarm is off.';
}
