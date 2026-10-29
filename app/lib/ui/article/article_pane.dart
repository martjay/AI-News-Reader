import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:news_core/news_core.dart';

import '../../core/article_record.dart';
import '../../core/body_fetch.dart';
import '../../core/relative_time.dart';
import '../../core/settings.dart';
import '../../core/tts_controller.dart';
import '../../core/tts_voices.dart';
import '../../l10n/app_localizations.dart';
import '../../services/open_link.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/paper_grain.dart';
import '../widgets/tts_player_bar.dart';

class ArticlePane extends StatelessWidget {
  const ArticlePane({
    super.key,
    required this.record,
    required this.catalog,
    required this.palette,
    required this.settings,
    required this.onToggleSaved,
    required this.onClose,
    this.onFetchBody,
    this.onTranslate,
    this.loadingBody = false,
    this.translatingBody = false,
    this.translateFailed = false,
  });

  final ArticleRecord? record;
  final SourceCatalog? catalog;
  final AppPalette palette;
  final AppSettings settings;
  final VoidCallback? onToggleSaved;
  final VoidCallback? onClose;
  final VoidCallback? onFetchBody;
  final VoidCallback? onTranslate;
  final bool loadingBody;
  final bool translatingBody;
  final bool translateFailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: palette.bgElevated,
      child: Stack(
        children: [
          PaperGrain(color: palette.fg),
          AnimatedSwitcher(
            duration: AppMotion.pane,
            switchInCurve: AppMotion.out,
            switchOutCurve: AppMotion.out,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, animation) {
              if (AppMotion.reduce(context)) return child;
              return AppMotion.fadeSlide(animation: animation, child: child);
            },
            child: record == null || catalog == null
                ? EmptyState(key: const ValueKey('empty'), palette: palette, message: l10n.emptyArticle, icon: LucideIcons.panelRight)
                : _ReaderBody(
                    key: ValueKey(record!.item.id),
                    rec: record!,
                    catalog: catalog!,
                    palette: palette,
                    settings: settings,
                    loadingBody: loadingBody,
                    translatingBody: translatingBody,
                    translateFailed: translateFailed,
                    onToggleSaved: onToggleSaved,
                    onClose: onClose,
                    onFetchBody: onFetchBody,
                    onTranslate: onTranslate,
                  ),
          ),
          if (record != null)
            Positioned(
              left: AppTokens.s12,
              right: AppTokens.s12,
              bottom: AppTokens.s12,
              child: TtsPlayerBar(palette: palette, articleId: record!.item.id),
            ),
        ],
      ),
    );
  }
}

class _ReaderBody extends ConsumerStatefulWidget {
  const _ReaderBody({
    super.key,
    required this.rec,
    required this.catalog,
    required this.palette,
    required this.settings,
    required this.loadingBody,
    required this.translatingBody,
    required this.translateFailed,
    required this.onToggleSaved,
    required this.onClose,
    required this.onFetchBody,
    required this.onTranslate,
  });

  final ArticleRecord rec;
  final SourceCatalog catalog;
  final AppPalette palette;
  final AppSettings settings;
  final bool loadingBody;
  final bool translatingBody;
  final bool translateFailed;
  final VoidCallback? onToggleSaved;
  final VoidCallback? onClose;
  final VoidCallback? onFetchBody;
  final VoidCallback? onTranslate;

  @override
  ConsumerState<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends ConsumerState<_ReaderBody> {
  final _titleKey = GlobalKey();
  final _paraKeys = <GlobalKey>[];
  bool _preferSummary = false;

  @override
  void didUpdateWidget(covariant _ReaderBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rec.item.id != widget.rec.item.id) {
      _preferSummary = false;
    } else if (oldWidget.loadingBody && !widget.loadingBody && widget.rec.bodyStatus.isNotEmpty) {
      _preferSummary = false;
    }
  }

  void _ensureParaKeys(int count) {
    if (_paraKeys.length == count) return;
    _paraKeys
      ..clear()
      ..addAll(List.generate(count, (_) => GlobalKey()));
  }

  void _scrollSpokenIntoView(TtsState tts, String title, List<String> paragraphs) {
    if (tts.articleId != widget.rec.item.id || !tts.active) return;
    BuildContext? target;
    if (tts.speaksText(title)) {
      target = _titleKey.currentContext;
    } else {
      for (var i = 0; i < paragraphs.length && i < _paraKeys.length; i++) {
        if (tts.speaksText(paragraphs[i])) {
          target = _paraKeys[i].currentContext;
          break;
        }
      }
    }
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.18,
      duration: AppMotion.reduce(context) ? Duration.zero : AppMotion.fast,
      curve: AppMotion.out,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rec = widget.rec;
    final catalog = widget.catalog;
    final palette = widget.palette;
    final settings = widget.settings;
    final loadingBody = widget.loadingBody;
    final translatingBody = widget.translatingBody;
    final translateFailed = widget.translateFailed;
    final tts = ref.watch(ttsProvider);
    final speechFailed = tts.articleId == rec.item.id &&
        (tts.error == TtsError.network || tts.error == TtsError.saveFailed);
    final onToggleSaved = widget.onToggleSaved;
    final onClose = widget.onClose;
    final onFetchBody = widget.onFetchBody;
    final onTranslate = widget.onTranslate;
    final item = rec.item;
    final source = catalog.byId(item.sourceId);
    final extras = item.extraSourceIds
        .map(catalog.byId)
        .whereType<SourceDef>()
        .map((s) => s.displayName(settings.isZh))
        .toList();
    final kicker = [
      source?.displayName(settings.isZh) ?? item.sourceId,
      ...extras,
      relativeTime(context, item.pubDate),
    ].where((e) => e.isNotEmpty).join('  ·  ');
    final hasFullText = hasUsableFullBody(rec.body, rec.bodyStatus);
    final fetched = rec.bodyStatus.isNotEmpty;
    final showingSummary = _preferSummary || !hasFullText;
    final originalBody = hasFullText && !showingSummary ? rec.body.trim() : '';
    final translatedBody = hasFullText && !showingSummary ? rec.bodyZh.trim() : '';
    final showBilingual = settings.isZh &&
        translatedBody.isNotEmpty &&
        originalBody.isNotEmpty &&
        translatedBody != originalBody;
    final body = showBilingual
        ? translatedBody
        : (!showingSummary ? rec.displayBody(settings.isZh).trim() : '');
    final summaryText = rec.bodyStatus == 'excerpt' && rec.body.trim().isNotEmpty
        ? rec.displayBody(settings.isZh).trim()
        : plaintextFromHtml(rec.displaySummary(settings.isZh), url: item.url).trim();
    final fallback = showingSummary ? summaryText : plaintextFromHtml(rec.displaySummary(settings.isZh), url: item.url).trim();
    final paragraphs = splitReaderParagraphs(body.isNotEmpty ? body : fallback);
    final originalParas = showBilingual ? splitReaderParagraphs(originalBody) : const <String>[];
    final busy = loadingBody || translatingBody;
    final weak = !busy && isWeakBodyStatus(rec.bodyStatus);
    final spokenHere = tts.active && tts.articleId == rec.item.id;
    final spokenTitle = spokenHere &&
        (tts.speaksText(rec.displayTitle(settings.isZh)) ||
            tts.speaksText(item.title) ||
            (rec.titleZh.trim().isNotEmpty && tts.speaksText(rec.titleZh)));
    _ensureParaKeys(paragraphs.length);
    ref.listen(ttsProvider, (prev, next) {
      if (next.articleId != rec.item.id) return;
      if (prev?.partFrom == next.partFrom && prev?.partTo == next.partTo && prev?.articleId == next.articleId) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollSpokenIntoView(next, rec.displayTitle(settings.isZh), paragraphs);
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTokens.s8, AppTokens.s8, AppTokens.s8, AppTokens.s8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.bgElevated,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                GhostIconButton(
                  tooltip: l10n.actionOpenOriginal,
                  onPressed: () => openOriginal(item.url),
                  icon: LucideIcons.externalLink,
                  color: palette.fgMuted,
                  hoverColor: palette.accent,
                ),
                GhostIconButton(
                  tooltip: rec.saved ? l10n.actionUnsave : l10n.actionSave,
                  onPressed: onToggleSaved,
                  icon: LucideIcons.bookmark,
                  color: palette.fgMuted,
                  hoverColor: palette.accent,
                  active: rec.saved,
                  activeColor: palette.primary,
                ),
                GhostIconButton(
                  tooltip: l10n.actionShare,
                  onPressed: () => shareStory(
                    context,
                    title: rec.displayTitle(settings.isZh),
                    url: item.url,
                  ),
                  icon: LucideIcons.share2,
                  color: palette.fgMuted,
                  hoverColor: palette.accent,
                ),
                const Spacer(),
                if (onClose != null)
                  GhostIconButton(
                    onPressed: onClose,
                    icon: LucideIcons.x,
                    color: palette.fgMuted,
                    hoverColor: palette.accent,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppTokens.s32,
                AppTokens.s24,
                AppTokens.s32,
                spokenHere ? 132 : AppTokens.s48,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTokens.measure),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(kicker, style: AppType.kicker(palette.fgMuted)),
                    const SizedBox(height: AppTokens.s12),
                    spokenTitle
                        ? _SpokenPassage(
                            key: _titleKey,
                            palette: palette,
                            child: Text(
                              rec.displayTitle(settings.isZh),
                              style: AppType.display(palette.fg),
                            ),
                          )
                        : KeyedSubtree(
                            key: _titleKey,
                            child: Text(
                              rec.displayTitle(settings.isZh),
                              style: AppType.display(palette.fg),
                            ),
                          ),
                    if (settings.isZh && rec.titleZh.isNotEmpty && rec.titleZh != item.title) ...[
                      const SizedBox(height: AppTokens.s8),
                      Text(item.title, style: AppType.dek(palette.fgMuted)),
                    ],
                    const SizedBox(height: AppTokens.s20),
                    Container(width: 32, height: 1, color: palette.border),
                    const SizedBox(height: AppTokens.s16),
                    SelectionContainer.disabled(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              style: _readerActionStyle(palette),
                              onPressed: busy
                                  ? null
                                  : () {
                                      if (fetched && _preferSummary && rec.body.trim().isNotEmpty) {
                                        setState(() => _preferSummary = false);
                                        return;
                                      }
                                      onFetchBody?.call();
                                    },
                              icon: const Icon(LucideIcons.fileText, size: 16),
                              label: Text(
                                hasFullText && _preferSummary
                                    ? l10n.showFullText
                                    : (fetched ? l10n.refetchFullText : l10n.fetchFullText),
                              ),
                            ),
                            if (!showingSummary) ...[
                              const SizedBox(width: AppTokens.s8),
                              OutlinedButton.icon(
                                style: _readerActionStyle(palette),
                                onPressed: busy ? null : () => setState(() => _preferSummary = true),
                                icon: const Icon(LucideIcons.alignLeft, size: 16),
                                label: Text(l10n.showSummary),
                              ),
                            ],
                            const SizedBox(width: AppTokens.s8),
                            OutlinedButton.icon(
                              style: _readerActionStyle(palette),
                              onPressed: busy ? null : onTranslate,
                              icon: const Icon(LucideIcons.languages, size: 16),
                              label: Text(translatingBody ? l10n.translatingArticle : l10n.translateArticle),
                            ),
                            const SizedBox(width: AppTokens.s8),
                            _CopyArticleButton(
                              palette: palette,
                              hasTranslation: rec.titleZh.trim().isNotEmpty || translatedBody.isNotEmpty,
                              titleZh: rec.titleZh.trim().isNotEmpty ? rec.titleZh.trim() : rec.displayTitle(settings.isZh),
                              titleOriginal: item.title.trim(),
                              bodyZh: translatedBody.isNotEmpty ? translatedBody : paragraphs.join('\n\n'),
                              bodyOriginal: originalBody.isNotEmpty ? originalBody : fallback,
                              originalLabel: l10n.originalBody,
                            ),
                            const SizedBox(width: AppTokens.s8),
                            _ListenArticleButton(
                              palette: palette,
                              articleId: rec.item.id,
                              text: speechTextFor(rec),
                            ),
                            const SizedBox(width: AppTokens.s8),
                            _DownloadSpeechButton(
                              palette: palette,
                              articleId: rec.item.id,
                              text: speechTextFor(rec),
                              title: rec.displayTitle(settings.isZh),
                            ),
                            const SizedBox(width: AppTokens.s8),
                            _TtsVoiceButton(
                              palette: palette,
                              chineseUi: settings.isZh,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s20),
                    if (loadingBody)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTokens.s16),
                        child: Text(l10n.readingBody, style: AppType.meta(palette.fgMuted)),
                      ),
                    if (translatingBody)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTokens.s16),
                        child: Text(l10n.translatingArticle, style: AppType.meta(palette.fgMuted)),
                      ),
                    if (!translatingBody && translateFailed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTokens.s16),
                        child: Text(l10n.errorTranslate, style: AppType.meta(palette.danger)),
                      ),
                    if (speechFailed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTokens.s16),
                        child: Text(
                          tts.error == TtsError.saveFailed ? l10n.audioSaveFailed : l10n.listenFailed,
                          style: AppType.meta(palette.danger),
                        ),
                      ),
                    if (weak)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTokens.s16),
                        child: Text(
                          switch (rec.bodyStatus) {
                            'fail' => l10n.bodyFetchFailed,
                            'excerpt' => l10n.bodyExcerptOnly,
                            _ => l10n.bodyUnavailable,
                          },
                          style: AppType.meta(palette.warning),
                        ),
                      ),
                    if (paragraphs.isEmpty && !loadingBody)
                      Text(l10n.noExcerpt, style: AppType.dek(palette.fgMuted))
                    else
                      ..._spokenBody(
                        palette: palette,
                        paragraphs: paragraphs,
                        originalParas: originalParas,
                        showBilingual: showBilingual,
                        spokenHere: spokenHere,
                        tts: tts,
                        articleUrl: item.url,
                      ),
                    const SizedBox(height: AppTokens.s8),
                    SelectionContainer.disabled(
                      child: TextButton(
                        onPressed: () => openOriginal(item.url),
                        child: Text(l10n.openInBrowser),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _paragraph(String text, TextStyle style, AppPalette palette, String articleUrl) {
    final url = readerImageUrl(text);
    if (url == null) return Text(text, style: style);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          headers: {
            'User-Agent': FetchClient.userAgent,
            'Referer': articleUrl,
            'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
          },
          errorBuilder: (context, error, stack) {
            return Material(
              color: palette.bgMuted,
              child: InkWell(
                onTap: () => openOriginal(articleUrl),
                child: SizedBox(
                  height: 96,
                  child: Center(
                    child: Text(l10n.imageLoadFailed, style: AppType.meta(palette.fgMuted)),
                  ),
                ),
              ),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: palette.fgMuted)),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _spokenBody({
    required AppPalette palette,
    required List<String> paragraphs,
    required List<String> originalParas,
    required bool showBilingual,
    required bool spokenHere,
    required TtsState tts,
    required String articleUrl,
  }) {
    final count = showBilingual
        ? (paragraphs.length > originalParas.length ? paragraphs.length : originalParas.length)
        : paragraphs.length;
    final spoken = [
      for (var i = 0; i < count; i++) spokenHere && i < paragraphs.length && tts.speaksText(paragraphs[i]),
    ];

    Widget unit(int i) {
      return KeyedSubtree(
        key: i < paragraphs.length && i < _paraKeys.length ? _paraKeys[i] : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (i < paragraphs.length)
              _paragraph(paragraphs[i], AppType.readerBody(palette.fg), palette, articleUrl),
            if (showBilingual &&
                i < originalParas.length &&
                (i >= paragraphs.length || originalParas[i] != paragraphs[i])) ...[
              if (i < paragraphs.length) const SizedBox(height: AppTokens.s8),
              _paragraph(
                originalParas[i],
                i < paragraphs.length ? AppType.dek(palette.fgMuted) : AppType.readerBody(palette.fg),
                palette,
                articleUrl,
              ),
            ],
          ],
        ),
      );
    }

    final out = <Widget>[];
    var i = 0;
    while (i < count) {
      if (!spoken[i]) {
        out.add(unit(i));
        out.add(const SizedBox(height: AppTokens.s16));
        i++;
        continue;
      }
      final start = i;
      i++;
      while (i < count && spoken[i]) {
        i++;
      }
      out.add(
        _SpokenPassage(
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = start; j < i; j++) ...[
                if (j > start) const SizedBox(height: AppTokens.s16),
                unit(j),
              ],
            ],
          ),
        ),
      );
      out.add(const SizedBox(height: AppTokens.s16));
    }
    return out;
  }
}

class _SpokenPassage extends StatelessWidget {
  const _SpokenPassage({
    super.key,
    required this.palette,
    required this.child,
  });

  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wash = Color.lerp(palette.bgElevated, palette.primary, 0.06)!;
    return AnimatedContainer(
      duration: AppMotion.reduce(context) ? Duration.zero : AppMotion.fast,
      curve: AppMotion.out,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: child,
    );
  }
}

class _CopyArticleButton extends StatelessWidget {
  const _CopyArticleButton({
    required this.palette,
    required this.hasTranslation,
    required this.titleZh,
    required this.titleOriginal,
    required this.bodyZh,
    required this.bodyOriginal,
    required this.originalLabel,
  });

  final AppPalette palette;
  final bool hasTranslation;
  final String titleZh;
  final String titleOriginal;
  final String bodyZh;
  final String bodyOriginal;
  final String originalLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: _readerMenuStyle(palette),
      builder: (context, controller, child) {
        return OutlinedButton.icon(
          style: _readerActionStyle(palette),
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(LucideIcons.copy, size: 16),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.copyArticle),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronDown, size: 14),
            ],
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          style: _menuItemStyle(palette),
          onPressed: hasTranslation
              ? () => copyArticle(
                    context,
                    title: titleZh,
                    body: bodyZh,
                    confirmation: l10n.translationCopied,
                  )
              : null,
          child: Text(l10n.copyTranslation, style: TextStyle(color: hasTranslation ? palette.menuFg : palette.fgMuted)),
        ),
        MenuItemButton(
          style: _menuItemStyle(palette),
          onPressed: () => copyArticle(
            context,
            title: titleOriginal,
            body: bodyOriginal,
            confirmation: l10n.originalCopied,
          ),
          child: Text(l10n.copyOriginalText, style: TextStyle(color: palette.menuFg)),
        ),
        MenuItemButton(
          style: _menuItemStyle(palette),
          onPressed: hasTranslation
              ? () => copyArticle(
                    context,
                    title: titleZh,
                    body: [
                      bodyZh,
                      '',
                      originalLabel,
                      titleOriginal,
                      '',
                      bodyOriginal,
                    ].join('\n'),
                    confirmation: l10n.bilingualCopied,
                  )
              : null,
          child: Text(l10n.copyBilingual, style: TextStyle(color: hasTranslation ? palette.menuFg : palette.fgMuted)),
        ),
      ],
    );
  }
}

class _ListenArticleButton extends ConsumerWidget {
  const _ListenArticleButton({
    required this.palette,
    required this.articleId,
    required this.text,
  });

  final AppPalette palette;
  final String articleId;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final tts = ref.watch(ttsProvider);
    final selected = voiceById(settings.ttsVoice);
    final mine = tts.articleId == articleId;
    ref.listen(ttsProvider, (prev, next) {
      if (next.articleId != articleId || next.error == prev?.error) return;
      final message = switch (next.error) {
        TtsError.empty => l10n.nothingToListen,
        TtsError.network => l10n.listenFailed,
        _ => null,
      };
      if (message == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
    });
    final loading = mine && tts.status == TtsStatus.loading;
    final playing = mine && (tts.status == TtsStatus.playing || tts.status == TtsStatus.paused);
    return OutlinedButton.icon(
      style: _readerActionStyle(palette),
      onPressed: loading
          ? null
          : () => ref.read(ttsProvider.notifier).toggle(
                articleId: articleId,
                text: text,
                voice: selected.id,
              ),
      icon: Icon(
        playing ? LucideIcons.square : LucideIcons.volume2,
        size: 16,
      ),
      label: Text(loading ? l10n.preparingSpeech : (playing ? l10n.stopListening : l10n.listenArticle)),
    );
  }
}

class _DownloadSpeechButton extends ConsumerWidget {
  const _DownloadSpeechButton({
    required this.palette,
    required this.articleId,
    required this.text,
    required this.title,
  });

  final AppPalette palette;
  final String articleId;
  final String text;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final tts = ref.watch(ttsProvider);
    final selected = voiceById(settings.ttsVoice);
    final mine = tts.articleId == articleId && tts.downloading;
    ref.listen(ttsProvider, (prev, next) {
      if (next.articleId != articleId || next.error == prev?.error) return;
      final message = switch (next.error) {
        TtsError.empty => l10n.nothingToListen,
        TtsError.saved => l10n.audioSaved,
        TtsError.saveFailed => l10n.audioSaveFailed,
        _ => null,
      };
      if (message == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
    });
    return Tooltip(
      message: mine && tts.downloadTotal > 0
          ? l10n.downloadingSpeech(tts.downloadDone, tts.downloadTotal)
          : l10n.downloadSpeech,
      child: OutlinedButton(
        style: _readerActionStyle(palette).copyWith(
          padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
          minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
        ),
        onPressed: tts.downloading
            ? null
            : () => ref.read(ttsProvider.notifier).download(
                  articleId: articleId,
                  text: text,
                  voice: selected.id,
                  title: title,
                ),
        child: const Icon(LucideIcons.download, size: 16),
      ),
    );
  }
}

class _TtsVoiceButton extends ConsumerWidget {
  const _TtsVoiceButton({
    required this.palette,
    required this.chineseUi,
  });

  final AppPalette palette;
  final bool chineseUi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final selected = voiceById(settings.ttsVoice);
    final menuStyle = _readerMenuStyle(palette);
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: menuStyle,
      builder: (context, controller, child) {
        return OutlinedButton.icon(
          style: _readerActionStyle(palette),
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(LucideIcons.userRound, size: 16),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(selected.label(chineseUi)),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronDown, size: 14),
            ],
          ),
        );
      },
      menuChildren: [
        _voiceSubmenu(
          palette: palette,
          style: menuStyle,
          label: l10n.ttsVoicesZh,
          voices: voicesForLocale('zh-CN'),
          selectedId: selected.id,
          chineseUi: chineseUi,
          onPick: (id) => ref.read(settingsProvider.notifier).update(settings.copyWith(ttsVoice: id)),
        ),
        _voiceSubmenu(
          palette: palette,
          style: menuStyle,
          label: l10n.ttsVoicesEn,
          voices: voicesForLocale('en-US'),
          selectedId: selected.id,
          chineseUi: chineseUi,
          onPick: (id) => ref.read(settingsProvider.notifier).update(settings.copyWith(ttsVoice: id)),
        ),
      ],
    );
  }
}

SubmenuButton _voiceSubmenu({
  required AppPalette palette,
  required MenuStyle style,
  required String label,
  required List<TtsVoice> voices,
  required String selectedId,
  required bool chineseUi,
  required ValueChanged<String> onPick,
}) {
  return SubmenuButton(
    style: MenuItemButton.styleFrom(foregroundColor: palette.menuFg),
    menuStyle: style,
    submenuIcon: WidgetStatePropertyAll(Icon(LucideIcons.chevronRight, size: 14, color: palette.fgMuted)),
    menuChildren: [
      for (final voice in voices)
        MenuItemButton(
          style: _menuItemStyle(palette),
          onPressed: () => onPick(voice.id),
          child: Text(
            voice.label(chineseUi),
            style: TextStyle(
              color: palette.menuFg,
              fontWeight: voice.id == selectedId ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
    ],
    child: Text(label),
  );
}

MenuStyle _readerMenuStyle(AppPalette palette) {
  return MenuStyle(
    backgroundColor: WidgetStatePropertyAll(palette.menuBg),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
    side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
    ),
  );
}

ButtonStyle _menuItemStyle(AppPalette palette) {
  return ButtonStyle(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
        return palette.menuHover;
      }
      return Colors.transparent;
    }),
  );
}

ButtonStyle _readerActionStyle(AppPalette palette) {
  return ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return palette.fgMuted.withValues(alpha: 0.5);
      if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
        return palette.fg;
      }
      return palette.fgMuted;
    }),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    side: WidgetStateProperty.resolveWith((states) {
      final hover = states.contains(WidgetState.hovered) || states.contains(WidgetState.focused);
      return BorderSide(color: hover ? palette.fgMuted : palette.border);
    }),
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
    minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
    ),
  );
}
