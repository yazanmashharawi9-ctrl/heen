import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sky/hijri_service.dart';

class AppSettings {
  const AppSettings({this.languageCode = 'ar', this.newMuslimMode = false, this.hijriOffset = 0});

  /// 'ar' or 'en'.
  final String languageCode;

  /// Simplified explanations for people new to Islam.
  final bool newMuslimMode;

  /// Whole days, HijriService.minOffset…maxOffset.
  final int hijriOffset;

  AppSettings copyWith({String? languageCode, bool? newMuslimMode, int? hijriOffset}) => AppSettings(
    languageCode: languageCode ?? this.languageCode,
    newMuslimMode: newMuslimMode ?? this.newMuslimMode,
    hijriOffset: hijriOffset ?? this.hijriOffset,
  );
}

abstract interface class SettingsStore {
  Future<AppSettings> load(Locale deviceLocale);
  Future<void> save(AppSettings settings);
}

/// Settings on the device only — nothing about the user leaves the phone.
class PrefsSettingsStore implements SettingsStore {
  PrefsSettingsStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _language = 'settings.language';
  static const _newMuslim = 'settings.newMuslimMode';
  static const _hijriOffset = 'settings.hijriOffset';

  @override
  Future<AppSettings> load(Locale deviceLocale) async {
    final language = await _prefs.getString(_language) ?? (deviceLocale.languageCode == 'ar' ? 'ar' : 'en');
    final offset = await _prefs.getInt(_hijriOffset) ?? 0;
    return AppSettings(
      languageCode: language == 'en' ? 'en' : 'ar',
      newMuslimMode: await _prefs.getBool(_newMuslim) ?? false,
      hijriOffset: offset.clamp(HijriService.minOffset, HijriService.maxOffset),
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    await _prefs.setString(_language, s.languageCode);
    await _prefs.setBool(_newMuslim, s.newMuslimMode);
    await _prefs.setInt(_hijriOffset, s.hijriOffset);
  }
}

/// Both overridden in main() once the stored settings are loaded.
final settingsStoreProvider = Provider<SettingsStore>((ref) => throw UnimplementedError('override in main'));
final initialSettingsProvider = Provider<AppSettings>((ref) => const AppSettings());

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  Future<void> update(AppSettings Function(AppSettings current) change) async {
    state = change(state);
    await ref.read(settingsStoreProvider).save(state);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

final hijriServiceProvider = Provider<HijriService>(
  (ref) => HijriService(offsetDays: ref.watch(settingsProvider.select((s) => s.hijriOffset))),
);
