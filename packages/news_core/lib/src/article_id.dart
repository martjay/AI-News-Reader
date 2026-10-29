import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'dedupe.dart';
import 'models.dart';

String articleIdFor({required String sourceId, required String url}) {
  final key = canonicalizeUrl(url);
  final material = key.isEmpty ? url.trim().toLowerCase() : key;
  return sha256.convert(utf8.encode('$sourceId|$material')).toString();
}

NewsItem makeItem({
  required String sourceId,
  required String title,
  required String url,
  String summary = '',
  DateTime? pubDate,
  List<String> extraSourceIds = const [],
}) {
  return NewsItem(
    id: articleIdFor(sourceId: sourceId, url: url),
    sourceId: sourceId,
    title: title,
    url: url,
    summary: summary,
    pubDate: pubDate,
    extraSourceIds: extraSourceIds,
  );
}
