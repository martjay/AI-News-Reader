import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

Future<void> openOriginal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return;
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!ok) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e, st) {
    debugPrint('openOriginal failed: $e\n$st');
  }
}

Future<void> shareStory(BuildContext context, {required String title, required String url}) async {
  final text = '${title.trim()}\n${url.trim()}';
  try {
    await SharePlus.instance.share(ShareParams(text: text, subject: title.trim()));
    return;
  } catch (e, st) {
    debugPrint('shareStory failed, copying instead: $e\n$st');
  }
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).shareCopied), duration: const Duration(seconds: 2)),
  );
}

Future<void> copyArticle(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmation,
}) async {
  final cleanedTitle = title.trim();
  final cleanedBody = body.trim();
  final text = cleanedBody.isEmpty ? cleanedTitle : '$cleanedTitle\n\n$cleanedBody';
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(confirmation ?? l10n.articleCopied), duration: const Duration(seconds: 2)),
  );
}
