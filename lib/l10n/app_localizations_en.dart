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
  String get common_continue => 'Continue';

  @override
  String get common_back => 'Back';

  @override
  String get common_progress => 'Progress';

  @override
  String get common_try_again => 'Try again';

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
  String get create_reason_area_title => 'What do you want\nto *wake up for*?';

  @override
  String get create_reason_areas_error =>
      'Couldn’t load the list. Check your connection and try again.';

  @override
  String get create_reason_areas_empty => 'Nothing to choose from yet.';

  @override
  String get create_reason_purpose_title => 'What are you\n*working toward*?';

  @override
  String get create_reason_purpose_hint =>
      'I’m working toward something that matters to me because…';

  @override
  String get create_reason_suggestions_label => 'Or start from one of these';

  @override
  String get suggestions_more_ideas => 'More ideas';

  @override
  String get suggestions_more_ideas_semantics => 'Show more ideas';

  @override
  String get create_reason_ideas_error => 'Couldn’t load ideas.';

  @override
  String get dictation_start => 'Say it out loud';

  @override
  String get dictation_discard => 'Discard what you said';

  @override
  String get dictation_stop => 'Stop and use what you said';

  @override
  String get dictation_listening => 'Listening… say it however it comes out.';

  @override
  String get dictation_unavailable =>
      'Voice input isn’t available. Allow the microphone and speech recognition for Eala in Settings.';

  @override
  String text_counter(int count, int max) {
    return '$count/$max';
  }

  @override
  String get reason_alarm_on_note => ' Played by an alarm.';

  @override
  String get reason_alarm_off_note => ' Its alarm is off.';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_set_your_name => 'Set your name';

  @override
  String get settings_not_signed_in => 'Not signed in';

  @override
  String settings_profile_semantics(String name, String subtitle) {
    return '$name. $subtitle';
  }

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_notify_billing => 'Trial & billing';

  @override
  String get settings_notify_alarms => 'Alarm reminders';

  @override
  String get settings_notify_quotes => 'Thoughts for the day';

  @override
  String get settings_notifications_note =>
      'These settings don’t affect your alarms.';

  @override
  String get settings_subscription => 'Subscription';

  @override
  String get settings_plan_free => 'Free';

  @override
  String get settings_support => 'Support';

  @override
  String get settings_help => 'Help & Support';

  @override
  String get settings_faq => 'FAQ';

  @override
  String get settings_request_feature => 'Request a feature';

  @override
  String get settings_leave_review => 'Leave a review';

  @override
  String get settings_legal => 'Legal';

  @override
  String get settings_privacy => 'Privacy Policy';

  @override
  String get settings_terms => 'Terms of Use';

  @override
  String get settings_account => 'Account';

  @override
  String get settings_sign_in => 'Sign In';

  @override
  String get settings_delete_account => 'Delete account';

  @override
  String settings_version(String name, String version, String build) {
    return '$name $version ($build)';
  }
}
