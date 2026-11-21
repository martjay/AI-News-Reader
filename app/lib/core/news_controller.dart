import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_core/news_core.dart';

import 'article_record.dart';
import 'body_fetch.dart';
import 'feed_filter.dart';
import 'refresh_publish.dart';
import 'serial.dart';
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
    this.translatingBodyId,
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
  final String? translatingBodyId;

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
    String? translatingBodyId,
    bool clearTranslatingBody = false,
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
      translatingBodyId: clearTranslatingBody ? null : (translatingBodyId ?? this.translatingBodyId),
    );
  }
}

class NewsController extends Notifier<NewsState> {
  final _feeds = FeedService();
  NewsDatabase? _db;
  final _loadingBodies = <String>{};
  final _bodyToken = <String, int>{};
  final _refreshGate = RefreshGate();
  final _translateTried = <String>{};
  var _translateToken = 0;
  var _translateRunning = false;
  var _translateAgain = false;
  var _translateQuiet = false;

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
        final adopted = adoptUnseenSources(
          enabledSources: enabled,
          seenSourceIds: seen,
          sources: catalog.sources,
        );
        enabled = adopted.enabled;
        seen = adopted.seen;
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
        await ref.read(settingsProvider.notifier).mutate(
              (current) => current.copyWith(enabledSources: enabled, seenSourceIds: seen, sourceOrder: order),
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
    _translateQuiet = false;
    _translateTried.clear();
    if (!_refreshGate.request()) return;
    await _drainRefresh();
  }

  Future<void> _drainRefresh() async {
    try {
      await _refreshBody();
    } finally {
      if (_refreshGate.finish()) {
        await _drainRefresh();
      } else {
        if (state.refreshing) state = state.copyWith(refreshing: false);
        unawaited(translatePending());
      }
    }
  }

  Future<void> _refreshBody() async {
    final catalog = state.catalog;
    final db = _db;
    if (catalog == null || db == null) return;
    state = state.copyWith(refreshing: true, clearBanner: true, partialFailure: false);
    var failed = false;
    var fetchedItems = 0;
    try {
      final enabled = _enabled;
      final direct = catalog.direct.where((s) => enabled.contains(s.id)).toList();
      final snapshotSources = catalog.snapshot.where((s) => enabled.contains(s.id)).toList();
      final got = <String>{};
      var known = await db.loadRecentForDedupe();

      void showStatus(SourceFetchResult result) {
        final statuses = Map<String, SourceFetchResult>.of(state.statuses);
        statuses[result.sourceId] = result;
        state = state.copyWith(statuses: statuses);
      }

      Future<void> showItems(SourceFetchResult result, List<NewsItem> items) async {
        await db.upsertStatus(result);
        final folded = foldIncoming(known, items);
        known = folded.known;
        if (folded.changed.isNotEmpty) await db.upsertItems(folded.changed);
        fetchedItems += items.length;
        got.add(result.sourceId);
        final statuses = Map<String, SourceFetchResult>.of(state.statuses);
        statuses[result.sourceId] = result;
        state = state.copyWith(
          records: recordsAfterIncoming(state.records, folded.changed),
          statuses: statuses,
        );
      }

      final liveOverseas = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      final fetchList = [
        ...direct,
        if (liveOverseas) ...snapshotSources,
      ];
      final gate = Serial();
      Future<void> acceptLive(SourceFetchResult result) {
        return gate.run(() async {
          if (result.items.isNotEmpty) {
            await showItems(result, result.items);
            return;
          }
          final source = catalog.byId(result.sourceId);
          if (source?.access == SourceAccess.direct) {
            await db.upsertStatus(result);
            if (source?.fragile != true) failed = true;
            showStatus(result);
          }
        });
      }

      final snapshotApplied = _downloadSnapshot(catalog).then((downloaded) async {
        if (downloaded.failed) {
          await gate.run(() async {
            failed = true;
            state = state.copyWith(banner: 'snapshot');
          });
        }
        final snap = downloaded.remote ?? await _feeds.loadBundledSnapshot();
        for (final source in snapshotSources) {
          await gate.run(() async {
            if (got.contains(source.id)) return;
            final result = snap.sources[source.id];
            if (result == null) return;
            if (result.items.isNotEmpty) {
              final stamped = SourceFetchResult(
                sourceId: source.id,
                status: result.status,
                updatedAt: result.updatedAt,
                error: result.error,
                items: [for (final item in result.items) item.copyWith(sourceId: source.id)],
              );
              await showItems(stamped, stamped.items);
            } else if (downloaded.remote != null && result.status != 'ok') {
              failed = true;
              final stamped = SourceFetchResult(
                sourceId: source.id,
                status: result.status,
                updatedAt: result.updatedAt,
                error: result.error,
              );
              await db.upsertStatus(stamped);
              showStatus(stamped);
            } else if (downloaded.remote == null) {
              final hasCached = state.records.any((r) => r.item.sourceId == source.id);
              if (hasCached) {
                final cached = SourceFetchResult(
                  sourceId: source.id,
                  status: 'ok',
                  updatedAt: DateTime.now(),
                );
                await db.upsertStatus(cached);
                showStatus(cached);
              }
            }
          });
        }
      });
      if (fetchList.isNotEmpty) {
        await _feeds.fetchDirect(fetchList, onEach: acceptLive);
      }
      await snapshotApplied;

      await db.prune(keepId: state.selectedId);
      final loaded = await db.loadArticles();
      final statuses = await db.loadStatuses();
      final live = {for (final record in state.records) record.item.id: record};
      final records = [for (final row in loaded) preserveFetchedBody(row, live[row.item.id])];
      state = state.copyWith(
        records: records,
        statuses: statuses,
        partialFailure: failed,
        banner: state.banner == 'snapshot'
            ? 'snapshot'
            : (failed && fetchedItems == 0 ? 'partial' : state.banner),
      );
    } catch (e, st) {
      debugPrint('refresh failed: ${e.runtimeType}\n$st');
      state = state.copyWith(banner: 'network', partialFailure: true);
    }
  }

  Future<({NewsSnapshot? remote, bool failed})> _downloadSnapshot(SourceCatalog catalog) async {
    final url = _feeds.resolveSnapshotUrl(ref.read(settingsProvider), catalog);
    if (url == null) return (remote: null, failed: false);
    try {
      return (remote: await _feeds.fetchRemoteSnapshot(url), failed: false);
    } catch (e, st) {
      debugPrint('snapshot fetch failed: $e\n$st');
      return (remote: null, failed: true);
    }
  }

  String? _selectedSourceId() {
    final filter = resolveFeedSource(ref.read(settingsProvider).feedFilter, _enabled);
    if (filter == 'all') return null;
    return filter;
  }

  bool _inSelectedSource(ArticleRecord rec) {
    final source = _selectedSourceId();
    return source != null && rec.item.sourceId == source;
  }

  bool _needsTitle(ArticleRecord rec) {
    return _inSelectedSource(rec) &&
        rec.titleZh.isEmpty &&
        rec.item.title.isNotEmpty &&
        !isPrimarilyChinese(rec.item.title) &&
        !_translateTried.contains('${rec.item.id}:title');
  }

  bool _needsSummary(ArticleRecord rec) {
    final summary = rec.item.summary.trim();
    return _inSelectedSource(rec) &&
        rec.summaryZh.isEmpty &&
        summary.isNotEmpty &&
        !isPrimarilyChinese(summary) &&
        !_translateTried.contains('${rec.item.id}:summary');
  }

  List<ArticleRecord> _translationQueue({required bool titlesOnly}) {
    final out = <ArticleRecord>[];
    for (final rec in state.records) {
      final title = _needsTitle(rec);
      final summary = !titlesOnly && _needsSummary(rec);
      if (!title && !summary) continue;
      out.add(rec);
      if (out.length >= 8) break;
    }
    return out;
  }

  bool get _hasQuietWork {
    for (final rec in state.records) {
      if (_needsTitle(rec) || _needsSummary(rec)) return true;
    }
    return false;
  }

  Future<void> translatePending() async {
    final db = _db;
    if (db == null || !ref.read(settingsProvider).autoTranslate) return;
    if (_translateRunning) {
      _translateAgain = true;
      return;
    }
    _translateRunning = true;
    var failures = 0;
    var saved = 0;
    var showBanner = false;
    TranslateService? tx;
    final sourceAtStart = _selectedSourceId();
    try {
      final copied = <(String, String, String)>[];
      for (final rec in state.records) {
        if (rec.item.sourceId != sourceAtStart) continue;
        if (rec.titleZh.isEmpty && rec.item.title.isNotEmpty && isPrimarilyChinese(rec.item.title)) {
          copied.add((rec.item.id, rec.item.title, rec.item.summary));
        }
      }
      if (copied.isNotEmpty) {
        await db.setTranslations(copied);
        final copiedIds = copied.map((row) => row.$1).toSet();
        state = state.copyWith(
          records: [
            for (final rec in state.records)
              if (copiedIds.contains(rec.item.id) && rec.titleZh.isEmpty && isPrimarilyChinese(rec.item.title))
                rec.copyWith(
                  titleZh: rec.item.title,
                  summaryZh: rec.summaryZh.isEmpty ? rec.item.summary : rec.summaryZh,
                )
              else
                rec,
          ],
        );
      }

      showBanner = !_translateQuiet && _translationQueue(titlesOnly: true).isNotEmpty;
      final pending = _translationQueue(titlesOnly: showBanner);
      if (pending.isEmpty) {
        if (!_translateQuiet && _hasQuietWork) _translateAgain = true;
        return;
      }
      if (showBanner && !_translateQuiet) state = state.copyWith(translating: true);
      tx = TranslateService(timeout: const Duration(seconds: 8));
      final translated = <(String, String, String)>[];
      for (final rec in pending) {
        if (!ref.read(settingsProvider).autoTranslate || (_translateQuiet && showBanner)) break;
        if (_selectedSourceId() != sourceAtStart) break;
        final titleKey = '${rec.item.id}:title';
        final summaryKey = '${rec.item.id}:summary';
        final translateTitle = _needsTitle(rec);
        final translateSummary = !showBanner && _needsSummary(rec);
        if (translateTitle) _translateTried.add(titleKey);
        if (translateSummary) _translateTried.add(summaryKey);
        var titleZh = rec.titleZh;
        var summaryZh = rec.summaryZh;
        try {
          final settings = ref.read(settingsProvider);
          if (translateTitle) {
            titleZh = await tx.translateToZh(rec.item.title, settings);
          }
          if (translateSummary) {
            final source = plaintextFromHtml(rec.item.summary);
            final clipped = source.length > 500 ? source.substring(0, 500) : source;
            if (clipped.trim().isNotEmpty && !isPrimarilyChinese(clipped)) {
              summaryZh = await tx.translateToZh(clipped, settings);
            }
          }
        } catch (e, st) {
          debugPrint('translatePending ${rec.item.id} failed: ${e.runtimeType}\n$st');
          failures++;
          continue;
        }
        if (titleZh.isEmpty) titleZh = rec.item.title;
        saved++;
        translated.add((rec.item.id, titleZh, summaryZh));
        final latest = {
          for (final current in state.records) current.item.id: current,
        };
        final row = latest[rec.item.id];
        if (row != null) {
          state = state.copyWith(
            records: [
              for (final current in state.records)
                if (current.item.id == rec.item.id)
                  current.copyWith(titleZh: titleZh, summaryZh: summaryZh.isEmpty ? current.summaryZh : summaryZh)
                else
                  current,
            ],
          );
        }
      }
      await db.setTranslations(translated);
    } finally {
      tx?.close();
      _translateRunning = false;
      final dismissed = _translateQuiet;
      if (showBanner && saved == 0 && failures > 0 && !dismissed) {
        state = state.copyWith(translating: false, banner: 'translate');
      } else if (state.banner == 'translate' && failures == 0) {
        state = state.copyWith(translating: false, clearBanner: true);
      } else {
        state = state.copyWith(translating: false);
      }
      final sourceNow = _selectedSourceId();
      final switched = sourceNow != sourceAtStart;
      if (switched) _translateQuiet = false;
      final followUp = _translateAgain || (!switched && _hasQuietWork);
      _translateAgain = false;
      if (followUp && ref.read(settingsProvider).autoTranslate && sourceNow != null && (switched || _hasQuietWork)) {
        if (!switched) _translateQuiet = true;
        unawaited(translatePending());
      }
    }
  }

  void dismissBanner() {
    _translateQuiet = true;
    state = state.copyWith(clearBanner: true, translating: false);
  }

  Future<void> retryBanner() async {
    final banner = state.banner;
    final failedId = state.translateFailedId;
    final selected = state.selectedId;
    switch (banner) {
      case 'body':
        if (selected != null) await fetchBody(selected, force: true);
      case 'translate':
        _translateQuiet = false;
        _translateTried.clear();
        if (failedId != null) {
          await translateArticle(failedId);
        } else {
          await translatePending();
        }
      case 'network':
        await retryStart();
      default:
        await refresh();
    }
  }

  void select(String? id) {
    final rec = id == null ? null : state.records.where((r) => r.item.id == id).firstOrNull;
    final needsBody = rec != null && shouldAutoFetchBody(rec.body, rec.bodyStatus);
    if (state.selectedId != id) unawaited(ref.read(ttsProvider.notifier).stop());
    final clearBodyBanner = state.banner == 'body' && id != state.selectedId;
    state = state.copyWith(
      selectedId: id,
      clearSelected: id == null,
      loadingBody: id != null && _loadingBodies.contains(id),
      clearBanner: clearBodyBanner,
      clearTranslateFailed: state.translateFailedId != null && state.translateFailedId != id,
    );
    unawaited(ref.read(settingsProvider.notifier).mutate((current) => current.copyWith(selectedId: id ?? '')));
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
    final token = (_bodyToken[id] ?? 0) + 1;
    _bodyToken[id] = token;
    _loadingBodies.add(id);
    if (state.selectedId == id) {
      state = state.copyWith(loadingBody: true);
    }
    bool mine() => _bodyToken[id] == token;
    void publish(StoredBody stored) {
      if (!mine()) return;
      final nextBanner = bannerAfterBodyFetch(
        current: state.banner,
        status: stored.status,
        selected: state.selectedId == id,
      );
      state = state.copyWith(
        records: [
          for (final r in state.records)
            if (r.item.id == id)
              r.copyWith(body: stored.body, bodyZh: stored.bodyZh, bodyStatus: stored.status)
            else
              r,
        ],
        clearBanner: nextBanner == null,
        banner: nextBanner,
      );
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
        if (!mine()) return;
        final stored = applyFetchedBody(
          previousBody: rec.body,
          previousBodyZh: rec.bodyZh,
          fetchedText: extracted.text,
          fetchedStatus: extracted.ok ? 'ok' : (extracted.text.trim().isEmpty ? 'empty' : extracted.status),
          summaryFallback: plaintextFromHtml(rec.item.summary, url: rec.item.url),
        );
        await db.setBody(id, body: stored.body, bodyZh: stored.bodyZh, status: stored.status);
        publish(stored);
      } finally {
        client.close();
      }
    } catch (e, st) {
      debugPrint('fetchBody $id failed: ${e.runtimeType}\n$st');
      if (!mine()) return;
      final latest = state.records.where((r) => r.item.id == id).firstOrNull ?? rec;
      final stored = applyFailedBody(
        previousBody: latest.body,
        previousBodyZh: latest.bodyZh,
        summaryFallback: plaintextFromHtml(latest.item.summary, url: latest.item.url),
      );
      try {
        await db.setBody(id, body: stored.body, bodyZh: stored.bodyZh, status: stored.status);
      } catch (persistError, persistStack) {
        debugPrint('fetchBody persist fail $id: ${persistError.runtimeType}\n$persistStack');
      }
      publish(stored);
    } finally {
      if (mine()) {
        _loadingBodies.remove(id);
        state = state.copyWith(
          loadingBody: state.selectedId != null && _loadingBodies.contains(state.selectedId),
        );
      }
    }
  }

  Future<void> translateArticle(String id) async {
    final db = _db;
    if (db == null || state.translatingBodyId == id) return;
    final rec = state.records.where((r) => r.item.id == id).firstOrNull;
    if (rec == null) return;

    final token = ++_translateToken;
    bool mine() => token == _translateToken;
    state = state.copyWith(translatingBodyId: id, clearBanner: true, clearTranslateFailed: true);
    final tx = TranslateService();
    try {
      var titleZh = rec.titleZh;
      var summaryZh = rec.summaryZh;
      var bodyZh = rec.bodyZh;
      final settings = ref.read(settingsProvider);
      Future<void> publish({String? nextTitle, String? nextSummary, String? nextBody}) async {
        if (!mine()) return;
        if (nextTitle != null) titleZh = nextTitle;
        if (nextSummary != null) summaryZh = nextSummary;
        if (nextBody != null) bodyZh = nextBody;
        await db.setTranslation(id, titleZh: titleZh, summaryZh: summaryZh);
        if (!mine()) return;
        final current = state.records.where((r) => r.item.id == id).firstOrNull ?? rec;
        await db.setBody(id, body: current.body, bodyZh: bodyZh, status: current.bodyStatus);
        if (!mine()) return;
        state = state.copyWith(
          translatingBodyId: id,
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
        final translatedTitle = hasTranslatableLatin(rec.item.title)
            ? await tx.translateToZh(rec.item.title, settings)
            : rec.item.title;
        if (!mine()) return;
        await publish(nextTitle: translatedTitle);
      }
      if (!mine()) return;
      final latest = state.records.where((r) => r.item.id == id).firstOrNull ?? rec;
      if (latest.body.trim().isNotEmpty) {
        await tx.translateToZh(
          latest.body,
          settings,
          onPartial: (partial) => publish(nextBody: partial),
        );
      } else {
        final summarySrc = plaintextFromHtml(latest.item.summary);
        if (summarySrc.isNotEmpty) {
          await tx.translateToZh(
            summarySrc,
            settings,
            onPartial: (partial) => publish(nextSummary: partial),
          );
        }
      }
    } catch (e, st) {
      debugPrint('translateArticle $id failed: ${e.runtimeType}\n$st');
      if (mine()) state = state.copyWith(banner: 'translate', translateFailedId: id);
    } finally {
      tx.close();
      if (mine()) state = state.copyWith(clearTranslatingBody: true);
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
