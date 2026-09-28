import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// App name. Arabic: حِين
  ///
  /// In en, this message translates to:
  /// **'Heen'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'The Sunnah in its moment'**
  String get appTagline;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @todayComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get todayComingUp;

  /// No description provided for @todayWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather moments'**
  String get todayWeatherTitle;

  /// No description provided for @todayWeatherBody.
  ///
  /// In en, this message translates to:
  /// **'When it rains, thunders or snows where you are, Heen will remind you of the Sunnah for that moment. Coming soon.'**
  String get todayWeatherBody;

  /// No description provided for @todayWhiteDaysDates.
  ///
  /// In en, this message translates to:
  /// **'{first} – {last}'**
  String todayWhiteDaysDates(String first, String last);

  /// No description provided for @todayDhulHijjahNote.
  ///
  /// In en, this message translates to:
  /// **'In Dhul-Hijjah the 13th is a Day of Tashrīq, so the White Days start on the 14th.'**
  String get todayDhulHijjahNote;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search: rain, crescent, fasting…'**
  String get librarySearchHint;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches your search.'**
  String get libraryEmpty;

  /// No description provided for @categoryWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get categoryWeather;

  /// No description provided for @categoryCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get categoryCalendar;

  /// No description provided for @categorySky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get categorySky;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryPlace.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get categoryPlace;

  /// No description provided for @momentDraftBanner.
  ///
  /// In en, this message translates to:
  /// **'Draft — this content has not been reviewed yet.'**
  String get momentDraftBanner;

  /// No description provided for @momentSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get momentSources;

  /// No description provided for @momentFiqh.
  ///
  /// In en, this message translates to:
  /// **'Fiqh notes'**
  String get momentFiqh;

  /// No description provided for @momentGeneralView.
  ///
  /// In en, this message translates to:
  /// **'General view'**
  String get momentGeneralView;

  /// No description provided for @momentNewMuslim.
  ///
  /// In en, this message translates to:
  /// **'For new Muslims'**
  String get momentNewMuslim;

  /// No description provided for @momentRepeat.
  ///
  /// In en, this message translates to:
  /// **'× {count}'**
  String momentRepeat(int count);

  /// No description provided for @momentNotFound.
  ///
  /// In en, this message translates to:
  /// **'This moment no longer exists.'**
  String get momentNotFound;

  /// No description provided for @momentOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get momentOpenSource;

  /// No description provided for @gradeSahih.
  ///
  /// In en, this message translates to:
  /// **'Sahih'**
  String get gradeSahih;

  /// No description provided for @gradeHasan.
  ///
  /// In en, this message translates to:
  /// **'Hasan'**
  String get gradeHasan;

  /// No description provided for @gradeSahihLiGhayrihi.
  ///
  /// In en, this message translates to:
  /// **'Sahih li-ghayrihi'**
  String get gradeSahihLiGhayrihi;

  /// No description provided for @gradeHasanLiGhayrihi.
  ///
  /// In en, this message translates to:
  /// **'Hasan li-ghayrihi'**
  String get gradeHasanLiGhayrihi;

  /// No description provided for @gradeDaif.
  ///
  /// In en, this message translates to:
  /// **'Weak (da\'if)'**
  String get gradeDaif;

  /// No description provided for @gradedBy.
  ///
  /// In en, this message translates to:
  /// **'{grade} — {by}'**
  String gradedBy(String grade, String by);

  /// No description provided for @narratedBy.
  ///
  /// In en, this message translates to:
  /// **'Narrated by {narrator}'**
  String narratedBy(String narrator);

  /// No description provided for @sourceMawquf.
  ///
  /// In en, this message translates to:
  /// **'Words of a Companion (athar)'**
  String get sourceMawquf;

  /// No description provided for @collectionQuran.
  ///
  /// In en, this message translates to:
  /// **'The Qur\'an'**
  String get collectionQuran;

  /// No description provided for @collectionBukhari.
  ///
  /// In en, this message translates to:
  /// **'Sahih al-Bukhari'**
  String get collectionBukhari;

  /// No description provided for @collectionMuslim.
  ///
  /// In en, this message translates to:
  /// **'Sahih Muslim'**
  String get collectionMuslim;

  /// No description provided for @collectionAbuDawud.
  ///
  /// In en, this message translates to:
  /// **'Sunan Abi Dawud'**
  String get collectionAbuDawud;

  /// No description provided for @collectionTirmidhi.
  ///
  /// In en, this message translates to:
  /// **'Jami\' at-Tirmidhi'**
  String get collectionTirmidhi;

  /// No description provided for @collectionNasai.
  ///
  /// In en, this message translates to:
  /// **'Sunan an-Nasa\'i'**
  String get collectionNasai;

  /// No description provided for @collectionIbnMajah.
  ///
  /// In en, this message translates to:
  /// **'Sunan Ibn Majah'**
  String get collectionIbnMajah;

  /// No description provided for @collectionAhmad.
  ///
  /// In en, this message translates to:
  /// **'Musnad Ahmad'**
  String get collectionAhmad;

  /// No description provided for @collectionMalik.
  ///
  /// In en, this message translates to:
  /// **'Muwatta Malik'**
  String get collectionMalik;

  /// No description provided for @collectionDarimi.
  ///
  /// In en, this message translates to:
  /// **'Sunan ad-Darimi'**
  String get collectionDarimi;

  /// No description provided for @collectionAdabMufrad.
  ///
  /// In en, this message translates to:
  /// **'Al-Adab al-Mufrad'**
  String get collectionAdabMufrad;

  /// No description provided for @collectionBayhaqi.
  ///
  /// In en, this message translates to:
  /// **'Al-Bayhaqi'**
  String get collectionBayhaqi;

  /// No description provided for @collectionHakim.
  ///
  /// In en, this message translates to:
  /// **'Al-Mustadrak (al-Hakim)'**
  String get collectionHakim;

  /// No description provided for @collectionIbnHibban.
  ///
  /// In en, this message translates to:
  /// **'Sahih Ibn Hibban'**
  String get collectionIbnHibban;

  /// No description provided for @collectionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get collectionOther;

  /// No description provided for @madhhabHanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get madhhabHanafi;

  /// No description provided for @madhhabMaliki.
  ///
  /// In en, this message translates to:
  /// **'Maliki'**
  String get madhhabMaliki;

  /// No description provided for @madhhabShafii.
  ///
  /// In en, this message translates to:
  /// **'Shafi\'i'**
  String get madhhabShafii;

  /// No description provided for @madhhabHanbali.
  ///
  /// In en, this message translates to:
  /// **'Hanbali'**
  String get madhhabHanbali;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsNewMuslim.
  ///
  /// In en, this message translates to:
  /// **'New Muslim mode'**
  String get settingsNewMuslim;

  /// No description provided for @settingsNewMuslimHint.
  ///
  /// In en, this message translates to:
  /// **'Simple explanations and transliteration for every du\'a'**
  String get settingsNewMuslimHint;

  /// No description provided for @settingsHijriOffset.
  ///
  /// In en, this message translates to:
  /// **'Hijri date adjustment'**
  String get settingsHijriOffset;

  /// No description provided for @settingsHijriOffsetHint.
  ///
  /// In en, this message translates to:
  /// **'If your country starts the month a day before or after the Umm al-Qura calendar'**
  String get settingsHijriOffsetHint;

  /// No description provided for @settingsHijriPreview.
  ///
  /// In en, this message translates to:
  /// **'Today: {date}'**
  String settingsHijriPreview(String date);

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Heen is free, has no ads and no accounts, and is open source — a sadaqah jariyah. Every text shows its source and grading.'**
  String get settingsAboutBody;

  /// No description provided for @settingsNoAdjustment.
  ///
  /// In en, this message translates to:
  /// **'No adjustment'**
  String get settingsNoAdjustment;

  /// No description provided for @settingsDaysAhead.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day ahead} other{{days} days ahead}}'**
  String settingsDaysAhead(int days);

  /// No description provided for @settingsDaysBehind.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day behind} other{{days} days behind}}'**
  String settingsDaysBehind(int days);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
