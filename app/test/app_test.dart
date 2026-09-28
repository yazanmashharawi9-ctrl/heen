import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heen/app.dart';
import 'package:heen/content/repository.dart';
import 'package:heen/core/clock.dart';
import 'package:heen/settings/settings.dart';

// Parsed straight from disk: asset loading through rootBundle caches futures
// across tests, which then never complete inside the next test's fake clock.
final _bundle = parseBundle(File('assets/content/moments.json').readAsStringSync());

class _MemoryStore implements SettingsStore {
  AppSettings saved = const AppSettings();

  @override
  Future<AppSettings> load(Locale deviceLocale) async => saved;

  @override
  Future<void> save(AppSettings settings) async => saved = settings;
}

Future<_MemoryStore> _pumpApp(WidgetTester tester, {AppSettings initial = const AppSettings()}) async {
  final store = _MemoryStore()..saved = initial;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        initialSettingsProvider.overrideWithValue(initial),
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 28, 9)),
        contentBundleProvider.overrideWith((ref) => _bundle),
      ],
      child: const HeenApp(),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('boots in Arabic, right-to-left, with upcoming moments', (tester) async {
    await _pumpApp(tester);
    expect(find.text('حِين'), findsOneWidget);
    expect(find.text('الأيام البيض'), findsOneWidget);
    expect(find.text('رؤية الهلال'), findsOneWidget);
    final direction = Directionality.of(tester.element(find.text('حِين')));
    expect(direction, TextDirection.rtl);
  });

  testWidgets('opens a moment with its source and draft banner', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عند نزول المطر'));
    await tester.pumpAndSettle();
    expect(find.text('اللَّهُمَّ صَيِّبًا نَافِعًا'), findsOneWidget);
    expect(find.textContaining('صحيح البخاري 1032'), findsOneWidget);
    expect(find.text('مسودة — لم يُراجَع هذا المحتوى بعد.'), findsOneWidget);
  });

  testWidgets('switching to English persists and shows transliteration', (tester) async {
    final store = await _pumpApp(tester);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(store.saved.languageCode, 'en');
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('When it rains'));
    await tester.pumpAndSettle();
    expect(find.text('Allāhumma ṣayyiban nāfiʿā'), findsOneWidget);
    expect(find.text('O Allah, make it a beneficial rain.'), findsOneWidget);
  });

  testWidgets('library search narrows results', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'صيام');
    await tester.pumpAndSettle();
    expect(find.text('الأيام البيض'), findsOneWidget);
    expect(find.text('عند نزول المطر'), findsNothing);
  });
}
