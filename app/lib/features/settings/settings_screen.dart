import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../settings/settings.dart';
import '../../sky/hijri_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final hijriToday = ref.watch(hijriServiceProvider).of(ref.watch(clockProvider)());
    final offset = settings.hijriOffset;

    return Scaffold(
      appBar: AppBar(title: Text(l.tabSettings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l.settingsLanguage),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {settings.languageCode},
                onSelectionChanged: (s) => controller.update((c) => c.copyWith(languageCode: s.first)),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(l.settingsNewMuslim),
            subtitle: Text(l.settingsNewMuslimHint),
            value: settings.newMuslimMode,
            onChanged: (v) => controller.update((c) => c.copyWith(newMuslimMode: v)),
          ),
          ListTile(
            title: Text(l.settingsHijriOffset),
            subtitle: Text(
              '${l.settingsHijriOffsetHint}\n'
              '${l.hijriOffsetLabel(offset)} · ${l.settingsHijriPreview(formatHijri(hijriToday, settings.languageCode))}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: offset > HijriService.minOffset
                      ? () => controller.update((c) => c.copyWith(hijriOffset: offset - 1))
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: offset < HijriService.maxOffset
                      ? () => controller.update((c) => c.copyWith(hijriOffset: offset + 1))
                      : null,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: Text(l.settingsAbout),
            subtitle: Text(l.settingsAboutBody),
          ),
        ],
      ),
    );
  }
}
