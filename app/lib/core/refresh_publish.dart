import 'package:news_core/news_core.dart';

import 'article_record.dart';

/// Inserts one source's new or updated rows into the list the reader is showing.
/// Unchanged rows keep their translation and full text.
List<ArticleRecord> recordsAfterIncoming(List<ArticleRecord> current, List<NewsItem> changed) {
  if (changed.isEmpty) return current;
  final byId = <String, ArticleRecord>{for (final record in current) record.item.id: record};
  for (final item in changed) {
    final existing = byId[item.id];
    if (existing == null) {
      byId[item.id] = ArticleRecord(item: item);
      continue;
    }
    if (sameNewsItem(existing.item, item)) continue;
    byId[item.id] = existing.copyWith(
      item: item,
      titleZh: existing.item.title == item.title ? existing.titleZh : '',
      summaryZh: existing.item.summary == item.summary ? existing.summaryZh : '',
    );
  }
  final next = byId.values.toList()
    ..sort((a, b) {
      final byDate = (b.item.pubDate?.millisecondsSinceEpoch ?? 0).compareTo(
        a.item.pubDate?.millisecondsSinceEpoch ?? 0,
      );
      if (byDate != 0) return byDate;
      return b.item.id.compareTo(a.item.id);
    });
  return next;
}
