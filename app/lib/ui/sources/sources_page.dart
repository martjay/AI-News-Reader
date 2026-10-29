import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:news_core/news_core.dart';

import '../../core/feed_filter.dart';
import '../../core/news_controller.dart';
import '../../core/relative_time.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/empty_state.dart';

class SourcesPage extends ConsumerWidget {
  const SourcesPage({super.key, required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final news = ref.watch(newsProvider);
    final settings = ref.watch(settingsProvider);
    final catalog = news.catalog;
    if (!news.ready) {
      return Center(child: CircularProgressIndicator(color: palette.primary, strokeWidth: 2));
    }
    if (catalog == null) {
      return EmptyState(
        palette: palette,
        message: l10n.errorNetwork,
        icon: LucideIcons.rss,
        action: OutlinedButton(
          onPressed: () => ref.read(newsProvider.notifier).retryStart(),
          child: Text(l10n.actionRefresh),
        ),
      );
    }
    final ordered = [
      for (final id in orderedSourceIds(settings.sourceOrder, catalog))
        if (catalog.byId(id) != null) catalog.byId(id)!,
    ];

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: AppTokens.s8, bottom: AppTokens.s32),
      buildDefaultDragHandles: false,
      itemCount: ordered.length + 1,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex == 0 || newIndex == 0) return;
        final from = oldIndex - 1;
        var to = newIndex - 1;
        final next = [...ordered];
        final item = next.removeAt(from);
        if (to > from) to -= 1;
        next.insert(to, item);
        ref.read(settingsProvider.notifier).update(
              settings.copyWith(sourceOrder: next.map((s) => s.id).toList()),
            );
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            key: const ValueKey('hint'),
            padding: const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s8, AppTokens.s16, AppTokens.s12),
            child: Text(l10n.sourcesReorderHint, style: AppType.meta(palette.fgMuted)),
          );
        }
        final source = ordered[index - 1];
        return _SourceRow(
          key: ValueKey(source.id),
          index: index,
          source: source,
          palette: palette,
          enabled: resolveEnabledSourceIds(
            enabledSources: settings.enabledSources,
            seenSourceIds: settings.seenSourceIds,
            catalogEnabledIds: catalog.enabled.map((s) => s.id),
          ).contains(source.id),
          failed: news.statuses[source.id]?.status == 'error',
          unread: news.records.where((r) => r.item.sourceId == source.id && !r.read).length,
          updated: news.statuses[source.id]?.updatedAt,
          chinese: settings.isZh,
          onTap: () => context.push('/sources/${source.id}'),
          onEnabled: (on) => ref.read(newsProvider.notifier).setSourceEnabled(source.id, on),
        );
      },
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    super.key,
    required this.index,
    required this.source,
    required this.palette,
    required this.enabled,
    required this.failed,
    required this.unread,
    required this.updated,
    required this.chinese,
    required this.onTap,
    required this.onEnabled,
  });

  final int index;
  final SourceDef source;
  final AppPalette palette;
  final bool enabled;
  final bool failed;
  final int unread;
  final DateTime? updated;
  final bool chinese;
  final VoidCallback onTap;
  final ValueChanged<bool> onEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.s8),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(left: AppTokens.s8),
              child: Icon(LucideIcons.gripVertical, size: 16, color: palette.fgMuted),
            ),
          ),
          Expanded(
            child: HoverLift(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppTokens.s8, AppTokens.s12, AppTokens.s8, AppTokens.s12),
                child: Row(
                  children: [
                    Icon(
                      source.board ? LucideIcons.flame : LucideIcons.rss,
                      size: 18,
                      color: enabled ? palette.primary : palette.fgMuted,
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.displayName(chinese),
                            style: TextStyle(color: palette.fg, fontSize: AppTokens.body, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppTokens.s4),
                          Text(
                            [
                              source.board ? l10n.boardsTitle : (source.access == SourceAccess.direct ? 'RSS' : 'snapshot'),
                              if (source.fragile) l10n.sourceFragile,
                              if (failed) l10n.sourceFailed else l10n.sourceOk,
                              if (unread > 0) l10n.unreadCount(unread),
                              relativeTime(context, updated),
                            ].where((e) => e.isNotEmpty).join('  ·  '),
                            style: AppType.meta(failed ? palette.danger : palette.fgMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 16, color: palette.fgMuted),
                  ],
                ),
              ),
            ),
          ),
          Switch(
            value: enabled,
            activeThumbColor: palette.primaryFg,
            activeTrackColor: palette.primary,
            onChanged: onEnabled,
          ),
        ],
      ),
    );
  }
}
