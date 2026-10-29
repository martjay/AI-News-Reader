import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/news_controller.dart';
import '../../core/search_query.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../shell/adaptive_shell.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/article_tile.dart';
import '../widgets/empty_state.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, required this.palette});

  final AppPalette palette;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final news = ref.watch(newsProvider);
    final settings = ref.watch(settingsProvider);
    final catalog = news.catalog;
    final q = _query.trim();
    final hits = searchArticles(
      records: news.records,
      enabledSourceIds: ref.read(newsProvider.notifier).enabledSourceIds,
      query: q,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTokens.s8, AppTokens.s12, AppTokens.s16, AppTokens.s8),
          child: Row(
            children: [
              GhostIconButton(
                tooltip: l10n.cancel,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: LucideIcons.chevronLeft,
                color: widget.palette.fgMuted,
                hoverColor: widget.palette.accent,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  style: TextStyle(color: widget.palette.inputFg, fontSize: AppTokens.body),
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: Icon(LucideIcons.search, size: 18, color: widget.palette.fgMuted),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                              _focus.requestFocus();
                            },
                            icon: Icon(LucideIcons.x, size: 16, color: widget.palette.fgMuted),
                          ),
                  ),
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 160), () {
                      if (mounted) setState(() => _query = v);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: catalog == null || q.isEmpty
              ? EmptyState(palette: widget.palette, message: l10n.searchHint, icon: LucideIcons.search)
              : hits.isEmpty
                  ? EmptyState(palette: widget.palette, message: l10n.emptySearch, icon: LucideIcons.search)
                  : ListView.builder(
                      itemCount: hits.length,
                      itemBuilder: (context, i) {
                        final rec = hits[i];
                        return StaggerIn(
                          index: i,
                          child: ArticleTile(
                            record: rec,
                            catalog: catalog,
                            palette: widget.palette,
                            chinese: settings.isZh,
                            selected: news.selectedId == rec.item.id,
                            onTap: () => OpenArticleScope.of(context)(rec.item.id),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
