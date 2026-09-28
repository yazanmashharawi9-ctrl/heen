import '../core/arabic_normalize.dart';
import 'models.dart';

/// Offline search over titles, keywords, the Arabic texts, transliterations
/// and translations. Every query word must appear somewhere in the moment.
class MomentSearch {
  MomentSearch(List<Moment> moments)
    : _entries = [for (final m in moments) (moment: m, text: normalizeForSearch(_haystack(m)))];

  final List<({Moment moment, String text})> _entries;

  List<Moment> query(String query) {
    final words = normalizeForSearch(query).split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return [for (final e in _entries) e.moment];
    return [
      for (final e in _entries)
        if (words.every(e.text.contains)) e.moment,
    ];
  }

  static String _haystack(Moment m) => [
    m.title.ar,
    m.title.en,
    ...m.keywordsAr,
    ...m.keywordsEn,
    for (final item in m.items) ...[item.ar, item.quote ?? '', item.translit ?? '', item.translationEn],
  ].join(' ');
}
