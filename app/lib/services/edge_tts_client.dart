import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random, min;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:news_core/news_core.dart';

class EdgeTtsClient {
  static const _token = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  static const _chrome = '143.0.3650.75';
  static const _gecVersion = '1-$_chrome';
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0';
  static const _origin = 'chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold';
  static const _hosts = [
    'wss://api.msedgeservices.com/tts/cognitiveservices/websocket/v1?Ocp-Apim-Subscription-Key=$_token',
    'wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1?TrustedClientToken=$_token',
  ];

  Future<Uint8List> synthesize({required String text, required String voice}) async {
    Object? last;
    for (final host in _hosts) {
      try {
        return await _synthesizeOnce(host: host, text: text, voice: voice);
      } catch (e) {
        last = e;
      }
    }
    throw last ?? StateError('Edge TTS failed');
  }

  Future<Uint8List> _synthesizeOnce({
    required String host,
    required String text,
    required String voice,
  }) async {
    final socket = await _connect(host);
    final audio = BytesBuilder(copy: false);
    final done = Completer<void>();
    late final StreamSubscription<dynamic> sub;
    sub = socket.listen(
      (message) {
        try {
          if (message is String) {
            if (message.contains('Path:turn.end')) {
              if (!done.isCompleted) done.complete();
            }
            return;
          }
          if (message is List<int>) {
            final chunk = _audioFromBinary(message);
            if (chunk != null && chunk.isNotEmpty) audio.add(chunk);
          }
        } catch (e, st) {
          if (!done.isCompleted) done.completeError(e, st);
        }
      },
      onError: (Object e, StackTrace st) {
        if (!done.isCompleted) done.completeError(e, st);
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: true,
    );
    try {
      final locale = RegExp(r'[a-z]{2}-[A-Z]{2}').firstMatch(voice)?.group(0) ?? 'zh-CN';
      final escaped = text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');
      final ts = _jsTime();
      socket.add(
        'X-Timestamp:$ts\r\n'
        'Content-Type:application/json; charset=utf-8\r\n'
        'Path:speech.config\r\n\r\n'
        '{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"false"},'
        '"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}\r\n',
      );
      socket.add(
        'X-RequestId:${_hex(16)}\r\n'
        'Content-Type:application/ssml+xml\r\n'
        'X-Timestamp:${ts}Z\r\n'
        'Path:ssml\r\n\r\n'
        '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="$locale">'
        '<voice name="$voice"><prosody rate="+0%" pitch="+0Hz" volume="+0%">$escaped</prosody></voice></speak>',
      );
      await done.future.timeout(const Duration(seconds: 30));
      final bytes = audio.takeBytes();
      if (bytes.isEmpty) throw StateError('Edge TTS returned no audio');
      return bytes;
    } finally {
      await sub.cancel();
      await socket.close();
    }
  }

  Future<WebSocket> _connect(String base) async {
    final url =
        '$base&ConnectionId=${_hex(16)}&Sec-MS-GEC=${_gec()}&Sec-MS-GEC-Version=$_gecVersion';
    final uri = Uri.parse(url);
    final requestUri = uri.replace(scheme: uri.scheme == 'wss' ? 'https' : 'http');
    final httpClient = HttpClient()..userAgent = _userAgent;
    final proxy = FetchClient.findProxy;
    if (proxy != null && proxy.isNotEmpty) {
      httpClient.findProxy = (_) => proxy;
    } else {
      httpClient.findProxy = HttpClient.findProxyFromEnvironment;
    }
    try {
      final request = await httpClient.openUrl('GET', requestUri).timeout(const Duration(seconds: 20));
      request.headers.set(HttpHeaders.hostHeader, uri.host);
      request.headers.set(HttpHeaders.upgradeHeader, 'websocket');
      request.headers.set(HttpHeaders.connectionHeader, 'Upgrade');
      request.headers.set('Sec-WebSocket-Key', base64Encode(List<int>.generate(16, (_) => Random.secure().nextInt(256))));
      request.headers.set('Sec-WebSocket-Version', '13');
      request.headers.set('Origin', _origin);
      request.headers.set('Pragma', 'no-cache');
      request.headers.set('Cache-Control', 'no-cache');
      request.headers.set('Cookie', 'muid=${_hex(16).toUpperCase()};');
      request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');
      final response = await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.switchingProtocols) {
        final body = await response.transform(utf8.decoder).join();
        throw HttpException('Edge TTS ${response.statusCode} ${body.trim()}', uri: requestUri);
      }
      final raw = await response.detachSocket();
      return WebSocket.fromUpgradedSocket(raw, serverSide: false, compression: CompressionOptions.compressionOff);
    } finally {
      httpClient.close(force: true);
    }
  }

  static Uint8List? _audioFromBinary(List<int> message) {
    final bytes = message is Uint8List ? message : Uint8List.fromList(message);
    final marker = utf8.encode('Path:audio\r\n');
    final idx = _indexOf(bytes, marker);
    if (idx >= 0 && idx + marker.length < bytes.length) {
      return bytes.sublist(idx + marker.length);
    }
    if (bytes.length < 2) return null;
    final headerLength = (bytes[0] << 8) | bytes[1];
    if (headerLength + 2 <= bytes.length) {
      final header = utf8.decode(bytes.sublist(0, min(headerLength, bytes.length)), allowMalformed: true);
      if (header.contains('Path:audio')) return bytes.sublist(headerLength + 2);
    }
    if (headerLength + 2 <= bytes.length) {
      final header = utf8.decode(bytes.sublist(2, 2 + headerLength), allowMalformed: true);
      if (header.contains('Path:audio')) return bytes.sublist(2 + headerLength);
    }
    return null;
  }

  static int _indexOf(List<int> source, List<int> needle) {
    if (needle.isEmpty || source.length < needle.length) return -1;
    for (var i = 0; i <= source.length - needle.length; i++) {
      var ok = true;
      for (var j = 0; j < needle.length; j++) {
        if (source[i + j] != needle[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return i;
    }
    return -1;
  }

  static String _gec() {
    final ticks = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 11644473600;
    final rounded = ticks - (ticks % 300);
    final windowsTicks = rounded * 10000000;
    return sha256.convert(utf8.encode('$windowsTicks$_token')).toString().toUpperCase();
  }

  static String _hex(int bytes) {
    final random = Random.secure();
    return List.generate(bytes, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static String _jsTime() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final utc = DateTime.now().toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${weekdays[utc.weekday % 7]} ${months[utc.month - 1]} ${two(utc.day)} ${utc.year} '
        '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)} GMT+0000 (Coordinated Universal Time)';
  }
}
