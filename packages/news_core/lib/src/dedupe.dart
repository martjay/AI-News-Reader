import 'models.dart';

String canonicalizeUrl(String raw) {
  var value = raw.trim();
  while (value.endsWith('/') && !value.endsWith('://')) {
    value = value.substring(0, value.length - 1);
  }
  try {
    final uri = Uri.parse(value);
    final filtered = Map<String, String>.from(uri.queryParameters)
      ..removeWhere((k, _) => k.toLowerCase().startsWith('utm_') || k == 'fbclid' || k == 'gclid');
    final replaced = uri.replace(queryParameters: filtered);
    value = filtered.isEmpty ? replaced.replace(query: '').toString() : replaced.toString();
    if (value.endsWith('?')) value = value.substring(0, value.length - 1);
  } catch (_) {}
  return value.toLowerCase();
}

String normalizeTitle(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[\s\[\]【】()（）:：|·,，.。!！?？\-—_]+'), '')
      .trim();
}

double titleSimilarity(String a, String b) {
  final na = normalizeTitle(a);
  final nb = normalizeTitle(b);
  if (na.isEmpty || nb.isEmpty) return 0;
  if (na == nb) return 1;
  final sa = na.split('');
  final sb = nb.split('');
  final setA = sa.toSet();
  final setB = sb.toSet();
  final inter = setA.intersection(setB).length;
  final union = setA.union(setB).length;
  if (union == 0) return 0;
  final jaccard = inter / union;
  final prefix = na.length >= 12 && nb.length >= 12 && (na.startsWith(nb.substring(0, 12)) || nb.startsWith(na.substring(0, 12)));
  return prefix ? (jaccard + 0.25).clamp(0, 1) : jaccard;
}

List<NewsItem> mergeAndDedupe(List<NewsItem> items) {
  final byUrl = <String, NewsItem>{};
  final leftover = <NewsItem>[];

  for (final item in items) {
    final key = canonicalizeUrl(item.url);
    if (key.isEmpty) {
      leftover.add(item);
      continue;
    }
    final existing = byUrl[key];
    if (existing == null) {
      byUrl[key] = item;
    } else {
      byUrl[key] = existing.copyWith(
        extraSourceIds: mergedSourceIds(existing, item),
        summary: existing.summary.length >= item.summary.length
            ? existing.summary
            : item.summary,
      );
    }
  }

  final merged = [...byUrl.values, ...leftover];
  final result = <NewsItem>[];
  final buckets = <String, List<int>>{};
  String bucketOf(String title) {
    final n = normalizeTitle(title);
    if (n.length <= 6) return n;
    return n.substring(0, 6);
  }

  for (final item in merged) {
    final bucket = buckets.putIfAbsent(bucketOf(item.title), () => <int>[]);
    var dupIndex = -1;
    for (final i in bucket) {
      final other = result[i];
      final sim = titleSimilarity(other.title, item.title);
      if (sim < 0.86) continue;
      final a = other.pubDate;
      final b = item.pubDate;
      final close = a == null || b == null ? sim >= 0.94 : a.difference(b).inHours.abs() <= 36;
      if (!close) continue;
      dupIndex = i;
      break;
    }
    if (dupIndex < 0) {
      bucket.add(result.length);
      result.add(item);
    } else {
      final other = result[dupIndex];
      result[dupIndex] = other.copyWith(
        extraSourceIds: mergedSourceIds(other, item),
        summary: other.summary.length >= item.summary.length ? other.summary : item.summary,
      );
    }
  }

  result.sort((a, b) {
    final da = a.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final db = b.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    return db.compareTo(da);
  });
  return result;
}

List<String> mergedSourceIds(NewsItem keep, NewsItem other) {
  final out = [...keep.extraSourceIds];
  void add(String id) {
    if (id.isEmpty || id == keep.sourceId || out.contains(id)) return;
    out.add(id);
  }

  add(other.sourceId);
  for (final id in other.extraSourceIds) {
    add(id);
  }
  return out;
}

List<NewsItem> mergeIncoming(List<NewsItem> stored, List<NewsItem> incoming) {
  return mergeAndDedupe([...stored, ...incoming]);
}
