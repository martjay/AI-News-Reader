import 'package:flutter/material.dart';
import 'package:news_core/news_core.dart';

import '../../core/article_record.dart';
import '../../core/relative_time.dart';
import '../../l10n/app_localizations.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

class ArticleTile extends StatefulWidget {
  const ArticleTile({
    super.key,
    required this.record,
    required this.catalog,
    required this.palette,
    required this.chinese,
    required this.selected,
    required this.onTap,
    this.hideSource = false,
    this.isNew = false,
  });

  final ArticleRecord record;
  final SourceCatalog catalog;
  final AppPalette palette;
  final bool chinese;
  final bool selected;
  final bool hideSource;
  final bool isNew;
  final VoidCallback onTap;

  @override
  State<ArticleTile> createState() => _ArticleTileState();
}

class _ArticleTileState extends State<ArticleTile> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = widget.record.item;
    final palette = widget.palette;
    final source = widget.catalog.byId(item.sourceId);
    final extras = item.extraSourceIds
        .map(widget.catalog.byId)
        .whereType<SourceDef>()
        .map((s) => s.displayName(widget.chinese))
        .toList();
    final sourceLabel = widget.hideSource
        ? extras.join(' · ')
        : [
            source?.displayName(widget.chinese) ?? item.sourceId,
            ...extras,
          ].join(' · ');
    final selected = widget.selected;
    final read = widget.record.read;

    return PressSurface(
      onTap: widget.onTap,
      selected: selected,
      selectedColor: palette.bgMuted,
      hoverColor: palette.bgMuted,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s12, AppTokens.s16, AppTokens.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: read ? Colors.transparent : palette.primary,
                      border: Border.all(color: read ? palette.border : palette.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.record.displayTitle(widget.chinese),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.listTitle(
                          color: read ? palette.fgMuted : palette.fg,
                          read: read,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Text(
                        [
                          sourceLabel,
                          relativeTime(context, item.pubDate),
                          if (widget.isNew) l10n.newBadge,
                        ].where((e) => e.isNotEmpty).join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.meta(palette.fgMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: AppMotion.micro,
                opacity: selected ? 1 : 0,
                child: ColoredBox(color: palette.primary, child: const SizedBox(width: 2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
