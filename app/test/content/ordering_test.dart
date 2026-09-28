import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heen/content/models.dart';
import 'package:heen/content/ordering.dart';
import 'package:heen/content/repository.dart';

void main() {
  final moments = sortedMoments(parseBundle(File('assets/content/moments.json').readAsStringSync()).moments);
  List<String> ids(MomentCategory c) => [for (final m in moments.where((m) => m.category == c)) m.id];

  test('categories stay together, in enum order', () {
    final order = moments.map((m) => m.category.index).toList();
    expect(order, [...order]..sort());
  });

  test('rain comes first, heat and cold last', () {
    final weather = ids(MomentCategory.weather);
    expect(weather.first, 'weather.rain_start');
    expect(weather.sublist(weather.length - 2), ['weather.heat', 'weather.cold']);
  });

  test('a journey reads from leaving to coming home', () {
    expect(ids(MomentCategory.travel), ['travel.leaving', 'travel.traveler', 'travel.stay_check', 'travel.returning']);
  });

  test('the Hijri year starts with the new month and Ramadan', () {
    expect(ids(MomentCategory.calendar).take(2), ['calendar.month_start', 'calendar.ramadan_start']);
  });
}
