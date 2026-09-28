// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'حِين';

  @override
  String get appTagline => 'السنّة في لحظتها';

  @override
  String get tabToday => 'اليوم';

  @override
  String get tabLibrary => 'المكتبة';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get todayComingUp => 'القادم';

  @override
  String get todayWeatherTitle => 'لحظات الطقس';

  @override
  String get todayWeatherBody =>
      'عندما ينزل المطر أو يرعد أو يتساقط الثلج حيث أنت، يذكّرك «حِين» بسنّة تلك اللحظة. قريبًا.';

  @override
  String todayWhiteDaysDates(String first, String last) {
    return '$first – $last';
  }

  @override
  String get todayDhulHijjahNote => 'في ذي الحجة: الثالث عشر من أيام التشريق، فتبدأ الأيام البيض من الرابع عشر.';

  @override
  String get librarySearchHint => 'ابحث: مطر، هلال، صيام…';

  @override
  String get libraryEmpty => 'لا توجد نتائج مطابقة.';

  @override
  String get categoryWeather => 'الطقس';

  @override
  String get categoryCalendar => 'التقويم';

  @override
  String get categorySky => 'السماء';

  @override
  String get categoryTravel => 'السفر';

  @override
  String get categoryPlace => 'الأماكن';

  @override
  String get momentDraftBanner => 'مسودة — لم يُراجَع هذا المحتوى بعد.';

  @override
  String get momentSources => 'المصادر';

  @override
  String get momentFiqh => 'مسائل فقهية';

  @override
  String get momentGeneralView => 'القول العام';

  @override
  String get momentNewMuslim => 'للمسلم الجديد';

  @override
  String momentRepeat(int count) {
    return '× $count';
  }

  @override
  String get momentNotFound => 'هذه اللحظة لم تعد موجودة.';

  @override
  String get momentOpenSource => 'افتح المصدر';

  @override
  String get gradeSahih => 'صحيح';

  @override
  String get gradeHasan => 'حسن';

  @override
  String get gradeSahihLiGhayrihi => 'صحيح لغيره';

  @override
  String get gradeHasanLiGhayrihi => 'حسن لغيره';

  @override
  String get gradeDaif => 'ضعيف';

  @override
  String gradedBy(String grade, String by) {
    return '$grade — $by';
  }

  @override
  String narratedBy(String narrator) {
    return 'رواه $narrator';
  }

  @override
  String get sourceMawquf => 'من كلام صحابي (أثر)';

  @override
  String get collectionQuran => 'القرآن الكريم';

  @override
  String get collectionBukhari => 'صحيح البخاري';

  @override
  String get collectionMuslim => 'صحيح مسلم';

  @override
  String get collectionAbuDawud => 'سنن أبي داود';

  @override
  String get collectionTirmidhi => 'سنن الترمذي';

  @override
  String get collectionNasai => 'سنن النسائي';

  @override
  String get collectionIbnMajah => 'سنن ابن ماجه';

  @override
  String get collectionAhmad => 'مسند أحمد';

  @override
  String get collectionMalik => 'موطأ مالك';

  @override
  String get collectionDarimi => 'سنن الدارمي';

  @override
  String get collectionAdabMufrad => 'الأدب المفرد';

  @override
  String get collectionBayhaqi => 'البيهقي';

  @override
  String get collectionHakim => 'المستدرك للحاكم';

  @override
  String get collectionIbnHibban => 'صحيح ابن حبان';

  @override
  String get collectionOther => 'مصدر آخر';

  @override
  String get madhhabHanafi => 'الحنفية';

  @override
  String get madhhabMaliki => 'المالكية';

  @override
  String get madhhabShafii => 'الشافعية';

  @override
  String get madhhabHanbali => 'الحنابلة';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsNewMuslim => 'وضع المسلم الجديد';

  @override
  String get settingsNewMuslimHint => 'شرح مبسّط ونطق لاتيني لكل دعاء';

  @override
  String get settingsHijriOffset => 'تعديل التاريخ الهجري';

  @override
  String get settingsHijriOffsetHint => 'إذا كان بلدك يبدأ الشهر قبل تقويم أم القرى أو بعده بيوم';

  @override
  String settingsHijriPreview(String date) {
    return 'اليوم: $date';
  }

  @override
  String get settingsAbout => 'عن التطبيق';

  @override
  String get settingsAboutBody =>
      '«حِين» مجاني، بلا إعلانات ولا حسابات، ومفتوح المصدر — صدقة جارية. كل نص يظهر معه مصدره ودرجته.';

  @override
  String get settingsNoAdjustment => 'بدون تعديل';

  @override
  String settingsDaysAhead(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'متقدّم بـ$days أيام',
      two: 'متقدّم بيومين',
      one: 'متقدّم بيوم',
    );
    return '$_temp0';
  }

  @override
  String settingsDaysBehind(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'متأخّر بـ$days أيام',
      two: 'متأخّر بيومين',
      one: 'متأخّر بيوم',
    );
    return '$_temp0';
  }
}
