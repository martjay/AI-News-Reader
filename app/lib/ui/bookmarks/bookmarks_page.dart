import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/news_controller.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../shell/adaptive_shell.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/article_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key, required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final news = ref.watch(newsProvider);
    final settings = ref.watch(settingsProvider);
    final catalog = news.catalog;
    final saved = news.records.where((r) => r.saved).toList();
    if (!news.ready) {
      return Center(child: CircularProgressIndicator(color: palette.primary, strokeWidth: 2));
    }
    if (catalog == null) {
      return EmptyState(
        palette: palette,
        message: l10n.errorNetwork,
        icon: LucideIcons.bookmark,
        action: OutlinedButton(
          onPressed: () => ref.read(newsProvider.notifier).retryStart(),
          child: Text(l10n.actionRefresh),
        ),
      );
    }
    if (saved.isEmpty) {
      return EmptyState(palette: palette, message: l10n.emptySaved, icon: LucideIcons.bookmark);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppTokens.s32, top: AppTokens.s8),
      itemCount: saved.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return SectionHeader(label: l10n.navSaved, palette: palette);
        }
        final rec = saved[i - 1];
        return StaggerIn(
          index: i - 1,
          child: ArticleTile(
            record: rec,
            catalog: catalog,
            palette: palette,
            chinese: settings.isZh,
            selected: news.selectedId == rec.item.id,
            onTap: () => OpenArticleScope.of(context)(rec.item.id),
          ),
        );
      },
    );
  }
}
