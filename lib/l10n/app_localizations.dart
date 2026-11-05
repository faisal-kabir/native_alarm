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

  /// No description provided for @create_reason_areas_error.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the list. Check your connection and try again.'**
  String get create_reason_areas_error;

  /// No description provided for @create_reason_areas_empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to choose from yet.'**
  String get create_reason_areas_empty;

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
