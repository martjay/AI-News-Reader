import 'dart:io';

import 'package:news_core/news_core.dart';
import 'package:test/test.dart';

void main() {
  test('catalog lists snapshot sources and the public jsDelivr URL', () {
    final yaml = File('../../config/sources.yaml').readAsStringSync();
    final catalog = SourceCatalog.parse(yaml);
    expect(catalog.snapshot, isNotEmpty);
    expect(catalog.direct, isNotEmpty);
    expect(
      catalog.defaultSnapshotUrl,
      'https://cdn.jsdelivr.net/gh/martjay/AI-News-Reader@main/data/snapshot.json',
    );
  });
}
