import 'package:flutter_test/flutter_test.dart';
import 'package:heen/sky/hijri_service.dart';

void main() {
  const uq = HijriService();

  test('Gregorian → Hijri → Gregorian round-trips for every day of a year', () {
    for (var d = DateTime(2026, 1, 1); d.year == 2026; d = DateTime(d.year, d.month, d.day + 1)) {
      final h = uq.of(d);
      expect(uq.toGregorian(h.year, h.month, h.day), d, reason: '$d → $h');
    }
  });

  test('an offset shifts the local date by whole days', () {
    const ahead = HijriService(offsetDays: 1);
    const behind = HijriService(offsetDays: -1);
    final d = DateTime(2026, 9, 28);
    expect(ahead.of(d), uq.of(DateTime(2026, 9, 29)));
    expect(behind.of(d), uq.of(DateTime(2026, 9, 27)));
    final h = ahead.of(d);
    expect(ahead.toGregorian(h.year, h.month, h.day), d);
  });

  test('White Days are the 13th–15th, and still ahead', () {
    final from = DateTime(2026, 9, 28);
    final white = uq.nextWhiteDays(from);
    expect(white.days, isNotEmpty);
    for (final day in white.days) {
      expect(day.isBefore(from), isFalse);
      final h = uq.of(day);
      expect([13, 14, 15], contains(h.day));
      expect((h.year, h.month), (white.year, white.month));
    }
  });

  test('on the 14th, only the 14th and 15th remain; after the 15th it is next month', () {
    final h = uq.of(DateTime(2026, 9, 28));
    final the14th = uq.toGregorian(h.year, h.month, 14);
    expect(uq.nextWhiteDays(the14th).days.map((d) => uq.of(d).day), [14, 15]);
    final the16th = uq.toGregorian(h.year, h.month, 16);
    final next = uq.nextWhiteDays(the16th);
    expect(next.days.map((d) => uq.of(d).day), [13, 14, 15]);
    expect((next.year, next.month), HijriService.nextMonth(h.year, h.month));
  });

  test('in Dhul-Hijjah the 13th (a Day of Tashriq) is skipped', () {
    final start = uq.toGregorian(1448, 12, 1);
    final white = uq.nextWhiteDays(start);
    expect(white.isDhulHijjah, isTrue);
    expect(white.days.map((d) => uq.of(d).day), [14, 15]);
  });

  test('next month start is always a 1st, strictly in the future', () {
    for (var d = DateTime(2026, 1, 1); d.year == 2026; d = DateTime(d.year, d.month, d.day + 7)) {
      final next = uq.nextMonthStart(d);
      expect(next.date.isAfter(d), isTrue);
      expect(uq.of(next.date), HijriDate(next.year, next.month, 1, 0));
    }
  });

  test('Arabic month names are spelled correctly', () {
    expect(formatHijri(const HijriDate(1448, 5, 1, 30), 'ar'), '1 جمادى الأولى 1448 هـ');
    expect(formatHijri(const HijriDate(1448, 12, 10, 30), 'en'), '10 Dhu al-Hijjah 1448 AH');
  });
}
