import 'dart:io';

import 'package:aggregator/aggregator.dart';
import 'package:news_core/news_core.dart';

Future<void> main(List<String> args) async {
  final root = findRepoRoot();
  if (root == null) {
    stderr.writeln('[ERROR] Cannot find config/sources.yaml');
    exitCode = 1;
    return;
  }
  final yamlFile = File('${root.path}/config/sources.yaml');
  final catalog = SourceCatalog.parse(yamlFile.readAsStringSync());
  final fetcher = SourceFetcher();
  final results = <String, SourceFetchResult>{};
  const parallelism = 6;

  stdout.writeln('[INFO] Fetching ${catalog.snapshot.length} snapshot sources');
  final sources = catalog.snapshot;
  try {
    for (var i = 0; i < sources.length; i += parallelism) {
      final end = i + parallelism > sources.length ? sources.length : i + parallelism;
      final chunk = sources.sublist(i, end);
      final fetched = await Future.wait(chunk.map(fetcher.fetch));
      for (final result in fetched) {
        results[result.sourceId] = result;
        stdout.writeln(
          result.ok
              ? '[OK] ${result.sourceId} ${result.items.length} items'
              : '[WARN] ${result.sourceId} ${result.status} ${result.error}',
        );
      }
    }
  } finally {
    fetcher.client.close();
  }

  final snapshot = NewsSnapshot(generatedAt: DateTime.now().toUtc(), sources: results);
  final out = File('${root.path}/data/snapshot.json');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync('${snapshot.encode()}\n');
  stdout.writeln('[OK] Wrote ${out.path}');
}
