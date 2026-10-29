import 'package:yaml/yaml.dart';

import 'models.dart';

class SourceCatalog {
  SourceCatalog({
    required this.sources,
    this.defaultSnapshotUrl = '',
    this.snapshotAssetPath = 'data/snapshot.json',
  });

  final List<SourceDef> sources;
  final String defaultSnapshotUrl;
  final String snapshotAssetPath;

  SourceDef? byId(String id) {
    for (final s in sources) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<SourceDef> get enabled => sources.where((s) => s.enabled).toList();

  List<SourceDef> get direct =>
      enabled.where((s) => s.access == SourceAccess.direct).toList();

  List<SourceDef> get snapshot =>
      enabled.where((s) => s.access == SourceAccess.snapshot).toList();

  factory SourceCatalog.parse(String yamlText) {
    final doc = loadYaml(yamlText);
    if (doc is! YamlMap) {
      throw const FormatException('sources.yaml root must be a map');
    }
    final snap = doc['snapshot'] as YamlMap?;
    final list = doc['sources'] as YamlList? ?? YamlList();
    return SourceCatalog(
      defaultSnapshotUrl: snap?['defaultUrl'] as String? ?? '',
      snapshotAssetPath: snap?['assetPath'] as String? ?? 'data/snapshot.json',
      sources: [
        for (final raw in list)
          SourceDef.fromYaml(Map<dynamic, dynamic>.from(raw as YamlMap)),
      ],
    );
  }
}
