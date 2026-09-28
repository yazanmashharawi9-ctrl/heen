import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models.dart';
import '../../content/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../settings/settings.dart';

class MomentScreen extends ConsumerWidget {
  const MomentScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final bundle = ref.watch(contentBundleProvider);

    return bundle.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (b) {
        final moment = b.byId(id);
        if (moment == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l.momentNotFound)),
          );
        }
        final lang = settings.languageCode;
        return Scaffold(
          appBar: AppBar(title: Text(moment.title.of(lang))),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (!moment.isApproved) _DraftBanner(text: l.momentDraftBanner),
              for (final item in moment.items)
                _ItemCard(item: item, languageCode: lang, newMuslimMode: settings.newMuslimMode),
              if (moment.fiqh.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(l.momentFiqh, style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final note in moment.fiqh) _FiqhCard(note: note, languageCode: lang),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.edit_note, color: scheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: scheme.onTertiaryContainer)),
          ),
        ],
      ),
    );
  }
}

/// Arabic is always laid out right-to-left, even inside the English UI.
class _Arabic extends StatelessWidget {
  const _Arabic(this.text, {this.large = false});

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = (large ? Theme.of(context).textTheme.headlineSmall : Theme.of(context).textTheme.titleMedium)
        ?.copyWith(height: 1.9);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.languageCode, required this.newMuslimMode});

  final MomentItem item;
  final String languageCode;
  final bool newMuslimMode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final english = languageCode == 'en';
    final repeat = item.repeat;
    final newMuslim = item.newMuslim;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Arabic(item.ar, large: item.isRecited),
            if (repeat != null && repeat > 1)
              Text(l.momentRepeat(repeat), textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
            if (item.quote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _Arabic('«${item.quote}»'),
              ),
            ],
            if (english && item.translit != null) ...[
              const SizedBox(height: 12),
              Text(
                item.translit!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            if (english) ...[
              const SizedBox(height: 8),
              Text(item.translationEn, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            ],
            const Divider(height: 32),
            Text(item.explain.of(languageCode), style: theme.textTheme.bodyMedium),
            if (newMuslimMode && newMuslim != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.momentNewMuslim, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(newMuslim.of(languageCode)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            _Sources(sources: item.sources),
          ],
        ),
      ),
    );
  }
}

class _Sources extends StatelessWidget {
  const _Sources({required this.sources});

  final List<Source> sources;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(l.momentSources),
      subtitle: Text(sources.map((s) => '${l.collection(s.collection)} ${s.number}').join(' · ')),
      children: [for (final s in sources) _SourceTile(source: s)],
    );
  }
}

class _SourceTile extends ConsumerWidget {
  const _SourceTile({required this.source});

  final Source source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = ref.watch(settingsProvider.select((s) => s.languageCode));
    final bundle = ref.watch(contentBundleProvider).value;
    String name(String n) => bundle?.person(n, lang) ?? n;
    final lines = <String>[
      if (source.narrator != null) l.narratedBy(name(source.narrator!)),
      if (source.type == NarrationType.mawquf) l.sourceMawquf,
      for (final g in source.grades) l.gradedBy(l.grade(g.grade), name(g.by)) + (g.note == null ? '' : ' (${g.note})'),
      if (source.note != null) source.note!,
    ];
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text('${l.collection(source.collection)} ${source.number}'),
      subtitle: Text(lines.join('\n')),
    );
  }
}

class _FiqhCard extends StatelessWidget {
  const _FiqhCard({required this.note, required this.languageCode});

  final FiqhNote note;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: ExpansionTile(
        title: Text(note.topic.of(languageCode)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.momentGeneralView),
            subtitle: Text(note.majority.of(languageCode)),
          ),
          for (final d in note.differences)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.madhhab(d.madhhab)),
              subtitle: Text(d.text.of(languageCode)),
            ),
          if (note.sources.isNotEmpty) _Sources(sources: note.sources),
        ],
      ),
    );
  }
}
