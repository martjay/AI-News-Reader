import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/feed_filter.dart';
import '../../core/news_controller.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../shell/adaptive_shell.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/article_tile.dart';
import '../widgets/empty_state.dart';

class SourceDetailPage extends ConsumerWidget {
  const SourceDetailPage({
    super.key,
    required this.sourceId,
    required this.palette,
  });

  final String sourceId;
  final AppPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final news = ref.watch(newsProvider);
    final settings = ref.watch(settingsProvider);
    final catalog = news.catalog;
    final source = catalog?.byId(sourceId);
    final items = news.records.where((r) => r.item.sourceId == sourceId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTokens.s8, AppTokens.s8, AppTokens.s16, AppTokens.s8),
          child: Row(
            children: [
              GhostIconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: LucideIcons.chevronLeft,
                color: palette.fgMuted,
                hoverColor: palette.accent,
              ),
              Expanded(
                child: Text(
                  source?.displayName(settings.isZh) ?? sourceId,
                  style: TextStyle(color: palette.fg, fontSize: AppTokens.section, fontWeight: FontWeight.w600),
                ),
              ),
              if (source != null)
                Switch(
                  value: resolveEnabledSourceIds(
                    enabledSources: settings.enabledSources,
                    seenSourceIds: settings.seenSourceIds,
                    catalogEnabledIds: [...?catalog?.enabled.map((s) => s.id)],
                  ).contains(source.id),
                  activeThumbColor: palette.primaryFg,
                  activeTrackColor: palette.primary,
                  onChanged: (on) => ref.read(newsProvider.notifier).setSourceEnabled(source.id, on),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: palette.border),
        Expanded(
          child: items.isEmpty
              ? EmptyState(palette: palette, message: l10n.emptySource, icon: LucideIcons.rss)
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final rec = items[i];
                    return ArticleTile(
                      record: rec,
                      catalog: catalog!,
                      palette: palette,
                      chinese: settings.isZh,
                      selected: news.selectedId == rec.item.id,
                      onTap: () => OpenArticleScope.of(context)(rec.item.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
