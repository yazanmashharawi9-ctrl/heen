// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Heen';

  @override
  String get appTagline => 'The Sunnah in its moment';

  @override
  String get tabToday => 'Today';

  @override
  String get tabLibrary => 'Library';

  @override
  String get tabSettings => 'Settings';

  @override
  String get todayComingUp => 'Coming up';

  @override
  String get todayWeatherTitle => 'Weather moments';

  @override
  String get todayWeatherBody =>
      'When it rains, thunders or snows where you are, Heen will remind you of the Sunnah for that moment. Coming soon.';

  @override
  String todayWhiteDaysDates(String first, String last) {
    return '$first – $last';
  }

  @override
  String get todayDhulHijjahNote => 'In Dhul-Hijjah the 13th is a Day of Tashrīq, so the White Days start on the 14th.';

  @override
  String get librarySearchHint => 'Search: rain, crescent, fasting…';

  @override
  String get libraryEmpty => 'Nothing matches your search.';

  @override
  String get categoryWeather => 'Weather';

  @override
  String get categoryCalendar => 'Calendar';

  @override
  String get categorySky => 'Sky';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryPlace => 'Places';

  @override
  String get momentDraftBanner => 'Draft — this content has not been reviewed yet.';

  @override
  String get momentSources => 'Sources';

  @override
  String get momentFiqh => 'Fiqh notes';

  @override
  String get momentGeneralView => 'General view';

  @override
  String get momentNewMuslim => 'For new Muslims';

  @override
  String momentRepeat(int count) {
    return '× $count';
  }

  @override
  String get momentNotFound => 'This moment no longer exists.';

  @override
  String get momentOpenSource => 'Open source';

  @override
  String get gradeSahih => 'Sahih';

  @override
  String get gradeHasan => 'Hasan';

  @override
  String get gradeSahihLiGhayrihi => 'Sahih li-ghayrihi';

  @override
  String get gradeHasanLiGhayrihi => 'Hasan li-ghayrihi';

  @override
  String get gradeDaif => 'Weak (da\'if)';

  @override
  String gradedBy(String grade, String by) {
    return '$grade — $by';
  }

  @override
  String narratedBy(String narrator) {
    return 'Narrated by $narrator';
  }

  @override
  String get sourceMawquf => 'Words of a Companion (athar)';

  @override
  String get collectionQuran => 'The Qur\'an';

  @override
  String get collectionBukhari => 'Sahih al-Bukhari';

  @override
  String get collectionMuslim => 'Sahih Muslim';

  @override
  String get collectionAbuDawud => 'Sunan Abi Dawud';

  @override
  String get collectionTirmidhi => 'Jami\' at-Tirmidhi';

  @override
  String get collectionNasai => 'Sunan an-Nasa\'i';

  @override
  String get collectionIbnMajah => 'Sunan Ibn Majah';

  @override
  String get collectionAhmad => 'Musnad Ahmad';

  @override
  String get collectionMalik => 'Muwatta Malik';

  @override
  String get collectionDarimi => 'Sunan ad-Darimi';

  @override
  String get collectionAdabMufrad => 'Al-Adab al-Mufrad';

  @override
  String get collectionBayhaqi => 'Al-Bayhaqi';

  @override
  String get collectionHakim => 'Al-Mustadrak (al-Hakim)';

  @override
  String get collectionIbnHibban => 'Sahih Ibn Hibban';

  @override
  String get collectionOther => 'Other';

  @override
  String get madhhabHanafi => 'Hanafi';

  @override
  String get madhhabMaliki => 'Maliki';

  @override
  String get madhhabShafii => 'Shafi\'i';

  @override
  String get madhhabHanbali => 'Hanbali';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNewMuslim => 'New Muslim mode';

  @override
  String get settingsNewMuslimHint => 'Simple explanations and transliteration for every du\'a';

  @override
  String get settingsHijriOffset => 'Hijri date adjustment';

  @override
  String get settingsHijriOffsetHint =>
      'If your country starts the month a day before or after the Umm al-Qura calendar';

  @override
  String settingsHijriPreview(String date) {
    return 'Today: $date';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutBody =>
      'Heen is free, has no ads and no accounts, and is open source — a sadaqah jariyah. Every text shows its source and grading.';

  @override
  String get settingsNoAdjustment => 'No adjustment';

  @override
  String settingsDaysAhead(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days ahead', one: '1 day ahead');
    return '$_temp0';
  }

  @override
  String settingsDaysBehind(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days behind', one: '1 day behind');
    return '$_temp0';
  }
}
