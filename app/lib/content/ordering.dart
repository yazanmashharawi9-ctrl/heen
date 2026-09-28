import 'models.dart';

/// Order moments the way people meet them, not alphabetically: rain before
/// heat, the Hijri year from the new month through Ramadan to Muharram, and a
/// journey from leaving to coming home.
int compareMoments(Moment a, Moment b) {
  final byCategory = a.category.index.compareTo(b.category.index);
  if (byCategory != 0) return byCategory;
  final byTrigger = _rank(a).compareTo(_rank(b));
  return byTrigger != 0 ? byTrigger : a.id.compareTo(b.id);
}

List<Moment> sortedMoments(Iterable<Moment> moments) => [...moments]..sort(compareMoments);

const _order = <String>[
  // weather
  'RAIN_START', 'RAIN_FIRST_OF_SEASON', 'RAIN_AFTER', 'RAIN_HEAVY', 'THUNDER', 'WIND_STRONG', 'SNOW', 'HEAT', 'COLD',
  // calendar, in the order of the Hijri year, then the weekly and seasonal ones
  'MONTH_START', 'RAMADAN_START', 'LAST_TEN_NIGHTS', 'SHAWWAL_SIX', 'DHUL_HIJJAH_TEN', 'ARAFAH', 'TASUA_ASHURA',
  'AYYAM_AL_BID', 'weekday:5', 'weekday:1', 'fastLength',
  // sky
  'solar', 'lunar',
  // travel
  'LEAVING', 'TRAVELER', 'STAY_CHECK', 'RETURNING',
  // places
  'mosque', 'cemetery',
];

int _rank(Moment m) {
  final t = m.trigger;
  final key = switch (t.type) {
    'weather' || 'travel' => t.event,
    'hijri' => t.rule,
    'weekday' => 'weekday:${t.days.isEmpty ? 0 : t.days.first}',
    'eclipse' || 'place' => t.kind,
    _ => t.type,
  };
  final i = _order.indexOf(key ?? '');
  return i < 0 ? _order.length : i;
}
