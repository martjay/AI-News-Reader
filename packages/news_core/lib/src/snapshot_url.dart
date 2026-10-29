final _privateHost = RegExp(
  r'^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|0\.0\.0\.0)',
  caseSensitive: false,
);

final _repoShape = RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$');

const snapshotMaxBytes = 6 * 1024 * 1024;

String? invalidSnapshotUrlReason(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return 'invalid';
  if (uri.scheme != 'https') return 'https';
  final host = uri.host.toLowerCase();
  if (host == '::1' || host == '[::1]' || _privateHost.hasMatch(host)) return 'private';
  if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host) && _privateHost.hasMatch(host)) {
    return 'private';
  }
  if (host == 'localhost' || host.endsWith('.local')) return 'private';
  return null;
}

bool isAllowedSnapshotUrl(String raw) => invalidSnapshotUrlReason(raw) == null;

String? jsdelivrUrlForRepo(String repo) {
  final trimmed = repo.trim();
  if (!_repoShape.hasMatch(trimmed)) return null;
  return 'https://cdn.jsdelivr.net/gh/$trimmed@main/data/snapshot.json';
}

bool shouldKeepArticle({
  required bool saved,
  required int? pubMs,
  required int nowMs,
  required int retentionMs,
}) {
  if (saved) return true;
  if (pubMs == null) return false;
  return nowMs - pubMs <= retentionMs;
}
