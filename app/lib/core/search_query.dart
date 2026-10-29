import 'article_record.dart';

bool articleInSearchScope(ArticleRecord record, Set<String> enabledSourceIds) {
  return record.saved || enabledSourceIds.contains(record.item.sourceId);
}

bool articleMatchesQuery(ArticleRecord record, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return false;
  if (record.item.title.toLowerCase().contains(q) ||
      record.item.summary.toLowerCase().contains(q) ||
      record.titleZh.toLowerCase().contains(q) ||
      record.summaryZh.toLowerCase().contains(q)) {
    return true;
  }
  if (q.length < 2) return false;
  return record.body.toLowerCase().contains(q) || record.bodyZh.toLowerCase().contains(q);
}

List<ArticleRecord> searchArticles({
  required List<ArticleRecord> records,
  required Set<String> enabledSourceIds,
  required String query,
}) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  return [
    for (final record in records)
      if (articleInSearchScope(record, enabledSourceIds) && articleMatchesQuery(record, q)) record,
  ];
}
