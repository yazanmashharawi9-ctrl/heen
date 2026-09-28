import 'package:intl/intl.dart';

import '../content/models.dart';
import 'app_localizations.dart';

// Localized names for content enums and codes.

extension ContentLabels on AppLocalizations {
  String category(MomentCategory c) => switch (c) {
    MomentCategory.weather => categoryWeather,
    MomentCategory.calendar => categoryCalendar,
    MomentCategory.sky => categorySky,
    MomentCategory.travel => categoryTravel,
    MomentCategory.place => categoryPlace,
  };

  String grade(Grade g) => switch (g) {
    Grade.sahih => gradeSahih,
    Grade.hasan => gradeHasan,
    Grade.sahihLiGhayrihi => gradeSahihLiGhayrihi,
    Grade.hasanLiGhayrihi => gradeHasanLiGhayrihi,
    Grade.daif => gradeDaif,
  };

  String collection(String id) => switch (id) {
    'quran' => collectionQuran,
    'bukhari' => collectionBukhari,
    'muslim' => collectionMuslim,
    'abudawud' => collectionAbuDawud,
    'tirmidhi' => collectionTirmidhi,
    'nasai' => collectionNasai,
    'ibnmajah' => collectionIbnMajah,
    'ahmad' => collectionAhmad,
    'malik' => collectionMalik,
    'darimi' => collectionDarimi,
    'adab_mufrad' => collectionAdabMufrad,
    'bayhaqi' => collectionBayhaqi,
    'hakim' => collectionHakim,
    'ibnhibban' => collectionIbnHibban,
    _ => collectionOther,
  };

  String madhhab(String id) => switch (id) {
    'hanafi' => madhhabHanafi,
    'maliki' => madhhabMaliki,
    'shafii' => madhhabShafii,
    'hanbali' => madhhabHanbali,
    _ => id,
  };

  String hijriOffsetLabel(int days) => days == 0
      ? settingsNoAdjustment
      : days > 0
      ? settingsDaysAhead(days)
      : settingsDaysBehind(-days);
}

/// Weekday, day and month in the UI language, e.g. "الأربعاء 30 سبتمبر".
String formatDay(DateTime d, String languageCode) => DateFormat.MMMMEEEEd(languageCode).format(d);
