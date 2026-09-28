import 'dart:math' as math;

/// The weather grid: 0.25° cells, about 28 km north–south.
///
/// The app computes its own cell and only ever sends the cell id to the
/// server, never coordinates. Mirrors
/// `supabase/functions/_shared/geo/cell.ts`; both are checked against
/// `shared/test-vectors/cells.json`.
const double cellDeg = 0.25;
const int _latCells = 720;
const int _lonCells = 1440;
final RegExp _idPattern = RegExp(r'^(\d{1,3})-(\d{1,4})$');

String cellId(double lat, double lon) {
  if (!lat.isFinite || !lon.isFinite || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
    throw RangeError('not a coordinate: $lat, $lon');
  }
  final latIndex = math.min(_latCells - 1, ((lat + 90) / cellDeg).floor());
  // lon + 180 is in [0, 360]; Dart's % is non-negative, and only 360 wraps to 0.
  final x = (lon + 180) % 360;
  final lonIndex = math.min(_lonCells - 1, (x / cellDeg).floor());
  return '$latIndex-$lonIndex';
}

({int latIndex, int lonIndex})? parseCellId(String id) {
  final match = _idPattern.firstMatch(id);
  if (match == null) return null;
  final latIndex = int.parse(match[1]!);
  final lonIndex = int.parse(match[2]!);
  if (latIndex >= _latCells || lonIndex >= _lonCells) return null;
  return (latIndex: latIndex, lonIndex: lonIndex);
}

/// Centre of a cell — where the server asks for the weather.
({double lat, double lon}) cellCenter(String id) {
  final parsed = parseCellId(id);
  if (parsed == null) throw RangeError('not a cell id: $id');
  return (lat: parsed.latIndex * cellDeg - 90 + cellDeg / 2, lon: parsed.lonIndex * cellDeg - 180 + cellDeg / 2);
}
