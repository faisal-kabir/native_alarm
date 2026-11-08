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
  String get common_list_error =>
      'Couldn’t load the list. Check your connection and try again.';

  @override
  String get common_list_empty => 'Nothing to choose from yet.';

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
  String get suggestions_load_failed => 'Couldn’t load ideas.';

  @override
  String get create_reason_matter_title => 'Why does it\n*matter to you*?';

  @override
  String get create_reason_matter_for => 'For';

  @override
  String get create_reason_matter_hint => 'This matters to me because…';

  @override
  String get create_reason_matter_too_short =>
      'A few more words, or clear it to skip.';

  @override
  String get common_optional => 'Optional';

  @override
  String get common_skip_for_now => 'Skip for now';

  @override
  String quoted_text(String text) {
    return '“$text”';
  }

  @override
  String get create_reason_sound_title => 'How should it *sound*?';

  @override
  String get create_reason_sound_semantics => 'Sound';

  @override
  String get create_reason_example => 'Example';

  @override
  String get create_reason_example_failed => 'Couldn’t load the example.';

  @override
  String get create_reason_length => 'Length';

  @override
  String get create_reason_length_30 => 'Short';

  @override
  String get create_reason_length_30_note => 'Quick and to the point.';

  @override
  String get create_reason_length_45 => 'Standard';

  @override
  String get create_reason_length_45_note => 'A full thought, not a ramble.';

  @override
  String get create_reason_create => 'Create Reason';

  @override
  String seconds_short(int seconds) {
    return '$seconds sec';
  }

  @override
  String get reason_ready_title => 'Your reason is *ready*.';

  @override
  String get reason_ready_announcement => 'Your reason is ready.';

  @override
  String get reason_ready_why => 'Why it matters';

  @override
  String get reason_ready_voice => 'Voice';

  @override
  String get reason_ready_tone => 'Tone';

  @override
  String get reason_ready_use_with_alarm => 'Use with alarm';

  @override
  String get reason_ready_save_for_later => 'Save for later';

  @override
  String get reason_name_hint => 'Name this reason';

  @override
  String get reason_name_label => 'Reason name';

  @override
  String get reason_name_save => 'Save name';

  @override
  String get reason_save_failed =>
      'Couldn’t save your reason. Check your connection and try again.';

  @override
  String get reason_rename_failed =>
      'Couldn’t rename it. Check your connection and try again.';

  @override
  String get common_saving => 'Saving…';

  @override
  String get create_reason_voice_title => 'Who should *say it*?';

  @override
  String voice_play(String name) {
    return 'Hear $name';
  }

  @override
  String voice_stop(String name) {
    return 'Stop $name';
  }

  @override
  String voice_group_semantics(String group) {
    return '$group voices';
  }

  @override
  String get voice_play_failed =>
      'Couldn’t play this voice. Check your connection and try again.';

  @override
  String get list_separator => ' · ';

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

  @override
  String get common_close => 'Close';

  @override
  String get common_add => 'Add';

  @override
  String get sheet_no_changes => 'No Changes';

  @override
  String get sheet_use_this => 'Use This';

  @override
  String get sheet_remove => 'Remove';

  @override
  String sheet_use_choice(String name) {
    return 'Use $name';
  }

  @override
  String get reason_detail_about => 'What it’s about';

  @override
  String get reason_detail_speaks => 'How it speaks';

  @override
  String get reason_detail_alarm => 'Alarm';

  @override
  String get reason_detail_no_alarm => 'Not in an alarm yet.';

  @override
  String get reason_detail_area => 'Area of life';

  @override
  String get reason_detail_purpose => 'Purpose';

  @override
  String get reason_detail_why => 'Why it matters';

  @override
  String get reason_detail_tone => 'Tone';

  @override
  String get reason_detail_voice => 'Voice';

  @override
  String get reason_detail_length => 'Length';

  @override
  String reason_detail_length_value(String name, int seconds) {
    return '$name · $seconds sec';
  }

  @override
  String reason_detail_row_semantics(
    String label,
    String value,
    String changed,
  ) {
    return '$label: $value.$changed Change';
  }

  @override
  String get reason_detail_changed_note => ' Changed, not saved.';

  @override
  String get reason_detail_save => 'Save Changes';

  @override
  String get reason_detail_discard => 'Discard';

  @override
  String get reason_detail_caption =>
      'Changes will apply from your next new message.';

  @override
  String get reason_detail_discard_title => 'Discard changes?';

  @override
  String get reason_detail_discard_message => 'This reason stays as it is now.';

  @override
  String get reason_detail_keep_editing => 'Keep Editing';

  @override
  String get reason_detail_save_failed =>
      'Couldn’t save your changes. Check your connection and try again.';

  @override
  String get reason_detail_more_below => 'More below';

  @override
  String get reason_detail_area_sheet => 'What part of life is this for?';

  @override
  String get reason_detail_keep_area => 'Keep This Area';

  @override
  String get reason_detail_purpose_sheet => 'What are you working toward?';

  @override
  String get reason_detail_why_sheet => 'Why does it matter to you?';

  @override
  String get reason_detail_purpose_short =>
      'A few more words, so we can write for you.';

  @override
  String get reason_detail_why_short => 'A little more, if you can.';

  @override
  String get reason_detail_tone_sheet => 'How should it talk to you?';

  @override
  String get reason_detail_keep_tone => 'Keep This Tone';

  @override
  String get reason_detail_voice_sheet => 'Choose a voice';

  @override
  String get reason_detail_keep_voice => 'Keep This Voice';

  @override
  String get reason_detail_length_sheet => 'How long should it speak?';

  @override
  String get reason_detail_keep_length => 'Keep This Length';

  @override
  String get reason_detail_more => 'More';

  @override
  String get reason_detail_connect_alarm => 'Connect an alarm';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_delete => 'Delete';

  @override
  String get reason_actions_use_with_alarm => 'Use with an alarm';

  @override
  String get reason_actions_delete => 'Delete Reason';

  @override
  String reason_delete_title(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get reason_delete_message => 'This can’t be undone.';

  @override
  String get reason_delete_failed =>
      'Couldn’t delete this reason. Check your connection and try again.';
}
