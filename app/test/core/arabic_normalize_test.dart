import 'package:flutter_test/flutter_test.dart';
import 'package:heen/core/arabic_normalize.dart';

void main() {
  test('strips tashkeel and tatweel', () {
    expect(normalizeForSearch('اللَّهُمَّ صَيِّبًا نَافِعًا'), 'اللهم صيبا نافعا');
    expect(normalizeForSearch('مـــطر'), 'مطر');
  });

  test('unifies letter variants', () {
    expect(normalizeForSearch('أإآٱ'), 'اااا');
    expect(normalizeForSearch('هدى'), 'هدي');
    expect(normalizeForSearch('رحمة'), 'رحمه');
    expect(normalizeForSearch('مؤمن سائل'), 'مومن سايل');
  });

  test('folds transliteration so plain typing matches', () {
    expect(normalizeForSearch('Allāhumma ṣayyiban nāfiʿā'), 'allahumma sayyiban nafia');
    expect(normalizeForSearch("  Du'a   for RAIN "), 'dua for rain');
  });
}
