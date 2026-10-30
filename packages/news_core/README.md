# news_core

Shared Dart library for the news reader. The Flutter app and `tools/aggregator` both depend on it.

It parses `config/sources.yaml`, fetches RSS and a few site-specific feeds, dedupes items that point at the same story, and reads or writes `data/snapshot.json`. Snapshot URLs are limited to public https hosts.

```dart
import 'package:news_core/news_core.dart';

final catalog = SourceCatalog.parse(yamlText);
final merged = mergeSnapshot(previous, freshResults, DateTime.now().toUtc());
```
