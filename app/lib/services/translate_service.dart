import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:news_core/news_core.dart';

import '../core/settings.dart';

class TranslateException implements Exception {
  TranslateException(this.backend, this.cause, {this.previous = const []});

  final String backend;
  final Object cause;
  final List<Object> previous;

  @override
  String toString() => 'TranslateException($backend: $cause)';
}

class TranslateService {
  TranslateService({FetchClient? client}) : _client = client ?? FetchClient(timeout: const Duration(seconds: 20));

  final FetchClient _client;

  Future<String> translateToZh(
    String text,
    AppSettings settings, {
    FutureOr<void> Function(String partial)? onPartial,
  }) async {
    final raw = text.trim();
    if (raw.isEmpty) return raw;
    final paras = raw.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (paras.length <= 1) {
      if (isPrimarilyChinese(raw) || !hasTranslatableLatin(raw)) return raw;
      final out = await _translateChunk(raw, settings);
      await onPartial?.call(out);
      return out;
    }
    final out = <String>[];
    for (final p in paras) {
      final latin = RegExp(r'[A-Za-z]').allMatches(p).length;
      if (isPrimarilyChinese(p) || latin < 8) {
        out.add(p);
      } else {
        final marker = RegExp(r'^(\s*[-*•]\s*)').firstMatch(p);
        final prefix = marker?.group(1) ?? '';
        final core = prefix.isEmpty ? p : p.substring(prefix.length);
        final translated = await _translateChunk(core, settings);
        out.add('$prefix$translated'.trim());
      }
      await onPartial?.call(out.join('\n\n').trim());
    }
    return out.join('\n\n').trim();
  }

  Future<String> _translateChunk(String clipped, AppSettings settings) async {
    if (clipped.trim().isEmpty) return clipped;
    if (!hasTranslatableLatin(clipped) && isPrimarilyChinese(clipped)) return clipped;
    if (settings.translationApiKey.trim().isNotEmpty) {
      try {
        return await _viaLlm(clipped, settings);
      } catch (e, st) {
        debugPrint('LLM translate failed, falling back: $e\n$st');
      }
    }
    try {
      return await _viaTransmart(clipped);
    } catch (transmart) {
      try {
        return await _viaGoogle(clipped);
      } catch (google) {
        try {
          return await _viaMyMemory(clipped);
        } catch (memory) {
          throw TranslateException('mymemory', memory, previous: [transmart, google]);
        }
      }
    }
  }

  Future<String> _viaTransmart(String text) async {
    final json = await _client.postJson(
      'https://transmart.qq.com/api/imt',
      {
        'header': {
          'fn': 'auto_translation',
          'client_key': 'browser-chrome-130.0.0-windows',
        },
        'type': 'plain',
        'model_category': 'normal',
        'source': {
          'lang': 'en',
          'text_list': [text],
        },
        'target': {'lang': 'zh'},
      },
    ) as Map;
    final list = json['auto_translation'] as List? ?? const [];
    final out = list.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).join('\n').trim();
    if (out.isEmpty) throw Exception('Transmart empty');
    return out;
  }

  Future<String> _viaGoogle(String text) async {
    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
      'client': 'gtx',
      'sl': 'auto',
      'tl': 'zh-CN',
      'dt': 't',
      'q': text,
    });
    final json = await _client.getJson(uri.toString());
    if (json is! List || json.isEmpty || json.first is! List) {
      throw Exception('Google empty');
    }
    final buf = StringBuffer();
    for (final row in json.first as List) {
      if (row is List && row.isNotEmpty) buf.write(row.first);
    }
    final out = buf.toString().trim();
    if (out.isEmpty) throw Exception('Google empty');
    return out;
  }

  Future<String> _viaMyMemory(String text) async {
    final uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': text,
      'langpair': 'en|zh-CN',
    });
    final json = await _client.getJson(uri.toString()) as Map;
    final out = ((json['responseData'] as Map?)?['translatedText'] as String?)?.trim() ?? '';
    if (out.isEmpty || out.contains('MYMEMORY WARNING')) throw Exception('MyMemory empty');
    return out;
  }

  Future<String> _viaLlm(String text, AppSettings settings) async {
    var base = settings.translationBaseUrl.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (!base.endsWith('/v1')) {
      base = '$base/v1';
    }
    final json = await _client.postJson(
      '$base/chat/completions',
      {
        'model': settings.translationModel.trim().isEmpty ? 'deepseek-chat' : settings.translationModel.trim(),
        'temperature': 0.2,
        'messages': [
          {
            'role': 'system',
            'content': '你是中文新闻译者。把用户给出的标题或摘要译成流畅简体中文。只输出译文，不要引号、不要解释。保留产品名、模型名原文。',
          },
          {'role': 'user', 'content': text},
        ],
      },
      headers: {'Authorization': 'Bearer ${settings.translationApiKey.trim()}'},
    ) as Map;
    final content = (((json['choices'] as List?)?.first as Map?)?['message'] as Map?)?['content'] as String?;
    final out = content?.trim() ?? '';
    if (out.isEmpty) throw Exception('LLM empty');
    return out;
  }

  void close() => _client.close();
}
