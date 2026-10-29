import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

String relativeTime(BuildContext context, DateTime? when) {
  final l10n = AppLocalizations.of(context);
  if (when == null) return '';
  final delta = DateTime.now().difference(when);
  if (delta.inMinutes < 1) return l10n.relativeJustNow;
  if (delta.inHours < 1) return l10n.relativeMinutes(delta.inMinutes);
  if (delta.inHours < 24) return l10n.relativeHours(delta.inHours);
  return l10n.relativeDays(delta.inDays);
}
