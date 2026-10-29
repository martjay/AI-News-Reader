import 'models.dart';

class TimelineSection {
  const TimelineSection({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.items,
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final List<NewsItem> items;

  String title(bool chinese) => chinese ? titleZh : titleEn;
}

class SpotlightGroup {
  const SpotlightGroup({
    required this.category,
    required this.titleZh,
    required this.titleEn,
    this.limit,
  });

  final SourceCategory category;
  final String titleZh;
  final String titleEn;
  final int? limit;
}

const defaultSpotlights = [
  SpotlightGroup(category: SourceCategory.labs, titleZh: '实验室发布', titleEn: 'Lab releases', limit: 12),
  SpotlightGroup(category: SourceCategory.papers, titleZh: '论文与预印本', titleEn: 'Papers', limit: 16),
];

List<TimelineSection> buildBySource({
  required List<NewsItem> items,
  required Map<String, SourceDef> catalog,
  List<String> sourceOrder = const [],
}) {
  final grouped = <String, List<NewsItem>>{};
  for (final item in items) {
    grouped.putIfAbsent(item.sourceId, () => []).add(item);
  }
  for (final list in grouped.values) {
    list.sort((a, b) {
      final da = a.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
  }
  final seen = <String>{};
  final ids = <String>[];
  for (final id in sourceOrder) {
    if (grouped.containsKey(id) && seen.add(id)) ids.add(id);
  }
  for (final id in grouped.keys) {
    if (seen.add(id)) ids.add(id);
  }
  return [
    for (final id in ids)
      TimelineSection(
        id: id,
        titleZh: catalog[id]?.name ?? id,
        titleEn: catalog[id]?.nameEn ?? catalog[id]?.name ?? id,
        items: grouped[id]!,
      ),
  ];
}

List<TimelineSection> buildTimeline({
  required List<NewsItem> items,
  required Map<String, SourceDef> catalog,
  DateTime? now,
  List<SpotlightGroup> spotlights = defaultSpotlights,
}) {
  final clock = now ?? DateTime.now();
  final pinned = <SourceCategory, List<NewsItem>>{
    for (final group in spotlights) group.category: <NewsItem>[],
  };
  final rest = <NewsItem>[];

  for (final item in items) {
    final cat = catalog[item.sourceId]?.category;
    if (cat != null && pinned.containsKey(cat)) {
      pinned[cat]!.add(item);
    } else {
      rest.add(item);
    }
  }

  final sections = <TimelineSection>[];
  for (final group in spotlights) {
    var list = pinned[group.category] ?? const <NewsItem>[];
    if (list.isEmpty) continue;
    if (group.limit != null) list = list.take(group.limit!).toList();
    sections.add(TimelineSection(
      id: group.category.name,
      titleZh: group.titleZh,
      titleEn: group.titleEn,
      items: list,
    ));
  }

  final buckets = <String, List<NewsItem>>{};
  for (final item in rest) {
    final when = item.pubDate ?? clock;
    final key = _bucketKey(clock, when);
    buckets.putIfAbsent(key, () => []).add(item);
  }

  const order = ['h6', 'h12', 'd1', 'older'];
  const labelsZh = {
    'h6': '近 6 小时',
    'h12': '今天稍早',
    'd1': '昨天',
    'older': '更早',
  };
  const labelsEn = {
    'h6': 'Last 6 hours',
    'h12': 'Earlier today',
    'd1': 'Yesterday',
    'older': 'Earlier',
  };

  for (final key in order) {
    final list = buckets[key];
    if (list == null || list.isEmpty) continue;
    sections.add(TimelineSection(
      id: key,
      titleZh: labelsZh[key]!,
      titleEn: labelsEn[key]!,
      items: list,
    ));
  }
  return sections;
}

String _bucketKey(DateTime now, DateTime when) {
  final delta = now.difference(when);
  if (delta.inHours < 6) return 'h6';
  if (delta.inHours < 18 && when.day == now.day) return 'h12';
  if (delta.inHours < 48) return 'd1';
  return 'older';
}
