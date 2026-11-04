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

  /// No description provided for @reasons_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Reasons screen will be here'**
  String get reasons_placeholder;

  /// No description provided for @settings_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Settings screen will be here'**
  String get settings_placeholder;
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
