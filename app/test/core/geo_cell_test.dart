import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heen/core/geo_cell.dart';

/// The same vectors the TypeScript backend is tested against — the app and the
/// server must agree on every cell, or pushes go to the wrong city.
void main() {
  final shared = jsonDecode(File('../shared/test-vectors/cells.json').readAsStringSync()) as Map<String, dynamic>;
  final vectors = (shared['vectors'] as List).cast<Map<String, dynamic>>();

  test('matches every shared vector', () {
    expect(vectors, isNotEmpty);
    for (final v in vectors) {
      final lat = (v['lat'] as num).toDouble();
      final lon = (v['lon'] as num).toDouble();
      final id = v['cell'] as String;
      final center = v['center'] as Map<String, dynamic>;
      expect(cellId(lat, lon), id, reason: v['name'] as String);
      final c = cellCenter(id);
      expect(c.lat, (center['lat'] as num).toDouble(), reason: v['name'] as String);
      expect(c.lon, (center['lon'] as num).toDouble(), reason: v['name'] as String);
    }
  });

  test('rejects bad input', () {
    expect(() => cellId(91, 0), throwsRangeError);
    expect(() => cellId(0, double.nan), throwsRangeError);
    expect(parseCellId('720-0'), isNull);
    expect(parseCellId('1-1440'), isNull);
    expect(parseCellId('31.9,35.9'), isNull);
    expect(parseCellId('487-863'), (latIndex: 487, lonIndex: 863));
  });
}
