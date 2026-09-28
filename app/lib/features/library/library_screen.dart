import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models.dart';
import '../../content/repository.dart';
import '../../content/search.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../router.dart';
import '../../settings/settings.dart';

final _searchProvider = Provider<MomentSearch?>((ref) {
  final bundle = ref.watch(contentBundleProvider).value;
  return bundle == null ? null : MomentSearch(bundle.moments);
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = ref.watch(settingsProvider.select((s) => s.languageCode));
    final search = ref.watch(_searchProvider);
    final results = search?.query(_query) ?? const <Moment>[];

    return Scaffold(
      appBar: AppBar(title: Text(l.tabLibrary)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: l.librarySearchHint,
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: search == null
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                ? Center(child: Text(l.libraryEmpty))
                : ListView(children: _tiles(context, l, lang, results)),
          ),
        ],
      ),
    );
  }

  List<Widget> _tiles(BuildContext context, AppLocalizations l, String lang, List<Moment> moments) {
    final tiles = <Widget>[];
    for (final category in MomentCategory.values) {
      final inCategory = moments.where((m) => m.category == category).toList();
      if (inCategory.isEmpty) continue;
      tiles.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(l.category(category), style: Theme.of(context).textTheme.titleSmall),
        ),
      );
      for (final m in inCategory) {
        tiles.add(
          ListTile(
            leading: Icon(_icon(category)),
            title: Text(m.title.of(lang)),
            subtitle: Text(
              m.items.first.ar,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
            ),
            trailing: m.isApproved ? null : const Icon(Icons.edit_note, semanticLabel: 'draft'),
            onTap: () => context.push(momentPath(m.id)),
          ),
        );
      }
    }
    return tiles;
  }

  static IconData _icon(MomentCategory c) => switch (c) {
    MomentCategory.weather => Icons.water_drop_outlined,
    MomentCategory.calendar => Icons.calendar_month_outlined,
    MomentCategory.sky => Icons.brightness_4_outlined,
    MomentCategory.travel => Icons.directions_car_outlined,
    MomentCategory.place => Icons.mosque_outlined,
  };
}
