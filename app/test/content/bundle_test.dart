import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heen/content/models.dart';
import 'package:heen/content/repository.dart';
import 'package:heen/content/search.dart';

/// Reads the real bundle the app ships, so a schema change that the Dart
/// models do not understand fails here rather than on a phone.
void main() {
  final bundle = parseBundle(File('assets/content/moments.json').readAsStringSync());

  test('parses every moment', () {
    expect(bundle.format, supportedBundleFormat);
    expect(bundle.moments, isNotEmpty);
    for (final m in bundle.moments) {
      expect(m.items, isNotEmpty, reason: m.id);
      for (final item in m.items) {
        expect(item.sources, isNotEmpty, reason: m.id);
        expect(item.ar, isNotEmpty, reason: m.id);
      }
    }
  });

  test('looks moments up by id and by Hijri rule', () {
    expect(bundle.byId('weather.rain_start')?.trigger.event, 'RAIN_START');
    expect(bundle.hijri('AYYAM_AL_BID')?.id, 'calendar.ayyam_al_bid');
    expect(bundle.hijri('MONTH_START')?.id, 'calendar.month_start');
    expect(bundle.byId('nope'), isNull);
  });

  test('carries sources, gradings and fiqh notes through', () {
    final white = bundle.byId('calendar.ayyam_al_bid')!;
    final source = white.items.first.sources.first;
    expect(source.collection, 'tirmidhi');
    expect(source.grades.first.grade, Grade.hasan);
    expect(white.fiqh.single.sources.single.collection, 'muslim');
    expect(white.reviewStatus, isA<ReviewStatus>());
  });

  test('every narrator and grader has an Arabic name', () {
    for (final m in bundle.moments) {
      final sources = [for (final i in m.items) ...i.sources, for (final f in m.fiqh) ...f.sources];
      for (final s in sources) {
        final names = [if (s.narrator != null) s.narrator!, for (final g in s.grades) g.by];
        for (final n in names) {
          expect(bundle.people[n], isNotNull, reason: '${m.id}: $n');
        }
      }
    }
    expect(bundle.person('Abū Hurayrah', 'ar'), 'أبو هريرة');
    expect(bundle.person('Abū Hurayrah', 'en'), 'Abū Hurayrah');
  });

  test('rejects an unknown bundle format', () {
    expect(
      () => parseBundle('{"format": 99, "release": false, "contentHash": "x", "moments": []}'),
      throwsFormatException,
    );
  });

  group('search', () {
    final search = MomentSearch(bundle.moments);
    List<String> ids(String q) => search.query(q).map((m) => m.id).toList();

    test('empty query returns everything', () => expect(ids('').length, bundle.moments.length));
    test('Arabic without tashkeel finds the vocalised du\'a', () => expect(ids('صيبا نافعا'), ['weather.rain_start']));
    test('Arabic keyword', () => expect(ids('المطر'), contains('weather.rain_start')));
    test('English, any case', () => expect(ids('White Days'), ['calendar.ayyam_al_bid']));
    test('plain transliteration', () => expect(ids('sayyiban'), ['weather.rain_start']));
    test('no match', () => expect(ids('zzzz'), isEmpty));
  });
}
