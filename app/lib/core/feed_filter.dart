import 'package:news_core/news_core.dart';

const preferredLeadSource = 'aihot';

List<String> pinPreferredSource(List<String> ids) {
  if (!ids.contains(preferredLeadSource)) return ids;
  return [preferredLeadSource, ...ids.where((id) => id != preferredLeadSource)];
}

List<String> orderedSourceIds(List<String> stored, SourceCatalog catalog) {
  if (stored.isEmpty) {
    return pinPreferredSource(catalog.sources.map((s) => s.id).toList());
  }
  final seen = <String>{};
  final ids = <String>[];
  for (final id in stored) {
    if (catalog.byId(id) != null && seen.add(id)) ids.add(id);
  }
  for (final source in catalog.sources) {
    if (seen.add(source.id)) ids.add(source.id);
  }
  return ids;
}

String resolveFeedSource(String raw, Iterable<String> sourceIds) {
  if (raw == 'all' || raw.isEmpty) return 'all';
  for (final id in sourceIds) {
    if (id == raw) return raw;
  }
  return 'all';
}

Set<String> resolveEnabledSourceIds({
  required Iterable<String> enabledSources,
  required Iterable<String> seenSourceIds,
  required Iterable<String> catalogEnabledIds,
}) {
  if (enabledSources.isNotEmpty) return {...enabledSources};
  if (seenSourceIds.isNotEmpty) return {};
  return {...catalogEnabledIds};
}

class AdoptedSources {
  const AdoptedSources({required this.enabled, required this.seen});

  final List<String> enabled;
  final List<String> seen;
}

/// Adds catalog sources the user has never seen. Sources they already saw stay as they left them.
AdoptedSources adoptUnseenSources({
  required List<String> enabledSources,
  required List<String> seenSourceIds,
  required Iterable<SourceDef> sources,
}) {
  final seen = [...seenSourceIds];
  final enabled = [...enabledSources];
  for (final source in sources) {
    if (seen.contains(source.id)) continue;
    seen.add(source.id);
    if (source.enabled && !source.board && !enabled.contains(source.id)) {
      enabled.add(source.id);
    }
  }
  return AdoptedSources(enabled: enabled, seen: seen);
}

List<String> applySourceEnabled({
  required List<String> enabledSources,
  required List<String> seenSourceIds,
  required Iterable<String> catalogEnabledIds,
  required String id,
  required bool on,
}) {
  var next = [...enabledSources];
  if (next.isEmpty && seenSourceIds.isEmpty) {
    next = [...catalogEnabledIds];
  }
  if (on) {
    if (!next.contains(id)) next.add(id);
  } else {
    next.remove(id);
  }
  return next;
}
