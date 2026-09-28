// The moment bundle as the app reads it (assets/content/moments.json, built
// from content/moments by tools/content/build.ts). The JSON schema in
// content/schema/moment.schema.json is the source of truth for the shape.

typedef JsonMap = Map<String, dynamic>;

class L10nText {
  const L10nText({required this.ar, required this.en});

  factory L10nText.fromJson(Object? json) {
    final m = json! as JsonMap;
    return L10nText(ar: m['ar'] as String, en: m['en'] as String);
  }

  static L10nText? maybe(Object? json) => json == null ? null : L10nText.fromJson(json);

  final String ar;
  final String en;

  String of(String languageCode) => languageCode == 'ar' ? ar : en;
}

enum MomentCategory { weather, calendar, sky, travel, place }

enum ItemKind { dua, dhikr, practice, quran, info }

enum Grade {
  sahih('sahih'),
  hasan('hasan'),
  sahihLiGhayrihi('sahih_li_ghayrihi'),
  hasanLiGhayrihi('hasan_li_ghayrihi'),
  daif('daif');

  const Grade(this.wire);
  final String wire;

  static Grade parse(String value) => values.firstWhere((g) => g.wire == value);
}

enum NarrationType { quran, marfu, mawquf, maqtu }

enum ReviewStatus {
  draft('draft'),
  inReview('in_review'),
  changesRequested('changes_requested'),
  approved('approved');

  const ReviewStatus(this.wire);
  final String wire;

  static ReviewStatus parse(String value) => values.firstWhere((s) => s.wire == value);
}

class Grading {
  const Grading({required this.grade, required this.by, this.note});

  factory Grading.fromJson(JsonMap m) =>
      Grading(grade: Grade.parse(m['grade'] as String), by: m['by'] as String, note: m['note'] as String?);

  final Grade grade;
  final String by;
  final String? note;
}

class Source {
  const Source({
    required this.collection,
    required this.number,
    required this.type,
    this.grades = const [],
    this.numbering,
    this.narrator,
    this.url,
    this.note,
  });

  factory Source.fromJson(JsonMap m) => Source(
    collection: m['collection'] as String,
    number: m['number'] as String,
    type: NarrationType.values.byName(m['type'] as String),
    grades: [for (final g in (m['grades'] as List? ?? const [])) Grading.fromJson(g as JsonMap)],
    numbering: m['numbering'] as String?,
    narrator: m['narrator'] as String?,
    url: m['url'] as String?,
    note: m['note'] as String?,
  );

  final String collection;
  final String number;
  final NarrationType type;
  final List<Grading> grades;
  final String? numbering;
  final String? narrator;
  final String? url;
  final String? note;
}

class MomentItem {
  const MomentItem({
    required this.kind,
    required this.ar,
    required this.translationEn,
    required this.sources,
    required this.explain,
    this.quote,
    this.translit,
    this.repeat,
    this.showAsWeak = false,
    this.newMuslim,
  });

  factory MomentItem.fromJson(JsonMap m) => MomentItem(
    kind: ItemKind.values.byName(m['kind'] as String),
    ar: m['ar'] as String,
    translationEn: (m['tr'] as JsonMap)['en'] as String,
    sources: [for (final s in m['sources'] as List) Source.fromJson(s as JsonMap)],
    explain: L10nText.fromJson(m['explain']),
    quote: m['quote'] as String?,
    translit: m['translit'] as String?,
    repeat: m['repeat'] as int?,
    showAsWeak: m['showAsWeak'] as bool? ?? false,
    newMuslim: L10nText.maybe(m['newMuslim']),
  );

  final ItemKind kind;

  /// Shown large. For du'a, dhikr and Qur'an it is fully vocalised.
  final String ar;
  final String translationEn;
  final List<Source> sources;
  final L10nText explain;
  final String? quote;
  final String? translit;
  final int? repeat;
  final bool showAsWeak;
  final L10nText? newMuslim;

  bool get isRecited => kind == ItemKind.dua || kind == ItemKind.dhikr || kind == ItemKind.quran;
}

class FiqhDifference {
  const FiqhDifference({required this.madhhab, required this.text});
  final String madhhab;
  final L10nText text;
}

class FiqhNote {
  const FiqhNote({required this.topic, required this.majority, this.differences = const [], this.sources = const []});

  factory FiqhNote.fromJson(JsonMap m) => FiqhNote(
    topic: L10nText.fromJson(m['topic']),
    majority: L10nText.fromJson(m['majority']),
    differences: [
      for (final d in (m['differences'] as List? ?? const []))
        FiqhDifference(madhhab: (d as JsonMap)['madhhab'] as String, text: L10nText.fromJson(d['text'])),
    ],
    sources: [for (final s in (m['sources'] as List? ?? const [])) Source.fromJson(s as JsonMap)],
  );

  final L10nText topic;
  final L10nText majority;
  final List<FiqhDifference> differences;
  final List<Source> sources;
}

/// What makes a moment happen. `type` is one of weather, hijri, weekday,
/// fastLength, eclipse, travel, place; the other fields depend on it.
class Trigger {
  const Trigger(this.type, this._raw);

  factory Trigger.fromJson(JsonMap m) => Trigger(m['type'] as String, m);

  final String type;
  final JsonMap _raw;

  String? get event => _raw['event'] as String?;
  String? get rule => _raw['rule'] as String?;
  String? get kind => _raw['kind'] as String?;
  List<int> get days => [for (final d in (_raw['days'] as List? ?? const [])) d as int];
}

class Moment {
  const Moment({
    required this.id,
    required this.rev,
    required this.category,
    required this.trigger,
    required this.defaultOn,
    required this.title,
    required this.pushTitle,
    required this.pushBody,
    required this.items,
    required this.reviewStatus,
    this.fiqh = const [],
    this.shareSlug,
    this.keywordsAr = const [],
    this.keywordsEn = const [],
    this.reviewer,
  });

  factory Moment.fromJson(JsonMap m) {
    final push = m['push'] as JsonMap;
    final keywords = m['keywords'] as JsonMap? ?? const {};
    final review = m['review'] as JsonMap;
    return Moment(
      id: m['id'] as String,
      rev: m['rev'] as int,
      category: MomentCategory.values.byName(m['category'] as String),
      trigger: Trigger.fromJson(m['trigger'] as JsonMap),
      defaultOn: m['defaultOn'] as bool,
      title: L10nText.fromJson(m['title']),
      pushTitle: L10nText.fromJson(push['title']),
      pushBody: L10nText.fromJson(push['body']),
      items: [for (final i in m['items'] as List) MomentItem.fromJson(i as JsonMap)],
      fiqh: [for (final f in (m['fiqh'] as List? ?? const [])) FiqhNote.fromJson(f as JsonMap)],
      shareSlug: L10nText.maybe((m['share'] as JsonMap?)?['slug']),
      keywordsAr: [for (final k in (keywords['ar'] as List? ?? const [])) k as String],
      keywordsEn: [for (final k in (keywords['en'] as List? ?? const [])) k as String],
      reviewStatus: ReviewStatus.parse(review['status'] as String),
      reviewer: review['reviewer'] as String?,
    );
  }

  final String id;
  final int rev;
  final MomentCategory category;
  final Trigger trigger;
  final bool defaultOn;
  final L10nText title;
  final L10nText pushTitle;
  final L10nText pushBody;
  final List<MomentItem> items;
  final List<FiqhNote> fiqh;
  final L10nText? shareSlug;
  final List<String> keywordsAr;
  final List<String> keywordsEn;
  final ReviewStatus reviewStatus;
  final String? reviewer;

  bool get isApproved => reviewStatus == ReviewStatus.approved;
}

class ContentBundle {
  ContentBundle({required this.format, required this.release, required this.contentHash, required this.moments})
    : _byId = {for (final m in moments) m.id: m};

  factory ContentBundle.fromJson(JsonMap m) => ContentBundle(
    format: m['format'] as int,
    release: m['release'] as bool,
    contentHash: m['contentHash'] as String,
    moments: [for (final x in m['moments'] as List) Moment.fromJson(x as JsonMap)],
  );

  final int format;
  final bool release;
  final String contentHash;
  final List<Moment> moments;
  final Map<String, Moment> _byId;

  Moment? byId(String id) => _byId[id];

  Moment? hijri(String rule) => moments.where((m) => m.trigger.type == 'hijri' && m.trigger.rule == rule).firstOrNull;
}
