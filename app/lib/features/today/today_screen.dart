import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models.dart';
import '../../content/repository.dart';
import '../../core/clock.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../router.dart';
import '../../settings/settings.dart';
import '../../sky/hijri_service.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = ref.watch(settingsProvider.select((s) => s.languageCode));
    final hijri = ref.watch(hijriServiceProvider);
    final now = ref.watch(clockProvider)();
    final bundle = ref.watch(contentBundleProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: bundle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (b) {
          final whiteDaysMoment = b.hijri('AYYAM_AL_BID');
          final crescentMoment = b.hijri('MONTH_START');
          final white = hijri.nextWhiteDays(now);
          final monthStart = hijri.nextMonthStart(now);
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _DateHeader(hijri: hijri.of(now), today: now, languageCode: lang),
              _SectionTitle(l.todayComingUp),
              if (whiteDaysMoment != null)
                _UpcomingCard(
                  moment: whiteDaysMoment,
                  languageCode: lang,
                  icon: Icons.brightness_1_outlined,
                  when: l.todayWhiteDaysDates(formatDay(white.days.first, lang), formatDay(white.days.last, lang)),
                  note: white.isDhulHijjah ? l.todayDhulHijjahNote : null,
                ),
              if (crescentMoment != null)
                _UpcomingCard(
                  moment: crescentMoment,
                  languageCode: lang,
                  icon: Icons.nightlight_outlined,
                  when:
                      '${formatHijri(HijriDate(monthStart.year, monthStart.month, 1, 30), lang)} · ${formatDay(monthStart.date, lang)}',
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.water_drop_outlined),
                  title: Text(l.todayWeatherTitle),
                  subtitle: Text(l.todayWeatherBody),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.hijri, required this.today, required this.languageCode});

  final HijriDate hijri;
  final DateTime today;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatHijri(hijri, languageCode), style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            formatDay(today, languageCode),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.moment,
    required this.languageCode,
    required this.icon,
    required this.when,
    this.note,
  });

  final Moment moment;
  final String languageCode;
  final IconData icon;
  final String when;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(moment.title.of(languageCode)),
        subtitle: Text(note == null ? when : '$when\n$note'),
        isThreeLine: note != null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(momentPath(moment.id)),
      ),
    );
  }
}
