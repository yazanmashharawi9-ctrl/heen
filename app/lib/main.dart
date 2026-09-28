import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = PrefsSettingsStore(SharedPreferencesAsync());
  final initial = await store.load(PlatformDispatcher.instance.locale);
  runApp(
    ProviderScope(
      overrides: [settingsStoreProvider.overrideWithValue(store), initialSettingsProvider.overrideWithValue(initial)],
      child: const HeenApp(),
    ),
  );
}
