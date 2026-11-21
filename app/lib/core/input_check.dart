bool acceptableHttpUrl(String value) {
  final text = value.trim();
  if (text.isEmpty) return true;
  final uri = Uri.tryParse(text);
  return uri != null && (uri.isScheme('http') || uri.isScheme('https')) && uri.host.isNotEmpty;
}

bool acceptableRepo(String value) {
  final text = value.trim();
  if (text.isEmpty) return true;
  return RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(text);
}

bool acceptableProxy(String value) {
  final text = value.trim();
  if (text.isEmpty) return true;
  if (text.contains(RegExp(r'\s'))) return false;
  final withScheme = text.contains('://') ? text : 'http://$text';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || uri.host.isEmpty) return false;
  if (!uri.isScheme('http') && !uri.isScheme('https')) return false;
  return RegExp(r'^[A-Za-z0-9.-]+$').hasMatch(uri.host);
}
