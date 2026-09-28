import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'router.dart';
import 'settings/settings.dart';

class HeenApp extends ConsumerWidget {
  const HeenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(settingsProvider.select((s) => s.languageCode));
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: Locale(languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: heenTheme(Brightness.light),
      darkTheme: heenTheme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Calm green, the colour of rain on leaves.
const Color heenSeed = Color(0xFF1F6F5C);

ThemeData heenTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: heenSeed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
  );
}
