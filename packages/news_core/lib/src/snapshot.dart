import 'dart:convert';

import 'models.dart';

class NewsSnapshot {
  const NewsSnapshot({
    required this.generatedAt,
    required this.sources,
  });

  final DateTime generatedAt;
  final Map<String, SourceFetchResult> sources;

  List<NewsItem> get allItems {
    final items = <NewsItem>[];
    for (final result in sources.values) {
      items.addAll(result.items);
    }
    return items;
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'sources': {
          for (final e in sources.entries) e.key: e.value.toJson(),
        },
      };

  factory NewsSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['sources'] as Map? ?? {};
    return NewsSnapshot(
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sources: {
        for (final e in raw.entries)
          e.key as String: SourceFetchResult.fromJson(
            Map<String, dynamic>.from(e.value as Map),
          ),
      },
    );
  }

  static NewsSnapshot decode(String text) =>
      NewsSnapshot.fromJson(jsonDecode(text) as Map<String, dynamic>);

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}
