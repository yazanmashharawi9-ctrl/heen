/// Folds text so that searching "مطر" finds "المَطَر" and "sayyiban" finds
/// "ṣayyiban": strips tashkeel and tatweel, unifies letter variants, and
/// drops the diacritics used in transliterations.
String normalizeForSearch(String input) {
  final s = input
      .replaceAll(_marks, '')
      .replaceAll(_alef, 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .toLowerCase();
  final out = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    if (_dropped.contains(ch)) continue;
    out.write(_latinFolds[ch] ?? ch);
  }
  return out.toString().replaceAll(_spaces, ' ').trim();
}

// Qur'anic annotation marks, tashkeel (fathatan … sukun and friends),
// superscript alef, and tatweel.
final RegExp _marks = RegExp('[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');
final RegExp _alef = RegExp('[أإآٱ]');
final RegExp _spaces = RegExp(r'\s+');

const Set<String> _dropped = {'ʿ', 'ʾ', "'", '’', '‘', '`'};
const Map<String, String> _latinFolds = {
  'ā': 'a',
  'á': 'a',
  'â': 'a',
  'à': 'a',
  'ī': 'i',
  'í': 'i',
  'î': 'i',
  'ū': 'u',
  'ú': 'u',
  'û': 'u',
  'ṣ': 's',
  'š': 's',
  'ḥ': 'h',
  'ṭ': 't',
  'ṯ': 't',
  'ḍ': 'd',
  'ḏ': 'd',
  'ẓ': 'z',
  'ġ': 'g',
};
