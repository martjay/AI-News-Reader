import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class FetchClient {
  FetchClient({http.Client? client, this.timeout = const Duration(seconds: 12)})
      : _client = client ?? _defaultClient();

  final http.Client _client;
  final Duration timeout;

  /// PAC-like directive: `PROXY host:port`, `DIRECT`, or null for environment.
  static String? findProxy;

  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';

  Map<String, String> _headers(Map<String, String>? extra) => {
        'User-Agent': userAgent,
        'Accept': '*/*',
        ...?extra,
      };

  Future<http.Response> getResponse(String url, {Map<String, String>? headers}) async {
    final response = await _client.get(Uri.parse(url), headers: _headers(headers)).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode} for $url');
    }
    return response;
  }

  Future<String> getText(String url, {Map<String, String>? headers, int? maxBytes}) async {
    final response = await getResponse(url, headers: headers);
    final bytes = response.bodyBytes;
    if (maxBytes != null && bytes.length > maxBytes) {
      throw Exception('Response too large (${bytes.length} > $maxBytes) for $url');
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<List<int>> getBytes(String url, {Map<String, String>? headers}) async {
    final response = await getResponse(url, headers: headers);
    return response.bodyBytes;
  }

  Future<String> cookieFrom(String url, {Map<String, String>? headers}) async {
    final response = await _client.get(Uri.parse(url), headers: _headers(headers)).timeout(timeout);
    final header = response.headers['set-cookie'] ?? '';
    if (header.isEmpty) return '';
    return [
      for (final chunk in header.split(RegExp(r',(?=[^ ;]+=)')))
        if (chunk.split(';').first.contains('=')) chunk.split(';').first.trim(),
    ].join('; ');
  }

  Future<dynamic> getJson(String url, {Map<String, String>? headers}) async {
    final text = await getText(url, headers: headers);
    return jsonDecode(text);
  }

  Future<dynamic> postJson(
    String url,
    Object body, {
    Map<String, String>? headers,
  }) async {
    final response = await _client
        .post(
          Uri.parse(url),
          headers: {
            'User-Agent': userAgent,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            ...?headers,
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode} for $url');
    }
    return jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
  }

  void close() => _client.close();

  static http.Client _defaultClient() {
    final io = HttpClient();
    final proxy = findProxy;
    if (proxy != null && proxy.isNotEmpty) {
      io.findProxy = (_) => proxy;
    } else {
      io.findProxy = HttpClient.findProxyFromEnvironment;
    }
    return IOClient(io);
  }
}
