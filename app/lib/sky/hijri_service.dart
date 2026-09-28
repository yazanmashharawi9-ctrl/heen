import 'package:hijri/hijri_calendar.dart';

/// A Hijri date on the Umm al-Qura calendar, after the user's adjustment.
class HijriDate {
  const HijriDate(this.year, this.month, this.day, this.lengthOfMonth);

  final int year;
  final int month;
  final int day;
  final int lengthOfMonth;

  @override
  bool operator ==(Object other) =>
      other is HijriDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year-$month-$day';
}

/// Days of one Hijri month's White Days that are still ahead.
class WhiteDays {
  const WhiteDays({required this.year, required this.month, required this.days});

  final int year;
  final int month;

  /// Gregorian dates, earliest first.
  final List<DateTime> days;

  /// The 13th of Dhul-Hijjah is a Day of Tashrīq, when fasting is not allowed.
  bool get isDhulHijjah => month == 12;
}

/// Umm al-Qura conversions with a whole-day adjustment for countries whose
/// announced month starts differ (the user's setting, ±2 days).
///
/// `offsetDays` = +1 means the local Hijri date is one day ahead of Umm
/// al-Qura: local(g) = UmmAlQura(g + offset). Supported range 1356–1500 AH.
///
/// Dates are calendar days; the Hijri day actually starts at Maghrib, which
/// the notification scheduler accounts for.
class HijriService {
  const HijriService({this.offsetDays = 0});

  final int offsetDays;

  static const int minOffset = -2;
  static const int maxOffset = 2;

  HijriDate of(DateTime gregorian) {
    final h = HijriCalendar.fromDate(DateTime(gregorian.year, gregorian.month, gregorian.day + offsetDays));
    return HijriDate(h.hYear, h.hMonth, h.hDay, h.lengthOfMonth);
  }

  DateTime toGregorian(int year, int month, int day) {
    final g = HijriCalendar().hijriToGregorian(year, month, day);
    return DateTime(g.year, g.month, g.day - offsetDays);
  }

  static List<int> whiteDayNumbers(int month) => month == 12 ? const [14, 15] : const [13, 14, 15];

  static (int, int) nextMonth(int year, int month) => month == 12 ? (year + 1, 1) : (year, month + 1);

  /// This month's White Days if any are still ahead (today counts), else next month's.
  WhiteDays nextWhiteDays(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    final h = of(today);
    final current = _whiteDays(h.year, h.month).where((d) => !d.isBefore(today)).toList();
    if (current.isNotEmpty) return WhiteDays(year: h.year, month: h.month, days: current);
    final (y, m) = nextMonth(h.year, h.month);
    return WhiteDays(year: y, month: m, days: _whiteDays(y, m));
  }

  /// Gregorian date of the next 1st of a Hijri month strictly after [from].
  ({int year, int month, DateTime date}) nextMonthStart(DateTime from) {
    final h = of(from);
    final (y, m) = nextMonth(h.year, h.month);
    return (year: y, month: m, date: toGregorian(y, m, 1));
  }

  List<DateTime> _whiteDays(int year, int month) => [
    for (final d in whiteDayNumbers(month)) toGregorian(year, month, d),
  ];
}

const Map<int, String> hijriMonthsAr = {
  1: 'محرّم',
  2: 'صفر',
  3: 'ربيع الأول',
  4: 'ربيع الآخر',
  5: 'جمادى الأولى',
  6: 'جمادى الآخرة',
  7: 'رجب',
  8: 'شعبان',
  9: 'رمضان',
  10: 'شوّال',
  11: 'ذو القعدة',
  12: 'ذو الحجة',
};

const Map<int, String> hijriMonthsEn = {
  1: 'Muharram',
  2: 'Safar',
  3: 'Rabiʿ al-Awwal',
  4: 'Rabiʿ al-Akhir',
  5: 'Jumada al-Ula',
  6: 'Jumada al-Akhirah',
  7: 'Rajab',
  8: 'Shaʿban',
  9: 'Ramadan',
  10: 'Shawwal',
  11: 'Dhu al-Qaʿdah',
  12: 'Dhu al-Hijjah',
};

String formatHijri(HijriDate d, String languageCode) => languageCode == 'ar'
    ? '${d.day} ${hijriMonthsAr[d.month]} ${d.year} هـ'
    : '${d.day} ${hijriMonthsEn[d.month]} ${d.year} AH';
