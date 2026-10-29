import 'package:flutter/services.dart';
import 'package:news_core/news_core.dart';

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

  Future<List<SourceFetchResult>> fetchDirect(List<SourceDef> sources, {int parallelism = 6}) async {
    final fetcher = SourceFetcher();
    final results = <SourceFetchResult>[];
    try {
      for (var i = 0; i < sources.length; i += parallelism) {
        final end = i + parallelism > sources.length ? sources.length : i + parallelism;
        results.addAll(await Future.wait(sources.sublist(i, end).map(fetcher.fetch)));
        await Future<void>.delayed(Duration.zero);
      }
      return results;
    } finally {
      fetcher.client.close();
    }
  }
}
