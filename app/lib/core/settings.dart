import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'feed_filter.dart';

class AppSettings {
  const AppSettings({
    this.language = 'zh',
    this.theme = 'dark',
    this.fontScale = 1.0,
    this.enabledSources = const [],
    this.sourceOrder = const [],
    this.snapshotRepo = '',
    this.snapshotUrl = '',
    this.autoTranslate = true,
    this.showOriginal = false,
    this.translationApiKey = '',
    this.translationBaseUrl = 'https://api.deepseek.com/v1',
    this.translationModel = 'deepseek-chat',
    this.feedFilter = 'all',
    this.listPaneWidth = 400,
    this.lastVisitMs = 0,
    this.newSinceMs = 0,
    this.useSystemProxy = true,
    this.proxyUrl = '',
    this.ttsVoice = 'zh-CN-XiaoxiaoNeural',
    this.seenSourceIds = const [],
    this.selectedId = '',
  });

  final String language;
  final String theme;
  final double fontScale;
  final List<String> enabledSources;
  final List<String> sourceOrder;
  final String snapshotRepo;
  final String snapshotUrl;
  final bool autoTranslate;
  final bool showOriginal;
  final String translationApiKey;
  final String translationBaseUrl;
  final String translationModel;
  final String feedFilter;
  final double listPaneWidth;
  final int lastVisitMs;
  final int newSinceMs;
  final bool useSystemProxy;
  final String proxyUrl;
  final String ttsVoice;
  final List<String> seenSourceIds;
  final String selectedId;

  bool get isZh => language != 'en';
  bool get isDark => theme != 'light';

  AppSettings copyWith({
    String? language,
    String? theme,
    double? fontScale,
    List<String>? enabledSources,
    List<String>? sourceOrder,
    String? snapshotRepo,
    String? snapshotUrl,
    bool? autoTranslate,
    bool? showOriginal,
    String? translationApiKey,
    String? translationBaseUrl,
    String? translationModel,
    String? feedFilter,
    double? listPaneWidth,
    int? lastVisitMs,
    int? newSinceMs,
    bool? useSystemProxy,
    String? proxyUrl,
    String? ttsVoice,
    List<String>? seenSourceIds,
    String? selectedId,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      fontScale: fontScale ?? this.fontScale,
      enabledSources: enabledSources ?? this.enabledSources,
      sourceOrder: sourceOrder ?? this.sourceOrder,
      snapshotRepo: snapshotRepo ?? this.snapshotRepo,
      snapshotUrl: snapshotUrl ?? this.snapshotUrl,
      autoTranslate: autoTranslate ?? this.autoTranslate,
      showOriginal: showOriginal ?? this.showOriginal,
      translationApiKey: translationApiKey ?? this.translationApiKey,
      translationBaseUrl: translationBaseUrl ?? this.translationBaseUrl,
      translationModel: translationModel ?? this.translationModel,
      feedFilter: feedFilter ?? this.feedFilter,
      listPaneWidth: listPaneWidth ?? this.listPaneWidth,
      lastVisitMs: lastVisitMs ?? this.lastVisitMs,
      newSinceMs: newSinceMs ?? this.newSinceMs,
      useSystemProxy: useSystemProxy ?? this.useSystemProxy,
      proxyUrl: proxyUrl ?? this.proxyUrl,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      seenSourceIds: seenSourceIds ?? this.seenSourceIds,
      selectedId: selectedId ?? this.selectedId,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'theme': theme,
        'fontScale': fontScale,
        'enabledSources': enabledSources,
        'sourceOrder': sourceOrder,
        'snapshotRepo': snapshotRepo,
        'snapshotUrl': snapshotUrl,
        'autoTranslate': autoTranslate,
        'showOriginal': showOriginal,
        'translationBaseUrl': translationBaseUrl,
        'translationModel': translationModel,
        'feedFilter': feedFilter,
        'listPaneWidth': listPaneWidth,
        'lastVisitMs': lastVisitMs,
        'newSinceMs': newSinceMs,
        'useSystemProxy': useSystemProxy,
        'proxyUrl': proxyUrl,
        'ttsVoice': ttsVoice,
        'seenSourceIds': seenSourceIds,
        'selectedId': selectedId,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: json['language'] as String? ?? 'zh',
      theme: json['theme'] as String? ?? 'dark',
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      enabledSources: (json['enabledSources'] as List?)?.cast<String>() ?? const [],
      sourceOrder: (json['sourceOrder'] as List?)?.cast<String>() ?? const [],
      snapshotRepo: json['snapshotRepo'] as String? ?? '',
      snapshotUrl: json['snapshotUrl'] as String? ?? '',
      autoTranslate: json['autoTranslate'] as bool? ?? true,
      showOriginal: json['showOriginal'] as bool? ?? false,
      translationApiKey: json['translationApiKey'] as String? ?? '',
      translationBaseUrl: json['translationBaseUrl'] as String? ?? 'https://api.deepseek.com/v1',
      translationModel: json['translationModel'] as String? ?? 'deepseek-chat',
      feedFilter: json['feedFilter'] as String? ?? 'all',
      listPaneWidth: (json['listPaneWidth'] as num?)?.toDouble() ?? 400,
      lastVisitMs: (json['lastVisitMs'] as num?)?.toInt() ?? 0,
      newSinceMs: (json['newSinceMs'] as num?)?.toInt() ?? 0,
      useSystemProxy: json['useSystemProxy'] as bool? ?? true,
      proxyUrl: json['proxyUrl'] as String? ?? '',
      ttsVoice: json['ttsVoice'] as String? ?? json['ttsVoiceZh'] as String? ?? 'zh-CN-XiaoxiaoNeural',
      seenSourceIds: (json['seenSourceIds'] as List?)?.cast<String>() ?? const [],
      selectedId: json['selectedId'] as String? ?? '',
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'inkbrief.settings';
  static const _secretKey = 'inkbrief.translationApiKey';
  static const _storage = FlutterSecureStorage();

  @override
  AppSettings build() => const AppSettings();

  Future<void> hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      var next = const AppSettings();
      if (raw != null && raw.isNotEmpty) {
        next = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
      var secret = '';
      try {
        secret = await _storage.read(key: _secretKey) ?? '';
      } catch (e, st) {
        debugPrint('secure storage read failed: $e\n$st');
      }
      if (secret.isEmpty && next.translationApiKey.isNotEmpty) {
        secret = next.translationApiKey;
        try {
          await _storage.write(key: _secretKey, value: secret);
        } catch (e, st) {
          debugPrint('secure storage migrate failed: $e\n$st');
        }
      }
      next = next.copyWith(translationApiKey: secret);
      state = next;
      await prefs.setString(_key, jsonEncode(next.toJson()));
    } catch (e, st) {
      debugPrint('settings hydrate failed: $e\n$st');
      state = const AppSettings();
    }
  }

  Future<void> update(AppSettings next, {bool persist = true}) async {
    state = next;
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(next.toJson()));
    try {
      if (next.translationApiKey.trim().isEmpty) {
        await _storage.delete(key: _secretKey);
      } else {
        await _storage.write(key: _secretKey, value: next.translationApiKey.trim());
      }
    } catch (e, st) {
      debugPrint('secure storage write failed: $e\n$st');
    }
  }

  Future<void> beginSession() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = state.lastVisitMs;
    final newSince = last == 0 ? now - const Duration(hours: 24).inMilliseconds : last;
    await update(state.copyWith(newSinceMs: newSince, lastVisitMs: now));
  }

  Future<void> touchVisit() async {
    await update(state.copyWith(lastVisitMs: DateTime.now().millisecondsSinceEpoch));
  }

  Future<void> setSourceEnabled(
    String id,
    bool on, {
    Iterable<String> catalogEnabledIds = const [],
  }) async {
    final next = applySourceEnabled(
      enabledSources: state.enabledSources,
      seenSourceIds: state.seenSourceIds,
      catalogEnabledIds: catalogEnabledIds,
      id: id,
      on: on,
    );
    final seen = [...state.seenSourceIds];
    if (!seen.contains(id)) seen.add(id);
    await update(state.copyWith(enabledSources: next, seenSourceIds: seen));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
