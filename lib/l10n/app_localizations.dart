import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Eala'**
  String get app_name;

  /// No description provided for @alarm_list_empty.
  ///
  /// In en, this message translates to:
  /// **'No alarms yet. Tap + to add one.'**
  String get alarm_list_empty;

  /// No description provided for @common_allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get common_allow;

  /// No description provided for @common_not_now.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get common_not_now;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get common_progress;

  /// No description provided for @common_try_again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get common_try_again;

  /// No description provided for @alarm_permission_title.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get alarm_permission_title;

  /// No description provided for @alarm_permission_notifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so the alarm can alert you.'**
  String get alarm_permission_notifications;

  /// No description provided for @alarm_permission_full_screen.
  ///
  /// In en, this message translates to:
  /// **'Allow full-screen alarms so the alarm screen can appear over the lock screen.'**
  String get alarm_permission_full_screen;

  /// No description provided for @alarm_permission_overlay.
  ///
  /// In en, this message translates to:
  /// **'Allow \"Display over other apps\" so the alarm screen can open while you are using the phone.'**
  String get alarm_permission_overlay;

  /// No description provided for @alarm_permission_exact_alarm.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms so the alarm rings on time.'**
  String get alarm_permission_exact_alarm;

  /// No description provided for @tab_alarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get tab_alarms;

  /// No description provided for @tab_reasons.
  ///
  /// In en, this message translates to:
  /// **'Reasons'**
  String get tab_reasons;

  /// No description provided for @tab_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tab_settings;

  /// No description provided for @my_alarms_title.
  ///
  /// In en, this message translates to:
  /// **'My Alarms'**
  String get my_alarms_title;

  /// No description provided for @my_alarms_your_alarms.
  ///
  /// In en, this message translates to:
  /// **'Your alarms'**
  String get my_alarms_your_alarms;

  /// Alarm limit shown beside the slot pills.
  ///
  /// In en, this message translates to:
  /// **'Up to {count}'**
  String my_alarms_slot_meter_label(int count);

  /// Screen reader label of the slot meter.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} alarms'**
  String my_alarms_slot_meter_semantics(int count);

  /// No description provided for @my_alarms_thought_semantics.
  ///
  /// In en, this message translates to:
  /// **'Today\'s thought'**
  String get my_alarms_thought_semantics;

  /// No description provided for @my_alarms_add_first_alarm_title.
  ///
  /// In en, this message translates to:
  /// **'Set your first alarm'**
  String get my_alarms_add_first_alarm_title;

  /// No description provided for @my_alarms_add_first_alarm_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a time and a reason.'**
  String get my_alarms_add_first_alarm_subtitle;

  /// No description provided for @my_alarms_add_alarm.
  ///
  /// In en, this message translates to:
  /// **'Add alarm'**
  String get my_alarms_add_alarm;

  /// No description provided for @reasons_title.
  ///
  /// In en, this message translates to:
  /// **'My Reasons'**
  String get reasons_title;

  /// No description provided for @reasons_add_first_title.
  ///
  /// In en, this message translates to:
  /// **'Add your first Reason'**
  String get reasons_add_first_title;

  /// No description provided for @reasons_add_first_subtitle.
  ///
  /// In en, this message translates to:
  /// **'The why behind your day.'**
  String get reasons_add_first_subtitle;

  /// No description provided for @reasons_add_label.
  ///
  /// In en, this message translates to:
  /// **'New Reason'**
  String get reasons_add_label;

  /// Second line of a reason row: its area of life and tone.
  ///
  /// In en, this message translates to:
  /// **'{area} · {tone}'**
  String reason_row_subtitle(String area, String tone);

  /// Screen reader label of a reason row; note is empty or one of the alarm notes below.
  ///
  /// In en, this message translates to:
  /// **'{name}. {area}, {tone} tone.{note}'**
  String reason_row_semantics(
    String name,
    String area,
    String tone,
    String note,
  );

  /// Heading of the first Create Reason step. Words between stars are drawn in the brand colour.
  ///
  /// In en, this message translates to:
  /// **'What do you want\nto *wake up for*?'**
  String get create_reason_area_title;

  /// No description provided for @common_list_error.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the list. Check your connection and try again.'**
  String get common_list_error;

  /// No description provided for @common_list_empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to choose from yet.'**
  String get common_list_empty;

  /// Heading of the second Create Reason step. Words between stars are drawn in the brand colour.
  ///
  /// In en, this message translates to:
  /// **'What are you\n*working toward*?'**
  String get create_reason_purpose_title;

  /// No description provided for @create_reason_purpose_hint.
  ///
  /// In en, this message translates to:
  /// **'I’m working toward something that matters to me because…'**
  String get create_reason_purpose_hint;

  /// No description provided for @create_reason_suggestions_label.
  ///
  /// In en, this message translates to:
  /// **'Or start from one of these'**
  String get create_reason_suggestions_label;

  /// No description provided for @suggestions_more_ideas.
  ///
  /// In en, this message translates to:
  /// **'More ideas'**
  String get suggestions_more_ideas;

  /// No description provided for @suggestions_more_ideas_semantics.
  ///
  /// In en, this message translates to:
  /// **'Show more ideas'**
  String get suggestions_more_ideas_semantics;

  /// No description provided for @suggestions_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load ideas.'**
  String get suggestions_load_failed;

  /// Heading of the optional fourth Create Reason step. Words between stars are drawn in the brand colour.
  ///
  /// In en, this message translates to:
  /// **'Why does it\n*matter to you*?'**
  String get create_reason_matter_title;

  /// No description provided for @create_reason_matter_for.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get create_reason_matter_for;

  /// No description provided for @create_reason_matter_hint.
  ///
  /// In en, this message translates to:
  /// **'This matters to me because…'**
  String get create_reason_matter_hint;

  /// No description provided for @create_reason_matter_too_short.
  ///
  /// In en, this message translates to:
  /// **'A few more words, or clear it to skip.'**
  String get create_reason_matter_too_short;

  /// No description provided for @common_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get common_optional;

  /// No description provided for @common_skip_for_now.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get common_skip_for_now;

  /// No description provided for @quoted_text.
  ///
  /// In en, this message translates to:
  /// **'“{text}”'**
  String quoted_text(String text);

  /// Heading of the last Create Reason step. Words between stars are drawn in the brand colour.
  ///
  /// In en, this message translates to:
  /// **'How should it *sound*?'**
  String get create_reason_sound_title;

  /// No description provided for @create_reason_sound_semantics.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get create_reason_sound_semantics;

  /// No description provided for @create_reason_example.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get create_reason_example;

  /// No description provided for @create_reason_example_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the example.'**
  String get create_reason_example_failed;

  /// No description provided for @create_reason_length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get create_reason_length;

  /// No description provided for @create_reason_length_30.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get create_reason_length_30;

  /// No description provided for @create_reason_length_30_note.
  ///
  /// In en, this message translates to:
  /// **'Quick and to the point.'**
  String get create_reason_length_30_note;

  /// No description provided for @create_reason_length_45.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get create_reason_length_45;

  /// No description provided for @create_reason_length_45_note.
  ///
  /// In en, this message translates to:
  /// **'A full thought, not a ramble.'**
  String get create_reason_length_45_note;

  /// No description provided for @create_reason_create.
  ///
  /// In en, this message translates to:
  /// **'Create Reason'**
  String get create_reason_create;

  /// No description provided for @seconds_short.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec'**
  String seconds_short(int seconds);

  /// Heading after a reason is saved. Words between stars are drawn in the brand colour.
  ///
  /// In en, this message translates to:
  /// **'Your reason is *ready*.'**
  String get reason_ready_title;

  /// No description provided for @reason_ready_announcement.
  ///
  /// In en, this message translates to:
  /// **'Your reason is ready.'**
  String get reason_ready_announcement;

  /// No description provided for @reason_ready_why.
  ///
  /// In en, this message translates to:
  /// **'Why it matters'**
  String get reason_ready_why;

  /// No description provided for @reason_ready_voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get reason_ready_voice;

  /// No description provided for @reason_ready_tone.
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get reason_ready_tone;

  /// No description provided for @reason_ready_use_with_alarm.
  ///
  /// In en, this message translates to:
  /// **'Use with alarm'**
  String get reason_ready_use_with_alarm;

  /// No description provided for @reason_ready_save_for_later.
  ///
  /// In en, this message translates to:
  /// **'Save for later'**
  String get reason_ready_save_for_later;

  /// No description provided for @reason_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Name this reason'**
  String get reason_name_hint;

  /// No description provided for @reason_name_label.
  ///
  /// In en, this message translates to:
  /// **'Reason name'**
  String get reason_name_label;

  /// No description provided for @reason_name_save.
  ///
  /// In en, this message translates to:
  /// **'Save name'**
  String get reason_name_save;

  /// No description provided for @reason_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save your reason. Check your connection and try again.'**
  String get reason_save_failed;

  /// No description provided for @reason_rename_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t rename it. Check your connection and try again.'**
  String get reason_rename_failed;

  /// No description provided for @common_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get common_saving;

  /// Heading of the third Create Reason step. Words between stars are drawn in the brand colour.
  ///
  /// In en, this message translates to:
  /// **'Who should *say it*?'**
  String get create_reason_voice_title;

  /// No description provided for @voice_play.
  ///
  /// In en, this message translates to:
  /// **'Hear {name}'**
  String voice_play(String name);

  /// No description provided for @voice_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}'**
  String voice_stop(String name);

  /// No description provided for @voice_group_semantics.
  ///
  /// In en, this message translates to:
  /// **'{group} voices'**
  String voice_group_semantics(String group);

  /// No description provided for @voice_play_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t play this voice. Check your connection and try again.'**
  String get voice_play_failed;

  /// Between short facts on one line, e.g. Female · American · Warm.
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get list_separator;

  /// No description provided for @dictation_start.
  ///
  /// In en, this message translates to:
  /// **'Say it out loud'**
  String get dictation_start;

  /// No description provided for @dictation_discard.
  ///
  /// In en, this message translates to:
  /// **'Discard what you said'**
  String get dictation_discard;

  /// No description provided for @dictation_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop and use what you said'**
  String get dictation_stop;

  /// No description provided for @dictation_listening.
  ///
  /// In en, this message translates to:
  /// **'Listening… say it however it comes out.'**
  String get dictation_listening;

  /// No description provided for @dictation_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input isn’t available. Allow the microphone and speech recognition for Eala in Settings.'**
  String get dictation_unavailable;

  /// Characters typed out of the maximum, shown under a text field near its limit.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String text_counter(int count, int max);

  /// No description provided for @reason_alarm_on_note.
  ///
  /// In en, this message translates to:
  /// **' Played by an alarm.'**
  String get reason_alarm_on_note;

  /// No description provided for @reason_alarm_off_note.
  ///
  /// In en, this message translates to:
  /// **' Its alarm is off.'**
  String get reason_alarm_off_note;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_set_your_name.
  ///
  /// In en, this message translates to:
  /// **'Set your name'**
  String get settings_set_your_name;

  /// No description provided for @settings_not_signed_in.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get settings_not_signed_in;

  /// Screen reader label of the account card.
  ///
  /// In en, this message translates to:
  /// **'{name}. {subtitle}'**
  String settings_profile_semantics(String name, String subtitle);

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_notify_billing.
  ///
  /// In en, this message translates to:
  /// **'Trial & billing'**
  String get settings_notify_billing;

  /// No description provided for @settings_notify_alarms.
  ///
  /// In en, this message translates to:
  /// **'Alarm reminders'**
  String get settings_notify_alarms;

  /// No description provided for @settings_notify_quotes.
  ///
  /// In en, this message translates to:
  /// **'Thoughts for the day'**
  String get settings_notify_quotes;

  /// No description provided for @settings_notifications_note.
  ///
  /// In en, this message translates to:
  /// **'These settings don’t affect your alarms.'**
  String get settings_notifications_note;

  /// No description provided for @settings_subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settings_subscription;

  /// No description provided for @settings_plan_free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get settings_plan_free;

  /// No description provided for @settings_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settings_support;

  /// No description provided for @settings_help.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settings_help;

  /// No description provided for @settings_faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get settings_faq;

  /// No description provided for @settings_request_feature.
  ///
  /// In en, this message translates to:
  /// **'Request a feature'**
  String get settings_request_feature;

  /// No description provided for @settings_leave_review.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get settings_leave_review;

  /// No description provided for @settings_legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settings_legal;

  /// No description provided for @settings_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settings_privacy;

  /// No description provided for @settings_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get settings_terms;

  /// No description provided for @settings_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_account;

  /// No description provided for @settings_sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get settings_sign_in;

  /// No description provided for @settings_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settings_delete_account;

  /// App name, version and build number at the bottom of Settings.
  ///
  /// In en, this message translates to:
  /// **'{name} {version} ({build})'**
  String settings_version(String name, String version, String build);

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @sheet_no_changes.
  ///
  /// In en, this message translates to:
  /// **'No Changes'**
  String get sheet_no_changes;

  /// No description provided for @sheet_use_this.
  ///
  /// In en, this message translates to:
  /// **'Use This'**
  String get sheet_use_this;

  /// No description provided for @sheet_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get sheet_remove;

  /// Button of a choice sheet once another row is chosen, e.g. "Use Career".
  ///
  /// In en, this message translates to:
  /// **'Use {name}'**
  String sheet_use_choice(String name);

  /// No description provided for @reason_detail_about.
  ///
  /// In en, this message translates to:
  /// **'What it’s about'**
  String get reason_detail_about;

  /// No description provided for @reason_detail_speaks.
  ///
  /// In en, this message translates to:
  /// **'How it speaks'**
  String get reason_detail_speaks;

  /// No description provided for @reason_detail_alarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get reason_detail_alarm;

  /// No description provided for @reason_detail_no_alarm.
  ///
  /// In en, this message translates to:
  /// **'Not in an alarm yet.'**
  String get reason_detail_no_alarm;

  /// No description provided for @reason_detail_area.
  ///
  /// In en, this message translates to:
  /// **'Area of life'**
  String get reason_detail_area;

  /// No description provided for @reason_detail_purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get reason_detail_purpose;

  /// No description provided for @reason_detail_why.
  ///
  /// In en, this message translates to:
  /// **'Why it matters'**
  String get reason_detail_why;

  /// No description provided for @reason_detail_tone.
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get reason_detail_tone;

  /// No description provided for @reason_detail_voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get reason_detail_voice;

  /// No description provided for @reason_detail_length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get reason_detail_length;

  /// No description provided for @reason_detail_length_value.
  ///
  /// In en, this message translates to:
  /// **'{name} · {seconds} sec'**
  String reason_detail_length_value(String name, int seconds);

  /// A row of the reason screen for screen readers.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}.{changed} Change'**
  String reason_detail_row_semantics(
    String label,
    String value,
    String changed,
  );

  /// No description provided for @reason_detail_changed_note.
  ///
  /// In en, this message translates to:
  /// **' Changed, not saved.'**
  String get reason_detail_changed_note;

  /// No description provided for @reason_detail_save.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get reason_detail_save;

  /// No description provided for @reason_detail_discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get reason_detail_discard;

  /// No description provided for @reason_detail_caption.
  ///
  /// In en, this message translates to:
  /// **'Changes will apply from your next new message.'**
  String get reason_detail_caption;

  /// No description provided for @reason_detail_discard_title.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get reason_detail_discard_title;

  /// No description provided for @reason_detail_discard_message.
  ///
  /// In en, this message translates to:
  /// **'This reason stays as it is now.'**
  String get reason_detail_discard_message;

  /// No description provided for @reason_detail_keep_editing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get reason_detail_keep_editing;

  /// No description provided for @reason_detail_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save your changes. Check your connection and try again.'**
  String get reason_detail_save_failed;

  /// No description provided for @common_more_below.
  ///
  /// In en, this message translates to:
  /// **'More below'**
  String get common_more_below;

  /// No description provided for @reason_detail_area_sheet.
  ///
  /// In en, this message translates to:
  /// **'What part of life is this for?'**
  String get reason_detail_area_sheet;

  /// No description provided for @reason_detail_keep_area.
  ///
  /// In en, this message translates to:
  /// **'Keep This Area'**
  String get reason_detail_keep_area;

  /// No description provided for @reason_detail_purpose_sheet.
  ///
  /// In en, this message translates to:
  /// **'What are you working toward?'**
  String get reason_detail_purpose_sheet;

  /// No description provided for @reason_detail_why_sheet.
  ///
  /// In en, this message translates to:
  /// **'Why does it matter to you?'**
  String get reason_detail_why_sheet;

  /// No description provided for @reason_detail_purpose_short.
  ///
  /// In en, this message translates to:
  /// **'A few more words, so we can write for you.'**
  String get reason_detail_purpose_short;

  /// No description provided for @reason_detail_why_short.
  ///
  /// In en, this message translates to:
  /// **'A little more, if you can.'**
  String get reason_detail_why_short;

  /// No description provided for @reason_detail_tone_sheet.
  ///
  /// In en, this message translates to:
  /// **'How should it talk to you?'**
  String get reason_detail_tone_sheet;

  /// No description provided for @reason_detail_keep_tone.
  ///
  /// In en, this message translates to:
  /// **'Keep This Tone'**
  String get reason_detail_keep_tone;

  /// No description provided for @reason_detail_voice_sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose a voice'**
  String get reason_detail_voice_sheet;

  /// No description provided for @reason_detail_keep_voice.
  ///
  /// In en, this message translates to:
  /// **'Keep This Voice'**
  String get reason_detail_keep_voice;

  /// No description provided for @reason_detail_length_sheet.
  ///
  /// In en, this message translates to:
  /// **'How long should it speak?'**
  String get reason_detail_length_sheet;

  /// No description provided for @reason_detail_keep_length.
  ///
  /// In en, this message translates to:
  /// **'Keep This Length'**
  String get reason_detail_keep_length;

  /// No description provided for @reason_detail_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get reason_detail_more;

  /// No description provided for @reason_detail_connect_alarm.
  ///
  /// In en, this message translates to:
  /// **'Connect an alarm'**
  String get reason_detail_connect_alarm;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @reason_actions_use_with_alarm.
  ///
  /// In en, this message translates to:
  /// **'Use with an alarm'**
  String get reason_actions_use_with_alarm;

  /// No description provided for @reason_actions_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete Reason'**
  String get reason_actions_delete;

  /// Asks before a reason is deleted.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String reason_delete_title(String name);

  /// No description provided for @reason_delete_message.
  ///
  /// In en, this message translates to:
  /// **'This can’t be undone.'**
  String get reason_delete_message;

  /// No description provided for @reason_delete_alarm_message.
  ///
  /// In en, this message translates to:
  /// **'Its alarm will be deleted too. Every alarm needs a reason.'**
  String get reason_delete_alarm_message;

  /// No description provided for @reason_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t delete this reason. Check your connection and try again.'**
  String get reason_delete_failed;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// Title of the alarm editor for a new alarm.
  ///
  /// In en, this message translates to:
  /// **'Add Alarm'**
  String get create_alarm_title;

  /// No description provided for @create_alarm_section.
  ///
  /// In en, this message translates to:
  /// **'What you’ll hear'**
  String get create_alarm_section;

  /// No description provided for @create_alarm_choose_reason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason'**
  String get create_alarm_choose_reason;

  /// When there is no reason left to pick: the tap opens the reason maker.
  ///
  /// In en, this message translates to:
  /// **'Add a reason'**
  String get create_alarm_add_reason;

  /// No description provided for @create_alarm_reason_hint.
  ///
  /// In en, this message translates to:
  /// **'What should Eala say?'**
  String get create_alarm_reason_hint;

  /// No description provided for @create_alarm_choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get create_alarm_choose;

  /// No description provided for @create_alarm_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get create_alarm_change;

  /// No description provided for @create_alarm_soundtrack.
  ///
  /// In en, this message translates to:
  /// **'Soundtrack'**
  String get create_alarm_soundtrack;

  /// No description provided for @create_alarm_alarm_sound.
  ///
  /// In en, this message translates to:
  /// **'Alarm sound'**
  String get create_alarm_alarm_sound;

  /// No description provided for @create_alarm_ring_again.
  ///
  /// In en, this message translates to:
  /// **'Ring again if I’m not up'**
  String get create_alarm_ring_again;

  /// No description provided for @create_alarm_again_off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get create_alarm_again_off;

  /// No description provided for @create_alarm_again_once.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get create_alarm_again_once;

  /// No description provided for @create_alarm_again_twice.
  ///
  /// In en, this message translates to:
  /// **'Twice'**
  String get create_alarm_again_twice;

  /// Under "Ring again" = Off; {count} is create_alarm_again_count_0, drawn white.
  ///
  /// In en, this message translates to:
  /// **'Rings {count}. Stopping it ends it.'**
  String create_alarm_again_note_0(String count);

  /// Ring again = Once; {count} is drawn white.
  ///
  /// In en, this message translates to:
  /// **'{count}, 5 minutes later.'**
  String create_alarm_again_note_1(String count);

  /// Ring again = Twice; {count} is drawn white.
  ///
  /// In en, this message translates to:
  /// **'{count}, 5 minutes apart.'**
  String create_alarm_again_note_2(String count);

  /// No description provided for @create_alarm_again_count_0.
  ///
  /// In en, this message translates to:
  /// **'once'**
  String get create_alarm_again_count_0;

  /// No description provided for @create_alarm_again_count_1.
  ///
  /// In en, this message translates to:
  /// **'1 more ring'**
  String get create_alarm_again_count_1;

  /// No description provided for @create_alarm_again_count_2.
  ///
  /// In en, this message translates to:
  /// **'2 more rings'**
  String get create_alarm_again_count_2;

  /// No description provided for @create_alarm_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get create_alarm_enabled;

  /// No description provided for @create_alarm_blocked_title.
  ///
  /// In en, this message translates to:
  /// **'This alarm won’t ring'**
  String get create_alarm_blocked_title;

  /// No description provided for @create_alarm_blocked_action.
  ///
  /// In en, this message translates to:
  /// **'Enable Alarm Access'**
  String get create_alarm_blocked_action;

  /// No description provided for @create_alarm_save.
  ///
  /// In en, this message translates to:
  /// **'Save Alarm'**
  String get create_alarm_save;

  /// No description provided for @create_alarm_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the alarm. Try again.'**
  String get create_alarm_save_failed;

  /// No description provided for @create_alarm_limit_title.
  ///
  /// In en, this message translates to:
  /// **'Alarm limit'**
  String get create_alarm_limit_title;

  /// No description provided for @create_alarm_limit_note.
  ///
  /// In en, this message translates to:
  /// **'You can have up to {count} alarms.'**
  String create_alarm_limit_note(int count);

  /// No description provided for @create_alarm_add_time.
  ///
  /// In en, this message translates to:
  /// **'Add another time'**
  String get create_alarm_add_time;

  /// No description provided for @create_alarm_hint_once.
  ///
  /// In en, this message translates to:
  /// **'Rings once · tap days to repeat'**
  String get create_alarm_hint_once;

  /// A day moved to another time card; shown for a moment.
  ///
  /// In en, this message translates to:
  /// **'{day} moved from {time}'**
  String create_alarm_moved(String day, String time);

  /// Screen reader: a day another time card rings.
  ///
  /// In en, this message translates to:
  /// **'{day}, rings at {time}. Move it here'**
  String create_alarm_day_away(String day, String time);

  /// Screen reader: a time card header.
  ///
  /// In en, this message translates to:
  /// **'{time}, {repeat}. {hint}'**
  String create_alarm_card_semantics(String time, String repeat, String hint);

  /// No description provided for @create_alarm_close_clock.
  ///
  /// In en, this message translates to:
  /// **'Close the clock'**
  String get create_alarm_close_clock;

  /// No description provided for @create_alarm_open_clock.
  ///
  /// In en, this message translates to:
  /// **'Change the time'**
  String get create_alarm_open_clock;

  /// No description provided for @create_alarm_hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get create_alarm_hour;

  /// No description provided for @create_alarm_minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get create_alarm_minute;

  /// No description provided for @create_alarm_meridiem.
  ///
  /// In en, this message translates to:
  /// **'AM or PM'**
  String get create_alarm_meridiem;

  /// No description provided for @repeat_once.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get repeat_once;

  /// No description provided for @repeat_every_day.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeat_every_day;

  /// No description provided for @repeat_weekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get repeat_weekdays;

  /// No description provided for @repeat_weekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get repeat_weekends;

  /// No description provided for @repeat_every_single.
  ///
  /// In en, this message translates to:
  /// **'Every {day}'**
  String repeat_every_single(String day);

  /// No description provided for @repeat_every_except.
  ///
  /// In en, this message translates to:
  /// **'Every day except {days}'**
  String repeat_every_except(String days);

  /// The seven short day names, Sunday first, comma-separated.
  ///
  /// In en, this message translates to:
  /// **'Sun,Mon,Tue,Wed,Thu,Fri,Sat'**
  String get day_short;

  /// The seven day names, Sunday first, comma-separated.
  ///
  /// In en, this message translates to:
  /// **'Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday'**
  String get day_names;

  /// No description provided for @reason_picker_title.
  ///
  /// In en, this message translates to:
  /// **'What should wake you up?'**
  String get reason_picker_title;

  /// No description provided for @reason_picker_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Each alarm plays one reason.'**
  String get reason_picker_subtitle;

  /// No description provided for @reason_picker_all_taken.
  ///
  /// In en, this message translates to:
  /// **'Every reason already has an alarm.'**
  String get reason_picker_all_taken;

  /// No description provided for @reason_picker_select.
  ///
  /// In en, this message translates to:
  /// **'Select Reason'**
  String get reason_picker_select;

  /// No description provided for @reason_picker_new.
  ///
  /// In en, this message translates to:
  /// **'New Reason'**
  String get reason_picker_new;

  /// No description provided for @reason_picker_none.
  ///
  /// In en, this message translates to:
  /// **'You don’t have any reasons yet.'**
  String get reason_picker_none;

  /// No description provided for @soundtrack_sheet_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Music that plays behind your message.'**
  String get soundtrack_sheet_subtitle;

  /// No description provided for @soundtrack_sheet_select.
  ///
  /// In en, this message translates to:
  /// **'Select Soundtrack'**
  String get soundtrack_sheet_select;

  /// No description provided for @alarm_sound_sheet_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap play to hear it.'**
  String get alarm_sound_sheet_subtitle;

  /// No description provided for @alarm_sound_sheet_select.
  ///
  /// In en, this message translates to:
  /// **'Select Sound'**
  String get alarm_sound_sheet_select;

  /// Screen reader: one alarm card.
  ///
  /// In en, this message translates to:
  /// **'{time}, {repeat}. {reason}. {status}'**
  String my_alarms_alarm_semantics(
    String time,
    String repeat,
    String reason,
    String status,
  );

  /// No description provided for @my_alarms_status_on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get my_alarms_status_on;

  /// No description provided for @my_alarms_status_off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get my_alarms_status_off;

  /// The section title once there is an alarm.
  ///
  /// In en, this message translates to:
  /// **'Next alarm'**
  String get my_alarms_next_alarm;

  /// Beside the slot pills once there is an alarm.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total}'**
  String my_alarms_slot_meter_used(int used, int total);

  /// No description provided for @my_alarms_next_ring.
  ///
  /// In en, this message translates to:
  /// **'Next ring · {when}'**
  String my_alarms_next_ring(String when);

  /// No description provided for @my_alarms_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get my_alarms_today;

  /// No description provided for @my_alarms_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get my_alarms_tomorrow;

  /// No description provided for @my_alarms_off_note.
  ///
  /// In en, this message translates to:
  /// **'Off · won’t ring'**
  String get my_alarms_off_note;

  /// No description provided for @my_alarms_toggle_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t change the alarm. Try again.'**
  String get my_alarms_toggle_failed;

  /// The seven one-letter day names, Sunday first, comma-separated.
  ///
  /// In en, this message translates to:
  /// **'S,M,T,W,T,F,S'**
  String get day_letters;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
