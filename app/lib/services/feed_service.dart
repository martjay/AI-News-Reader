import 'package:flutter/services.dart';
import 'package:news_core/news_core.dart';

import '../core/serial.dart';
import '../core/settings.dart';

class FeedService {
  FeedService();

  Future<SourceCatalog> loadCatalog() async {
    final yaml = await rootBundle.loadString('assets/config/sources.yaml');
    return SourceCatalog.parse(yaml);
  }

  Future<NewsSnapshot> loadBundledSnapshot() async {
    final text = await rootBundle.loadString('assets/data/snapshot.json');
    return NewsSnapshot.decode(text);
  }

  String? resolveSnapshotUrl(AppSettings settings, SourceCatalog catalog) {
    if (settings.snapshotUrl.trim().isNotEmpty) {
      final raw = settings.snapshotUrl.trim();
      if (!isAllowedSnapshotUrl(raw)) {
        return null;
      }
      return _cacheBust(raw);
    }
    final fromRepo = jsdelivrUrlForRepo(settings.snapshotRepo);
    if (fromRepo != null) return _cacheBust(fromRepo);
    final fallback = catalog.defaultSnapshotUrl.trim();
    if (fallback.isNotEmpty && isAllowedSnapshotUrl(fallback)) {
      return _cacheBust(fallback);
    }
    return null;
  }

  String _cacheBust(String url) {
    final bucket = DateTime.now().millisecondsSinceEpoch ~/ (15 * 60 * 1000);
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters)..['t'] = '$bucket';
    return uri.replace(queryParameters: params).toString();
  }

  Future<NewsSnapshot?> fetchRemoteSnapshot(String url) async {
    if (!isAllowedSnapshotUrl(url.split('?').first)) {
      throw Exception('Snapshot URL not allowed');
    }
    final client = FetchClient(timeout: const Duration(seconds: 12));
    try {
      final text = await client.getText(url, maxBytes: snapshotMaxBytes);
      return NewsSnapshot.decode(text);
    } finally {
      client.close();
    }
  }

  Future<List<SourceFetchResult>> fetchDirect(
    List<SourceDef> sources, {
    int parallelism = 6,
    Future<SourceFetchResult> Function(SourceDef source)? fetchOne,
    Future<void> Function(SourceFetchResult result)? onEach,
  }) async {
    final fetcher = fetchOne == null ? SourceFetcher() : null;
    final results = <SourceFetchResult>[];
    final publish = Serial();
    try {
      if (sources.isEmpty) return results;
      var next = 0;
      final width = parallelism < 1
          ? 1
          : (parallelism > sources.length ? sources.length : parallelism);
      Future<void> worker() async {
        while (true) {
          if (next >= sources.length) return;
          final source = sources[next];
          next += 1;
          final result = fetchOne != null ? await fetchOne(source) : await fetcher!.fetch(source);
          results.add(result);
          if (onEach != null) await publish.run(() => onEach(result));
        }
      }

      await Future.wait([for (var i = 0; i < width; i++) worker()]);
      return results;
    } finally {
      fetcher?.client.close();
    }
  }
}
