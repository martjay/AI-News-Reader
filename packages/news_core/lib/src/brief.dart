import 'dedupe.dart';
import 'models.dart';

class BriefStory {
  const BriefStory({
    required this.lead,
    required this.sourceIds,
    required this.memberIds,
  });

  final NewsItem lead;
  final List<String> sourceIds;
  final List<String> memberIds;

  bool get crossSource => sourceIds.length > 1;
}

List<BriefStory> buildBrief({
  required List<NewsItem> items,
  Set<String> unreadIds = const {},
  DateTime? now,
  int limit = 12,
  Duration window = const Duration(hours: 36),
}) {
  final clock = now ?? DateTime.now();
  final ranked = [...items]..sort((a, b) {
      final da = a.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
  final pool = ranked.take(80).toList();

  final used = <String>{};
  final stories = <BriefStory>[];

  for (final item in pool) {
    if (used.contains(item.id)) continue;
    final age = item.pubDate == null ? const Duration(days: 9) : clock.difference(item.pubDate!);
    if (age > window && item.extraSourceIds.isEmpty) continue;
    if (normalizeTitle(item.title).length < 4) continue;

    final members = <NewsItem>[item];
    for (final other in pool) {
      if (other.id == item.id || used.contains(other.id)) continue;
      if (other.sourceId == item.sourceId) continue;
      final sim = titleSimilarity(item.title, other.title);
      if (sim < 0.86) continue;
      final oa = other.pubDate;
      final ia = item.pubDate;
      if (oa != null && ia != null && oa.difference(ia).inHours.abs() > 48) continue;
      members.add(other);
    }

    for (final member in members) {
      used.add(member.id);
    }

    final sourceIds = <String>{};
    for (final member in members) {
      sourceIds.addAll(member.allSourceIds);
    }

    stories.add(BriefStory(
      lead: item,
      sourceIds: sourceIds.toList(),
      memberIds: members.map((e) => e.id).toList(),
    ));
  }

  stories.sort((a, b) => _score(b, unreadIds, clock).compareTo(_score(a, unreadIds, clock)));
  return stories.take(limit).toList();
}

double _score(BriefStory story, Set<String> unreadIds, DateTime clock) {
  final item = story.lead;
  final ageH = item.pubDate == null ? 48.0 : clock.difference(item.pubDate!).inMinutes / 60.0;
  final recency = (36 - ageH).clamp(0, 36);
  final cross = (story.sourceIds.length - 1) * 26.0;
  final unread = unreadIds.contains(item.id) ? 16.0 : 0.0;
  return recency + cross + unread;
}
