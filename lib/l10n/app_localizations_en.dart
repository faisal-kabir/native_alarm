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
  String get tab_reasons => 'Goal';

  @override
  String get tab_settings => 'Settings';

  @override
  String get my_alarms_title => 'My Alarms';

  @override
  String get alarm_ringing_fallback_title => 'Alarm';

  @override
  String alarm_ringing_snooze(int minutes) {
    return 'Snooze for $minutes min';
  }

  @override
  String alarm_ringing_snoozed(int minutes) {
    return 'Alarm snoozed for $minutes minutes';
  }

  @override
  String get alarm_ringing_stop => 'Stop';

  @override
  String get message_load_failed => 'Couldn’t load this message.';

  @override
  String get message_ringing_title => 'Alarm ringing';

  @override
  String get message_ringing_body => 'Play your message, or dismiss the alarm.';

  @override
  String get message_dismiss => 'Dismiss';

  @override
  String get message_play => 'Play message';

  @override
  String get message_status_playing => 'Playing';

  @override
  String get message_status_paused => 'Paused';

  @override
  String get message_status_ready => 'Ready';

  @override
  String get message_tap_to_play => 'Tap to play message';

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
  String get my_alarms_add_first_alarm_subtitle => 'Pick a time and a goal.';

  @override
  String get my_alarms_add_alarm => 'Add alarm';

  @override
  String get reasons_title => 'My Goals';

  @override
  String get reasons_add_first_title => 'Add your first Goal';

  @override
  String get reasons_add_first_subtitle => 'The why behind your day.';

  @override
  String get reasons_add_label => 'New Goal';

  @override
  String reason_row_subtitle(String voice, String tone) {
    return '$voice · $tone';
  }

  @override
  String reason_row_semantics(
    String name,
    String voice,
    String tone,
    String note,
  ) {
    return '$name. $voice’s voice, $tone tone.$note';
  }

  @override
  String get create_reason_area_title => 'What do you want\nto *wake up for*?';

  @override
  String get common_list_error =>
      'Couldn’t load the list. Check your connection and try again.';

  @override
  String get common_list_empty => 'Nothing to choose from yet.';

  @override
  String get create_reason_topic_semantics =>
      'What you wake up for, in a few words';

  @override
  String get create_reason_topic_chips => 'Or pick one';

  @override
  String get create_reason_topic_more => 'More';

  @override
  String get create_reason_topic_more_semantics => 'Show more';

  @override
  String get create_reason_topic_clear => 'Clear';

  @override
  String create_reason_topic_left(int count) {
    return '$count left';
  }

  @override
  String get create_reason_topic_example_1 => 'My garden';

  @override
  String get create_reason_topic_example_2 => 'My dog';

  @override
  String get create_reason_topic_example_3 => 'Painting';

  @override
  String get create_reason_topic_example_4 => 'Coaching kids';

  @override
  String get create_reason_topic_example_5 => 'Volunteering';

  @override
  String get create_reason_topic_example_6 => 'Surfing';

  @override
  String get create_reason_purpose_title => 'What are you\n*working toward*?';

  @override
  String get create_reason_purpose_hint => 'In your own words';

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
  String get create_reason_create => 'Create Goal';

  @override
  String seconds_short(int seconds) {
    return '$seconds sec';
  }

  @override
  String get reason_ready_title => 'Your goal is *ready*.';

  @override
  String get reason_ready_announcement => 'Your goal is ready.';

  @override
  String get reason_ready_topic => 'Wake up for';

  @override
  String get reason_ready_goal => 'Goal';

  @override
  String get reason_ready_why => 'Why';

  @override
  String get reason_ready_voice => 'Voice';

  @override
  String get reason_ready_tone => 'Tone';

  @override
  String get reason_ready_length => 'Length';

  @override
  String get reason_ready_use_with_alarm => 'Use with alarm';

  @override
  String get reason_ready_save_for_later => 'Save for later';

  @override
  String get reason_name_hint => 'Name this goal';

  @override
  String get reason_name_label => 'Goal name';

  @override
  String get reason_name_save => 'Save name';

  @override
  String get reason_save_failed =>
      'Couldn’t save your goal. Check your connection and try again.';

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
  String get settings_sign_out => 'Sign Out';

  @override
  String get settings_signed_in_apple => 'Signed in with Apple';

  @override
  String get settings_signed_in_google => 'Signed in with Google';

  @override
  String get settings_signed_in_device => 'Signed in on this device';

  @override
  String get settings_sign_in_note =>
      'Keep your goals, alarms and Premium if you delete the app or switch phones.';

  @override
  String get account_profile_title => 'Profile';

  @override
  String get account_profile_back => 'Settings';

  @override
  String get account_save => 'Save';

  @override
  String get account_your_name => 'Your name';

  @override
  String get account_name_hint => 'Your first name';

  @override
  String get account_name_semantics => 'First name';

  @override
  String get account_section => 'Account';

  @override
  String get account_signed_in_with => 'Signed in with';

  @override
  String get account_provider_apple => 'Apple';

  @override
  String get account_provider_google => 'Google';

  @override
  String get account_provider_device => 'This device';

  @override
  String get account_sign_out_title => 'Sign out of Eala?';

  @override
  String get account_sign_out_message =>
      'Your goals stay with your account. Sign back in any time to pick up where you left off.';

  @override
  String get account_sign_in_title => 'Keep your goals safe';

  @override
  String get account_sign_in_subtitle => 'So they follow you to any phone.';

  @override
  String get account_sign_in_apple => 'Sign in with Apple';

  @override
  String get account_sign_in_google => 'Sign in with Google';

  @override
  String get account_sign_in_failed =>
      'Couldn’t sign in. Check your connection and try again.';

  @override
  String get account_sign_out_failed =>
      'Couldn’t sign out. Check your connection and try again.';

  @override
  String get account_name_failed =>
      'Couldn’t save your name. Check your connection and try again.';

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
  String get reason_detail_back => 'Goals';

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
  String get reason_detail_purpose => 'Goal';

  @override
  String get reason_detail_why => 'Why';

  @override
  String get reason_detail_tone => 'Tone';

  @override
  String get reason_detail_voice => 'Voice';

  @override
  String get reason_detail_length => 'Length';

  @override
  String reason_detail_length_value(String name, int seconds) {
    return '$name · ${seconds}s';
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
  String get reason_detail_discard_message => 'This goal stays as it is now.';

  @override
  String get reason_detail_keep_editing => 'Keep Editing';

  @override
  String get reason_detail_save_failed =>
      'Couldn’t save your changes. Check your connection and try again.';

  @override
  String get common_more_below => 'More below';

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
  String get reason_actions_delete => 'Delete Goal';

  @override
  String reason_delete_title(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get reason_delete_message => 'This can’t be undone.';

  @override
  String get reason_delete_alarm_message =>
      'Its alarm will be deleted too. Every alarm needs a goal.';

  @override
  String get reason_delete_failed =>
      'Couldn’t delete this goal. Check your connection and try again.';

  @override
  String get common_ok => 'OK';

  @override
  String get create_alarm_title => 'Add Alarm';

  @override
  String get create_alarm_section => 'What you’ll hear';

  @override
  String get create_alarm_choose_reason => 'Choose a goal';

  @override
  String get create_alarm_add_reason => 'Add a goal';

  @override
  String get create_alarm_reason_hint => 'What should Eala say?';

  @override
  String get create_alarm_choose => 'Choose';

  @override
  String get create_alarm_change => 'Change';

  @override
  String get create_alarm_soundtrack => 'Soundtrack';

  @override
  String get create_alarm_alarm_sound => 'Alarm sound';

  @override
  String get create_alarm_ring_again => 'Ring again if I’m not up';

  @override
  String get create_alarm_again_off => 'Off';

  @override
  String get create_alarm_again_once => 'Once';

  @override
  String get create_alarm_again_twice => 'Twice';

  @override
  String create_alarm_again_note_0(String count) {
    return 'Rings $count. Stopping it ends it.';
  }

  @override
  String create_alarm_again_note_1(String count) {
    return '$count, 5 minutes later.';
  }

  @override
  String create_alarm_again_note_2(String count) {
    return '$count, 5 minutes apart.';
  }

  @override
  String get create_alarm_again_count_0 => 'once';

  @override
  String get create_alarm_again_count_1 => '1 more ring';

  @override
  String get create_alarm_again_count_2 => '2 more rings';

  @override
  String get create_alarm_enabled => 'Enabled';

  @override
  String get create_alarm_blocked_title => 'This alarm won’t ring';

  @override
  String get create_alarm_blocked_action => 'Enable Alarm Access';

  @override
  String get create_alarm_save => 'Save Alarm';

  @override
  String get create_alarm_edit_title => 'Edit Alarm';

  @override
  String get create_alarm_save_changes => 'Save Changes';

  @override
  String get create_alarm_delete => 'Delete Alarm';

  @override
  String get create_alarm_save_failed => 'Couldn’t save the alarm. Try again.';

  @override
  String get create_alarm_limit_title => 'Alarm limit';

  @override
  String create_alarm_limit_note(int count) {
    return 'You can have up to $count alarms.';
  }

  @override
  String get create_alarm_add_time => 'Add another time';

  @override
  String get create_alarm_hint_once => 'Rings once · tap days to repeat';

  @override
  String create_alarm_moved(String day, String time) {
    return '$day moved from $time';
  }

  @override
  String create_alarm_day_away(String day, String time) {
    return '$day, rings at $time. Move it here';
  }

  @override
  String create_alarm_card_semantics(String time, String repeat, String hint) {
    return '$time, $repeat. $hint';
  }

  @override
  String get create_alarm_close_clock => 'Close the clock';

  @override
  String get create_alarm_open_clock => 'Change the time';

  @override
  String get create_alarm_hour => 'Hour';

  @override
  String get create_alarm_minute => 'Minute';

  @override
  String get create_alarm_meridiem => 'AM or PM';

  @override
  String get repeat_once => 'Once';

  @override
  String get repeat_every_day => 'Every day';

  @override
  String get repeat_weekdays => 'Weekdays';

  @override
  String get repeat_weekends => 'Weekends';

  @override
  String repeat_every_single(String day) {
    return 'Every $day';
  }

  @override
  String repeat_every_except(String days) {
    return 'Every day except $days';
  }

  @override
  String get day_short => 'Sun,Mon,Tue,Wed,Thu,Fri,Sat';

  @override
  String get day_names =>
      'Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday';

  @override
  String get reason_picker_title => 'What should wake you up?';

  @override
  String get reason_picker_subtitle => 'Each alarm plays one goal.';

  @override
  String get reason_picker_all_taken => 'Every goal already has an alarm.';

  @override
  String get reason_picker_select => 'Select Goal';

  @override
  String get reason_picker_new => 'New Goal';

  @override
  String get reason_picker_none => 'You don’t have any goals yet.';

  @override
  String get soundtrack_sheet_subtitle =>
      'Music that plays behind your message.';

  @override
  String get soundtrack_sheet_select => 'Select Soundtrack';

  @override
  String get alarm_sound_sheet_subtitle => 'Tap play to hear it.';

  @override
  String get alarm_sound_sheet_select => 'Select Sound';

  @override
  String my_alarms_alarm_semantics(
    String time,
    String repeat,
    String reason,
    String status,
  ) {
    return '$time, $repeat. $reason. $status';
  }

  @override
  String get my_alarms_next_alarm => 'Next alarm';

  @override
  String my_alarms_slot_meter_used(int used, int total) {
    return '$used of $total';
  }

  @override
  String my_alarms_next_ring(String when) {
    return 'Next ring · $when';
  }

  @override
  String get my_alarms_tomorrow => 'Tomorrow';

  @override
  String get my_alarms_off => 'Off';

  @override
  String get my_alarms_all_alarms => 'All alarms';

  @override
  String my_alarms_rings_once(String when) {
    return 'Rings $when · once';
  }

  @override
  String my_alarms_in_minutes(int n) {
    return 'in $n min';
  }

  @override
  String my_alarms_in_hours(int h) {
    return 'in $h hr';
  }

  @override
  String my_alarms_in_hours_minutes(int h, int m) {
    return 'in $h hr $m min';
  }

  @override
  String get my_alarms_blocked => 'Won’t ring · Alarm access is off';

  @override
  String get my_alarms_blocked_semantics =>
      'This alarm won’t ring. Alarm access is off.';

  @override
  String my_alarms_switch_semantics(String time) {
    return 'Alarm at $time';
  }

  @override
  String get my_alarms_access_title => 'Alarm access is off';

  @override
  String get my_alarms_delete_title => 'Delete this alarm?';

  @override
  String get my_alarms_delete_message => 'Your goal stays in My Goals.';

  @override
  String my_alarms_delete_semantics(String time) {
    return 'Delete alarm at $time';
  }

  @override
  String get my_alarms_delete_failed =>
      'Couldn’t delete the alarm. Check your connection and try again.';

  @override
  String get my_alarms_toggle_failed => 'Couldn’t change the alarm. Try again.';

  @override
  String get day_letters => 'S,M,T,W,T,F,S';
}
