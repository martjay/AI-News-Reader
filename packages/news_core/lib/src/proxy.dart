import 'dart:io';

import 'fetch_client.dart';

String? parseHttpProxy(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return null;
  if (value.toUpperCase() == 'DIRECT') return null;
  if (value.toLowerCase().startsWith('socks')) return null;
  value = value.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
  if (value.contains(';')) {
    final parts = value.split(';');
    for (final key in ['https', 'http']) {
      for (final part in parts) {
        final kv = part.split('=');
        if (kv.length == 2 && kv.first.trim().toLowerCase() == key) {
          return parseHttpProxy(kv.last);
        }
      }
    }
    value = parts.first.trim();
  }
  final hostPort = value.contains('@') ? value.split('@').last : value;
  if (!hostPort.contains(':')) return null;
  final uri = Uri.tryParse('http://$hostPort');
  if (uri == null || uri.host.isEmpty || uri.port <= 0) return null;
  return '${uri.host}:${uri.port}';
}

Future<String?> detectSystemProxy() async {
  for (final key in ['HTTPS_PROXY', 'https_proxy', 'HTTP_PROXY', 'http_proxy', 'ALL_PROXY', 'all_proxy']) {
    final parsed = parseHttpProxy(Platform.environment[key] ?? '');
    if (parsed != null) return parsed;
  }
  if (Platform.isWindows) return _windowsInternetProxy();
  return null;
}

Future<String?> _windowsInternetProxy() async {
  try {
    final result = await Process.run('reg', [
      'query',
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
    ]);
    final text = '${result.stdout}';
    if (!RegExp(r'ProxyEnable\s+REG_DWORD\s+0x1\b', caseSensitive: false).hasMatch(text)) {
      return null;
    }
    final match = RegExp(r'ProxyServer\s+REG_SZ\s+(.+)$', caseSensitive: false, multiLine: true).firstMatch(text);
    return parseHttpProxy(match?.group(1) ?? '');
  } catch (_) {
    return null;
  }
}

Future<String> applyFetchProxy({required bool useSystem, required String manual}) async {
  final fromManual = parseHttpProxy(manual);
  if (fromManual != null) {
    FetchClient.findProxy = 'PROXY $fromManual';
    _installHttpOverrides(FetchClient.findProxy);
    return fromManual;
  }
  if (!useSystem) {
    FetchClient.findProxy = 'DIRECT';
    _installHttpOverrides('DIRECT');
    return 'DIRECT';
  }
  final detected = await detectSystemProxy();
  if (detected != null) {
    FetchClient.findProxy = 'PROXY $detected';
    _installHttpOverrides(FetchClient.findProxy);
    return detected;
  }
  FetchClient.findProxy = null;
  _installHttpOverrides(null);
  return 'env';
}

void _installHttpOverrides(String? directive) {
  HttpOverrides.global = _ProxyHttpOverrides(directive);
}

class _ProxyHttpOverrides extends HttpOverrides {
  _ProxyHttpOverrides(this.directive);

  final String? directive;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (directive == 'DIRECT') {
      client.findProxy = (_) => 'DIRECT';
    } else if (directive != null && directive!.isNotEmpty) {
      client.findProxy = (_) => directive!;
    } else {
      client.findProxy = HttpClient.findProxyFromEnvironment;
    }
    return client;
  }
}
