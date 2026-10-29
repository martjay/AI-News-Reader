import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_core/news_core.dart';

import 'article_record.dart';
import 'body_fetch.dart';
import 'feed_filter.dart';
import 'settings.dart';
import 'tts_controller.dart';
import '../services/database.dart';
import '../services/feed_service.dart';
import '../services/translate_service.dart';

class NewsState {
  const NewsState({
    this.ready = false,
    this.refreshing = false,
    this.catalog,
    this.records = const [],
    this.statuses = const {},
    this.selectedId,
    this.partialFailure = false,
    this.banner,
    this.translateFailedId,
    this.translating = false,
    this.loadingBody = false,
    this.translatingBody = false,
  });

  final bool ready;
  final bool refreshing;
  final SourceCatalog? catalog;
  final List<ArticleRecord> records;
  final Map<String, SourceFetchResult> statuses;
  final String? selectedId;
  final bool partialFailure;
  final String? banner;
  final String? translateFailedId;
  final bool translating;
  final bool loadingBody;
  final bool translatingBody;

  ArticleRecord? get selected {
    if (selectedId == null) return null;
    for (final r in records) {
      if (r.item.id == selectedId) return r;
    }
    return null;
  }

  NewsState copyWith({
    bool? ready,
    bool? refreshing,
    SourceCatalog? catalog,
    List<ArticleRecord>? records,
    Map<String, SourceFetchResult>? statuses,
    String? selectedId,
    bool clearSelected = false,
    bool? partialFailure,
    String? banner,
    bool clearBanner = false,
    String? translateFailedId,
    bool clearTranslateFailed = false,
    bool? translating,
    bool? loadingBody,
    bool? translatingBody,
  }) {
    return NewsState(
      ready: ready ?? this.ready,
      refreshing: refreshing ?? this.refreshing,
      catalog: catalog ?? this.catalog,
      records: records ?? this.records,
      statuses: statuses ?? this.statuses,
      selectedId: clearSelected ? null : (selectedId ?? this.selectedId),
      partialFailure: partialFailure ?? this.partialFailure,
      banner: clearBanner ? null : (banner ?? this.banner),
      translateFailedId: clearTranslateFailed ? null : (translateFailedId ?? this.translateFailedId),
      translating: translating ?? this.translating,
      loadingBody: loadingBody ?? this.loadingBody,
      translatingBody: translatingBody ?? this.translatingBody,
    );
  }
}

class NewsController extends Notifier<NewsState> {
  final _feeds = FeedService();
  NewsDatabase? _db;
  final _loadingBodies = <String>{};

  @override
  NewsState build() => const NewsState();

  Future<void> bootstrap() async {
    try {
      _db ??= await NewsDatabase.open();
      final prior = ref.read(settingsProvider);
      await ref.read(settingsProvider.notifier).beginSession();
      await applyProxyFromSettings(ref.read(settingsProvider));
      final catalog = await _feeds.loadCatalog();
      final settings = ref.read(settingsProvider);
      var enabled = [...prior.enabledSources];
      var seen = [...prior.seenSourceIds];
      final catalogIds = catalog.sources.map((s) => s.id).toList();
      final returning = prior.lastVisitMs != 0 || prior.enabledSources.isNotEmpty || prior.sourceOrder.isNotEmpty;
      if (seen.isEmpty) {
        seen = catalogIds;
        if (enabled.isEmpty && !returning) {
          enabled = pinPreferredSource(catalog.enabled.where((s) => !s.board).map((s) => s.id).toList());
        }
      } else {
        for (final source in catalog.sources) {
          if (seen.contains(source.id)) continue;
          seen.add(source.id);
        }
      }
      final order = settings.sourceOrder.isEmpty
          ? pinPreferredSource(enabled)
          : [
              ...settings.sourceOrder,
              ...catalogIds.where((id) => !settings.sourceOrder.contains(id)),
            ];
      if (!_sameList(enabled, settings.enabledSources) ||
          !_sameList(seen, settings.seenSourceIds) ||
          !_sameList(order, settings.sourceOrder)) {
        await ref.read(settingsProvider.notifier).update(
              settings.copyWith(enabledSources: enabled, seenSourceIds: seen, sourceOrder: order),
            );
      }
      await _db!.prune(keepId: prior.selectedId);
      final records = await _db!.loadArticles();
      final statuses = await _db!.loadStatuses();
      final restore = prior.selectedId;
      final hasRestore = restore.isNotEmpty && records.any((r) => r.item.id == restore);
      state = state.copyWith(
        ready: true,
        catalog: catalog,
        records: records,
        statuses: statuses,
        selectedId: hasRestore ? restore : null,
        clearSelected: !hasRestore,
      );
      await refresh();
    } catch (e, st) {
      debugPrint('bootstrap failed: $e\n$st');
      var catalog = state.catalog;
      if (catalog == null) {
        try {
          catalog = await _feeds.loadCatalog();
        } catch (catalogError, catalogStack) {
          debugPrint('bootstrap catalog retry failed: $catalogError\n$catalogStack');
        }
      }
      state = state.copyWith(
        ready: true,
        catalog: catalog,
        banner: 'network',
        partialFailure: true,
      );
    }
  }

  Future<void> retryStart() async {
    if (state.refreshing) return;
    if (state.catalog != null) {
      await refresh();
      return;
    }
    state = state.copyWith(ready: false, clearBanner: true);
    await bootstrap();
  }

  Set<String> get enabledSourceIds => _enabled;

  Set<String> get _enabled {
    final settings = ref.read(settingsProvider);
    return resolveEnabledSourceIds(
      enabledSources: settings.enabledSources,
      seenSourceIds: settings.seenSourceIds,
      catalogEnabledIds: [...?state.catalog?.enabled.map((s) => s.id)],
    );
  }

  List<ArticleRecord> visibleRecords() {
    final enabled = _enabled;
    final filter = resolveFeedSource(ref.read(settingsProvider).feedFilter, enabled);
    return [
      for (final r in state.records)
        if (enabled.contains(r.item.sourceId) && (filter == 'all' || r.item.sourceId == filter)) r,
    ];
  }

  Future<void> setSourceEnabled(String id, bool on) async {
    await ref.read(settingsProvider.notifier).setSourceEnabled(
          id,
          on,
          catalogEnabledIds: [...?state.catalog?.enabled.map((s) => s.id)],
        );
    if (on) unawaited(refresh());
  }

  void selectAdjacent(int delta) {
    if (delta == 0) return;
    final ids = [for (final r in visibleRecords()) r.item.id];
    if (ids.isEmpty) return;
    final current = state.selectedId;
    final index = current == null ? -1 : ids.indexOf(current);
    late final int nextIndex;
    if (index < 0) {
      nextIndex = delta > 0 ? 0 : ids.length - 1;
    } else {
      nextIndex = (index + delta).clamp(0, ids.length - 1);
    }
    final next = ids[nextIndex];
    if (next == current) return;
    unawaited(markRead(next));
    select(next);
  }

  Future<void> refresh() async {
    final catalog = state.catalog;
    final db = _db;
    if (catalog == null || db == null || state.refreshing) return;
    state = state.copyWith(refreshing: true, clearBanner: true, partialFailure: false);
    var failed = false;
    try {
      final enabled = _enabled;
      final direct = catalog.direct.where((s) => enabled.contains(s.id)).toList();
      final snapshotSources = catalog.snapshot.where((s) => enabled.contains(s.id)).toList();

      final incoming = <NewsItem>[];
      final got = <String>{};
      final liveOverseas = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      final fetchList = [
        ...direct,
        if (liveOverseas) ...snapshotSources,
      ];
      if (fetchList.isNotEmpty) {
        final results = await _feeds.fetchDirect(fetchList);
        for (final result in results) {
          if (result.items.isNotEmpty) {
            await db.upsertStatus(result);
            incoming.addAll(result.items);
            got.add(result.sourceId);
          } else {
            final source = catalog.byId(result.sourceId);
            if (source?.access == SourceAccess.direct) {
              await db.upsertStatus(result);
              if (source?.fragile != true) failed = true;
            }
          }
        }
      }

      NewsSnapshot? snap;
      var usedRemote = false;
      final url = _feeds.resolveSnapshotUrl(ref.read(settingsProvider), catalog);
      if (url != null) {
        try {
          snap = await _feeds.fetchRemoteSnapshot(url);
          usedRemote = snap != null;
        } catch (e, st) {
          debugPrint('snapshot fetch failed: $e\n$st');
          failed = true;
          state = state.copyWith(banner: 'snapshot');
        }
      }
      snap ??= await _feeds.loadBundledSnapshot();
      for (final source in snapshotSources) {
        if (got.contains(source.id)) continue;
        final result = snap.sources[source.id];
        if (result == null) continue;
        if (result.items.isNotEmpty) {
          await db.upsertStatus(result);
          incoming.addAll(result.items.map((e) => e.copyWith(sourceId: source.id)));
        } else if (usedRemote && result.status != 'ok') {
          failed = true;
          await db.upsertStatus(result);
        } else if (!usedRemote) {
          final hasCached = state.records.any((r) => r.item.sourceId == source.id);
          if (hasCached) {
            await db.upsertStatus(SourceFetchResult(
              sourceId: source.id,
              status: 'ok',
              updatedAt: DateTime.now(),
            ));
          }
        }
      }

      if (incoming.isNotEmpty) {
        final stored = await db.loadRecentForDedupe();
        final encodedStored = [for (final item in stored) item.toJson()];
        final encodedIncoming = [for (final item in incoming) item.toJson()];
        final mergedJson = await Isolate.run(() {
          final existing = [
            for (final row in encodedStored) NewsItem.fromJson(Map<String, dynamic>.from(row as Map)),
          ];
          final fresh = [
            for (final row in encodedIncoming) NewsItem.fromJson(Map<String, dynamic>.from(row as Map)),
          ];
          return [for (final item in mergeIncoming(existing, fresh)) item.toJson()];
        });
        final merged = [
          for (final row in mergedJson) NewsItem.fromJson(Map<String, dynamic>.from(row as Map)),
        ];
        await db.upsertItems(merged);
      }
      await db.prune(keepId: state.selectedId);
      final records = await db.loadArticles();
      final statuses = await db.loadStatuses();
      state = state.copyWith(
        records: records,
        statuses: statuses,
        partialFailure: failed,
        banner: state.banner == 'snapshot'
            ? 'snapshot'
            : (failed && incoming.isEmpty ? 'partial' : state.banner),
      );
    } catch (e, st) {
      debugPrint('refresh failed: $e\n$st');
      state = state.copyWith(banner: 'network', partialFailure: true);
    } finally {
      state = state.copyWith(refreshing: false);
    }
    unawaited(translatePending());
  }

  Future<void> translatePending() async {
    final db = _db;
    if (db == null || state.translating) return;
    final settings = ref.read(settingsProvider);
    if (!settings.autoTranslate) return;

    final copied = <(String, String, String)>[];
    var records = [
      for (final rec in state.records)
        if (rec.titleZh.isEmpty && rec.item.title.isNotEmpty && isPrimarilyChinese(rec.item.title))
          rec.copyWith(titleZh: rec.item.title, summaryZh: rec.item.summary)
        else
          rec,
    ];
    for (final rec in records) {
      if (rec.titleZh == rec.item.title && rec.item.title.isNotEmpty && isPrimarilyChinese(rec.item.title)) {
        copied.add((rec.item.id, rec.item.title, rec.item.summary));
      }
    }
    if (copied.isNotEmpty) {
      await db.setTranslations(copied);
      state = state.copyWith(records: records);
    }

    final pending = records.where((r) => r.needsTranslation).take(80).toList();
    if (pending.isEmpty) return;

    state = state.copyWith(translating: true);
    final tx = TranslateService();
    final translated = <(String, String, String)>[];
    var failures = 0;
    try {
      for (final rec in pending) {
        if (!ref.read(settingsProvider).autoTranslate) break;
        var titleZh = rec.titleZh;
        var summaryZh = rec.summaryZh;
        try {
          if (titleZh.isEmpty && rec.item.title.isNotEmpty) {
            titleZh = isPrimarilyChinese(rec.item.title)
                ? rec.item.title
                : await tx.translateToZh(rec.item.title, ref.read(settingsProvider));
          }
          if (summaryZh.isEmpty && rec.item.summary.isNotEmpty) {
            summaryZh = isPrimarilyChinese(rec.item.summary)
                ? rec.item.summary
                : await tx.translateToZh(plaintextFromHtml(rec.item.summary), ref.read(settingsProvider));
          }
        } catch (e, st) {
          debugPrint('translatePending ${rec.item.id} failed: $e\n$st');
          failures++;
          continue;
        }
        translated.add((rec.item.id, titleZh, summaryZh));
        records = [
          for (final r in records)
            if (r.item.id == rec.item.id) r.copyWith(titleZh: titleZh, summaryZh: summaryZh) else r,
        ];
        state = state.copyWith(records: records, translating: true);
      }
      await db.setTranslations(translated);
    } finally {
      tx.close();
      if (failures > 0) {
        state = state.copyWith(translating: false, records: records, banner: 'translate');
      } else if (state.banner == 'translate') {
        state = state.copyWith(translating: false, records: records, clearBanner: true);
      } else {
        state = state.copyWith(translating: false, records: records);
      }
    }
    if (translated.isNotEmpty &&
        ref.read(settingsProvider).autoTranslate &&
        state.records.any((r) => r.needsTranslation)) {
      unawaited(translatePending());
    }
  }

  void dismissBanner() {
    state = state.copyWith(clearBanner: true);
  }

  void select(String? id) {
    final rec = id == null ? null : state.records.where((r) => r.item.id == id).firstOrNull;
    final needsBody = rec != null && shouldAutoFetchBody(rec.body, rec.bodyStatus);
    if (state.selectedId != id) unawaited(ref.read(ttsProvider.notifier).stop());
    state = state.copyWith(
      selectedId: id,
      clearSelected: id == null,
      loadingBody: id != null && _loadingBodies.contains(id),
    );
    unawaited(ref.read(settingsProvider.notifier).update(
          ref.read(settingsProvider).copyWith(selectedId: id ?? ''),
        ));
    if (needsBody) unawaited(fetchBody(id!));
  }

  Future<void> markVisibleRead(Iterable<String> ids) async {
    if (_db == null) return;
    final unread = ids.where((id) => state.records.any((r) => r.item.id == id && !r.read)).toList();
    if (unread.isEmpty) return;
    await _db!.markAllRead(unread);
    final marked = unread.toSet();
    state = state.copyWith(
      records: [
        for (final r in state.records)
          if (marked.contains(r.item.id)) r.copyWith(read: true) else r,
      ],
    );
  }

  Future<void> fetchBody(String id, {bool force = false}) async {
    final db = _db;
    if (db == null) return;
    final rec = state.records.where((r) => r.item.id == id).firstOrNull;
    if (rec == null) return;
    if (!force && rec.bodyStatus == 'ok' && rec.body.trim().isNotEmpty) return;
    if (_loadingBodies.contains(id)) return;
    _loadingBodies.add(id);
    if (state.selectedId == id) {
      state = state.copyWith(loadingBody: true);
    }
    try {
      final client = FetchClient(timeout: const Duration(seconds: 20));
      try {
        final extracted = await fetchReadable(
          client,
          rec.item.url,
          seedHtml: rec.item.summary,
          preferRemote: true,
        );
        final stored = applyFetchedBody(
          previousBody: rec.body,
          previousBodyZh: rec.bodyZh,
          fetchedText: extracted.text,
          fetchedStatus: extracted.ok ? 'ok' : (extracted.text.trim().isEmpty ? 'empty' : extracted.status),
          summaryFallback: plaintextFromHtml(rec.item.summary, url: rec.item.url),
        );
        await db.setBody(id, body: stored.body, bodyZh: stored.bodyZh, status: stored.status);
        state = state.copyWith(
          records: [
            for (final r in state.records)
              if (r.item.id == id)
                r.copyWith(body: stored.body, bodyZh: stored.bodyZh, bodyStatus: stored.status)
              else
                r,
          ],
          clearBanner: stored.status == 'ok' && state.selectedId == id,
          banner: stored.status == 'fail' && state.selectedId == id ? 'body' : null,
        );
      } finally {
        client.close();
      }
    } catch (e, st) {
      debugPrint('fetchBody $id failed: $e\n$st');
      final latest = state.records.where((r) => r.item.id == id).firstOrNull ?? rec;
      final stored = applyFailedBody(
        previousBody: latest.body,
        previousBodyZh: latest.bodyZh,
        summaryFallback: plaintextFromHtml(latest.item.summary, url: latest.item.url),
      );
      try {
        await db.setBody(id, body: stored.body, bodyZh: stored.bodyZh, status: stored.status);
      } catch (persistError, persistStack) {
        debugPrint('fetchBody persist fail $id: $persistError\n$persistStack');
      }
      state = state.copyWith(
        records: [
          for (final r in state.records)
            if (r.item.id == id)
              r.copyWith(body: stored.body, bodyZh: stored.bodyZh, bodyStatus: stored.status)
            else
              r,
        ],
        banner: state.selectedId == id ? 'body' : state.banner,
      );
    } finally {
      _loadingBodies.remove(id);
      state = state.copyWith(
        loadingBody: state.selectedId != null && _loadingBodies.contains(state.selectedId),
      );
    }
  }

  Future<void> translateArticle(String id) async {
    final db = _db;
    if (db == null || state.translatingBody) return;
    final rec = state.records.where((r) => r.item.id == id).firstOrNull;
    if (rec == null) return;

    state = state.copyWith(translatingBody: true, clearBanner: true, clearTranslateFailed: true);
    final tx = TranslateService();
    try {
      var titleZh = rec.titleZh;
      var summaryZh = rec.summaryZh;
      var bodyZh = rec.bodyZh;
      final settings = ref.read(settingsProvider);
      Future<void> publish({String? nextTitle, String? nextSummary, String? nextBody}) async {
        if (nextTitle != null) titleZh = nextTitle;
        if (nextSummary != null) summaryZh = nextSummary;
        if (nextBody != null) bodyZh = nextBody;
        await db.setTranslation(id, titleZh: titleZh, summaryZh: summaryZh);
        await db.setBody(id, body: rec.body, bodyZh: bodyZh, status: rec.bodyStatus);
        state = state.copyWith(
          translatingBody: true,
          records: [
            for (final r in state.records)
              if (r.item.id == id)
                r.copyWith(titleZh: titleZh, summaryZh: summaryZh, bodyZh: bodyZh)
              else
                r,
          ],
        );
      }

      if (rec.item.title.isNotEmpty && (titleZh.isEmpty || hasTranslatableLatin(rec.item.title))) {
        await publish(
          nextTitle: hasTranslatableLatin(rec.item.title)
              ? await tx.translateToZh(rec.item.title, settings)
              : rec.item.title,
        );
      }
      if (rec.body.trim().isNotEmpty) {
        await tx.translateToZh(
          rec.body,
          settings,
          onPartial: (partial) => publish(nextBody: partial),
        );
      } else {
        final summarySrc = plaintextFromHtml(rec.item.summary);
        if (summarySrc.isNotEmpty) {
          await tx.translateToZh(
            summarySrc,
            settings,
            onPartial: (partial) => publish(nextSummary: partial),
          );
        }
      }
    } catch (e, st) {
      debugPrint('translateArticle $id failed: $e\n$st');
      state = state.copyWith(banner: 'translate', translateFailedId: id);
    } finally {
      tx.close();
      state = state.copyWith(translatingBody: false);
    }
  }

  Future<void> toggleSaved(String id) async {
    final rec = state.records.where((r) => r.item.id == id).firstOrNull;
    if (rec == null || _db == null) return;
    final next = !rec.saved;
    await _db!.setSaved(id, next);
    state = state.copyWith(
      records: [
        for (final r in state.records)
          if (r.item.id == id) r.copyWith(saved: next) else r,
      ],
    );
  }

  Future<void> markRead(String id) async {
    if (_db == null) return;
    await _db!.setRead(id, true);
    state = state.copyWith(
      records: [
        for (final r in state.records)
          if (r.item.id == id) r.copyWith(read: true) else r,
      ],
    );
  }
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Future<String> applyProxyFromSettings(AppSettings settings) async {
  return applyFetchProxy(useSystem: settings.useSystemProxy, manual: settings.proxyUrl);
}

final newsProvider = NotifierProvider<NewsController, NewsState>(NewsController.new);
