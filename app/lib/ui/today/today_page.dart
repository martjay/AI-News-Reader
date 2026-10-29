import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:news_core/news_core.dart';

import '../../core/article_record.dart';
import '../../core/feed_filter.dart';
import '../../core/news_controller.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../shell/adaptive_shell.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/article_tile.dart';
import '../widgets/brief_story_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/feed_filter_bar.dart';
import '../widgets/section_header.dart';

enum _RowKind { header, brief, article }

class _FeedRow {
  const _FeedRow.header({
    required this.label,
    this.unread = 0,
    this.failed = false,
    this.tightTop = false,
    this.markAll = false,
  })  : kind = _RowKind.header,
        story = null,
        record = null,
        hideSource = false;

  const _FeedRow.brief(this.story, this.record)
      : kind = _RowKind.brief,
        label = '',
        unread = 0,
        failed = false,
        tightTop = false,
        markAll = false,
        hideSource = false;

  const _FeedRow.article(this.record, {required this.hideSource})
      : kind = _RowKind.article,
        story = null,
        label = '',
        unread = 0,
        failed = false,
        tightTop = false,
        markAll = false;

  final _RowKind kind;
  final String label;
  final int unread;
  final bool failed;
  final bool tightTop;
  final bool markAll;
  final BriefStory? story;
  final ArticleRecord? record;
  final bool hideSource;

  Iterable<String> get locateIds {
    if (story != null) return story!.memberIds;
    if (record != null) return [record!.item.id];
    return const [];
  }
}

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key, required this.palette});

  final AppPalette palette;

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  final _rowKeys = <String, GlobalKey>{};
  final _scroll = ScrollController();
  List<_FeedRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyForRow(_FeedRow row) {
    final ids = row.locateIds.toList();
    final lead = ids.isEmpty ? '' : ids.first;
    final key = _rowKeys.putIfAbsent(lead, GlobalKey.new);
    for (final id in ids) {
      _rowKeys[id] = key;
    }
    return key;
  }

  Future<void> _scrollToSelected() async {
    final id = ref.read(newsProvider).selectedId;
    if (id == null) return;
    final index = _rows.indexWhere((r) => r.locateIds.contains(id));
    if (index < 0) return;
    for (var attempt = 0; attempt < 8; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final ctx = _rowKeys[id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.12,
          duration: AppMotion.reduce(context) ? Duration.zero : AppMotion.fast,
          curve: AppMotion.out,
        );
        return;
      }
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) continue;
      final estimate = ((index + 0.5) / _rows.length) * max;
      _scroll.jumpTo(estimate.clamp(0.0, max));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(newsProvider.select((s) => s.selectedId), (prev, next) {
      if (next != null && next != prev) _scrollToSelected();
    });
    final palette = widget.palette;
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final ready = ref.watch(newsProvider.select((s) => s.ready));
    final catalog = ref.watch(newsProvider.select((s) => s.catalog));
    final records = ref.watch(newsProvider.select((s) => s.records));
    final statuses = ref.watch(newsProvider.select((s) => s.statuses));
    if (!ready) {
      return Center(child: CircularProgressIndicator(color: palette.primary, strokeWidth: 2));
    }
    if (catalog == null) {
      return RefreshIndicator(
        color: palette.primary,
        onRefresh: () => ref.read(newsProvider.notifier).retryStart(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 280,
              child: EmptyState(
                palette: palette,
                message: l10n.errorNetwork,
                icon: LucideIcons.newspaper,
                action: OutlinedButton(
                  onPressed: () => ref.read(newsProvider.notifier).retryStart(),
                  child: Text(l10n.actionRefresh),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final enabled = ref.read(newsProvider.notifier).enabledSourceIds;
    final order = orderedSourceIds(settings.sourceOrder, catalog);
    final sources = [
      for (final id in order)
        if (catalog.byId(id) != null && enabled.contains(id)) catalog.byId(id)!,
    ];
    final filter = resolveFeedSource(settings.feedFilter, sources.map((s) => s.id));
    final map = {for (final s in catalog.sources) s.id: s};
    final visible = [
      for (final r in records)
        if (enabled.contains(r.item.sourceId) && (filter == 'all' || r.item.sourceId == filter)) r,
    ];
    final unreadIds = {
      for (final r in visible)
        if (!r.read) r.item.id,
    };
    final newSinceMs = settings.newSinceMs == 0
        ? DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch
        : settings.newSinceMs;
    final byId = {for (final r in visible) r.item.id: r};
    final unreadTotal = unreadIds.length;

    final feedItems = [
      for (final r in visible)
        if (!(map[r.item.sourceId]?.board ?? false)) r.item,
    ];
    final boardItems = [
      for (final r in visible)
        if (map[r.item.sourceId]?.board ?? false) r.item,
    ];

    final brief = filter == 'all' ? buildBrief(items: feedItems, unreadIds: unreadIds) : const <BriefStory>[];
    final briefIds = {for (final story in brief) ...story.memberIds};
    final boardSections = buildBySource(
      items: boardItems,
      catalog: map,
      sourceOrder: sources.map((s) => s.id).toList(),
    );
    final feedSections = buildBySource(
      items: [
        for (final item in feedItems)
          if (filter != 'all' || !briefIds.contains(item.id)) item,
      ],
      catalog: map,
      sourceOrder: sources.map((s) => s.id).toList(),
    );

    final rows = <_FeedRow>[];
    if (brief.isNotEmpty) {
      rows.add(
        _FeedRow.header(
          label: l10n.briefTitle,
          unread: brief.where((s) => unreadIds.contains(s.lead.id)).length,
          tightTop: true,
          markAll: unreadTotal > 0,
        ),
      );
      for (final story in brief) {
        final rec = byId[story.lead.id];
        if (rec != null) rows.add(_FeedRow.brief(story, rec));
      }
    }

    void addSections(List<TimelineSection> sections, {required bool hideSource, required bool tightTop, String? wrapLabel}) {
      if (sections.isEmpty) return;
      if (wrapLabel != null) {
        rows.add(_FeedRow.header(label: wrapLabel, tightTop: tightTop));
      }
      for (final section in sections) {
        rows.add(
          _FeedRow.header(
            label: section.title(settings.isZh),
            unread: section.items.where((item) => unreadIds.contains(item.id)).length,
            failed: statuses[section.id]?.status == 'error',
          ),
        );
        for (final item in section.items) {
          final rec = byId[item.id];
          if (rec != null) rows.add(_FeedRow.article(rec, hideSource: hideSource));
        }
      }
    }

    if (filter != 'all') {
      addSections(
        buildBySource(
          items: visible.map((r) => r.item).toList(),
          catalog: map,
          sourceOrder: sources.map((s) => s.id).toList(),
        ),
        hideSource: true,
        tightTop: brief.isEmpty,
      );
    } else {
      addSections(boardSections, hideSource: false, tightTop: brief.isEmpty, wrapLabel: l10n.boardsTitle);
      addSections(
        feedSections,
        hideSource: true,
        tightTop: brief.isEmpty && boardSections.isEmpty,
        wrapLabel: l10n.bySource,
      );
    }

    _rows = rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeedFilterBar(
          palette: palette,
          selectedId: filter,
          sources: sources,
          chinese: settings.isZh,
          caption: unreadTotal > 0 ? l10n.unreadCount(unreadTotal) : (visible.isEmpty ? null : l10n.feedCount(visible.length)),
          onSelected: (next) {
            ref.read(settingsProvider.notifier).update(settings.copyWith(feedFilter: next));
          },
        ),
        Expanded(
          child: RefreshIndicator(
            color: palette.primary,
            onRefresh: () => ref.read(newsProvider.notifier).refresh(),
            child: visible.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 280,
                        child: EmptyState(
                          palette: palette,
                          message: records.where((r) => enabled.contains(r.item.sourceId)).isEmpty
                              ? l10n.emptyToday
                              : l10n.emptyFilter,
                          icon: LucideIcons.newspaper,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: AppTokens.s32),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      final child = _TodayRow(
                        row: row,
                        catalog: catalog,
                        palette: palette,
                        chinese: settings.isZh,
                        newSinceMs: newSinceMs,
                        index: i,
                        onMarkAll: row.markAll
                            ? () => ref.read(newsProvider.notifier).markVisibleRead(visible.map((r) => r.item.id))
                            : null,
                      );
                      if (row.locateIds.isEmpty) return child;
                      return KeyedSubtree(key: _keyForRow(row), child: child);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _TodayRow extends ConsumerWidget {
  const _TodayRow({
    required this.row,
    required this.catalog,
    required this.palette,
    required this.chinese,
    required this.newSinceMs,
    required this.index,
    this.onMarkAll,
  });

  final _FeedRow row;
  final SourceCatalog catalog;
  final AppPalette palette;
  final bool chinese;
  final int newSinceMs;
  final int index;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (row.kind == _RowKind.header) {
      return SectionHeader(
        label: row.label,
        palette: palette,
        tightTop: row.tightTop,
        unread: row.unread,
        failed: row.failed,
        actionLabel: row.markAll ? l10n.markAllRead : null,
        onAction: onMarkAll,
      );
    }
    final id = row.record!.item.id;
    final selected = ref.watch(newsProvider.select((s) {
      final sid = s.selectedId;
      if (sid == null) return false;
      if (sid == id) return true;
      return row.story?.memberIds.contains(sid) ?? false;
    }));
    final isNew = (row.record!.item.pubDate?.millisecondsSinceEpoch ?? 0) > newSinceMs;
    final widget = row.kind == _RowKind.brief
        ? BriefStoryCard(
            record: row.record!,
            story: row.story!,
            catalog: catalog,
            palette: palette,
            chinese: chinese,
            selected: selected,
            isNew: isNew,
            onTap: () => OpenArticleScope.of(context)(id),
          )
        : ArticleTile(
            record: row.record!,
            catalog: catalog,
            palette: palette,
            chinese: chinese,
            selected: selected,
            hideSource: row.hideSource,
            isNew: isNew,
            onTap: () => OpenArticleScope.of(context)(id),
          );
    if (index < 14) return StaggerIn(index: index, child: widget);
    return widget;
  }
}
