import 'dart:io';

import 'package:ai_news_reader/core/settings.dart';
import 'package:ai_news_reader/services/feed_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_core/news_core.dart';

void main() {
  test('default settings resolve the catalog jsDelivr snapshot URL', () {
    final yaml = File('../config/sources.yaml').readAsStringSync();
    final catalog = SourceCatalog.parse(yaml);
    final url = FeedService().resolveSnapshotUrl(const AppSettings(), catalog);
    expect(
      catalog.defaultSnapshotUrl,
      'https://cdn.jsdelivr.net/gh/martjay/AI-News-Reader@main/data/snapshot.json',
    );
    expect(url, contains('cdn.jsdelivr.net/gh/martjay/AI-News-Reader@main/data/snapshot.json'));
    expect(catalog.snapshot, isNotEmpty);
  });

  test('rejects loopback snapshot urls and accepts jsDelivr repo form', () {
    final catalog = SourceCatalog.parse('snapshot:\n  defaultUrl: ""\nsources: []\n');
    expect(
      FeedService().resolveSnapshotUrl(
        const AppSettings(snapshotUrl: 'https://127.0.0.1/snapshot.json'),
        catalog,
      ),
      isNull,
    );
    final url = FeedService().resolveSnapshotUrl(
      const AppSettings(snapshotRepo: 'owner/repo'),
      catalog,
    );
    expect(url, contains('cdn.jsdelivr.net/gh/owner/repo@main/data/snapshot.json'));
  });
}
