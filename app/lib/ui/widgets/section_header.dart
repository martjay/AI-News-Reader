import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    required this.palette,
    this.tightTop = false,
    this.count,
    this.unread,
    this.failed = false,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final AppPalette palette;
  final bool tightTop;
  final int? count;
  final int? unread;
  final bool failed;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s16,
        tightTop ? AppTokens.s16 : AppTokens.s28,
        AppTokens.s12,
        AppTokens.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.section(palette.fgMuted),
            ),
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(left: AppTokens.s8),
              child: Text(l10n.sourceFailed, style: AppType.meta(palette.danger)),
            ),
          if (unread != null && unread! > 0)
            Padding(
              padding: const EdgeInsets.only(left: AppTokens.s8),
              child: Text(l10n.unreadCount(unread!), style: AppType.meta(palette.fgMuted)),
            )
          else if (count != null)
            Padding(
              padding: const EdgeInsets.only(left: AppTokens.s8),
              child: Text('$count', style: AppType.meta(palette.fgMuted)),
            ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: AppType.meta(palette.fgMuted)),
            ),
        ],
      ),
    );
  }
}
