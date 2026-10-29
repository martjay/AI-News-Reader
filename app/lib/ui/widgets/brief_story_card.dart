import 'package:flutter/material.dart';
import 'package:news_core/news_core.dart';

import '../../core/article_record.dart';
import '../../core/relative_time.dart';
import '../../l10n/app_localizations.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

class BriefStoryCard extends StatefulWidget {
  const BriefStoryCard({
    super.key,
    required this.record,
    required this.story,
    required this.catalog,
    required this.palette,
    required this.chinese,
    required this.selected,
    required this.isNew,
    required this.onTap,
  });

  final ArticleRecord record;
  final BriefStory story;
  final SourceCatalog catalog;
  final AppPalette palette;
  final bool chinese;
  final bool selected;
  final bool isNew;
  final VoidCallback onTap;

  @override
  State<BriefStoryCard> createState() => _BriefStoryCardState();
}

class _BriefStoryCardState extends State<BriefStoryCard> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = widget.palette;
    final rec = widget.record;
    final names = widget.story.sourceIds
        .map(widget.catalog.byId)
        .whereType<SourceDef>()
        .map((s) => s.displayName(widget.chinese))
        .toList();
    return PressSurface(
      onTap: widget.onTap,
      selected: widget.selected,
      selectedColor: palette.bgMuted,
      hoverColor: palette.bgElevated,
      color: palette.bg,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      margin: const EdgeInsets.fromLTRB(AppTokens.s12, 0, AppTokens.s12, AppTokens.s8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s16, AppTokens.s16, AppTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      names.isEmpty
                          ? rec.item.sourceId
                          : names.take(3).join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.kicker(palette.fgMuted),
                    ),
                  ),
                  if (widget.story.crossSource)
                    Text(
                      l10n.relatedSources(widget.story.sourceIds.length),
                      style: AppType.meta(palette.fgMuted),
                    ),
                ],
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                rec.displayTitle(widget.chinese),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppType.listTitle(
                  color: rec.read ? palette.fgMuted : palette.fg,
                  read: rec.read,
                ).copyWith(fontSize: 16, height: 1.38),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                [
                  relativeTime(context, rec.item.pubDate),
                  if (widget.isNew) l10n.newBadge,
                ].join('  ·  '),
                style: AppType.meta(palette.fgMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
