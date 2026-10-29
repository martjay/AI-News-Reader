import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import '../core/news_controller.dart';
import '../core/settings.dart';
import '../l10n/app_localizations.dart';
import '../ui/article/article_pane.dart';
import '../ui/bookmarks/bookmarks_page.dart';
import '../ui/search/search_page.dart';
import '../ui/settings/settings_page.dart';
import '../ui/shell/adaptive_shell.dart';
import '../ui/sources/source_detail_page.dart';
import '../ui/sources/sources_page.dart';
import '../ui/theme/app_theme.dart';
import '../ui/theme/motion.dart';
import '../ui/theme/tokens.dart';
import '../ui/today/today_page.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AdaptiveShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => inkPage(key: state.pageKey, child: const _Today()),
        ),
        GoRoute(
          path: '/sources',
          pageBuilder: (context, state) => inkPage(key: state.pageKey, child: const _Sources()),
        ),
        GoRoute(
          path: '/sources/:id',
          pageBuilder: (context, state) =>
              inkPage(key: state.pageKey, child: _SourceDetail(id: state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/saved',
          pageBuilder: (context, state) => inkPage(key: state.pageKey, child: const _Saved()),
        ),
        GoRoute(
          path: '/me',
          pageBuilder: (context, state) => inkPage(key: state.pageKey, child: const _Me()),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => inkPage(key: state.pageKey, child: const _Search()),
        ),
        GoRoute(
          path: '/article/:id',
          pageBuilder: (context, state) => inkPage(
            key: state.pageKey,
            child: _Article(id: state.pathParameters['id']!),
          ),
        ),
      ],
    ),
  ],
);

class InkBriefApp extends ConsumerStatefulWidget {
  const InkBriefApp({super.key});

  @override
  ConsumerState<InkBriefApp> createState() => _InkBriefAppState();
}

class _InkBriefAppState extends ConsumerState<InkBriefApp> {
  String? _windowTitle;

  void _syncWindowTitle(String title) {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    if (_windowTitle == title) return;
    _windowTitle = title;
    windowManager.setTitle(title);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final palette = settings.isDark ? AppPalette.dark : AppPalette.light;
    final theme = buildAppTheme(palette, dark: settings.isDark);
    final title = settings.isZh ? '新闻' : 'News';
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWindowTitle(title));
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(settings.fontScale)),
      child: MaterialApp.router(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: theme,
        themeAnimationDuration: AppMotion.theme,
        themeAnimationCurve: AppMotion.out,
        locale: settings.isZh ? const Locale('zh') : const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: _router,
      ),
    );
  }
}

AppPalette _paletteOf(WidgetRef ref) {
  return ref.watch(settingsProvider).isDark ? AppPalette.dark : AppPalette.light;
}

class _Today extends ConsumerWidget {
  const _Today();
  @override
  Widget build(BuildContext context, WidgetRef ref) => TodayPage(palette: _paletteOf(ref));
}

class _Sources extends ConsumerWidget {
  const _Sources();
  @override
  Widget build(BuildContext context, WidgetRef ref) => SourcesPage(palette: _paletteOf(ref));
}

class _SourceDetail extends ConsumerWidget {
  const _SourceDetail({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SourceDetailPage(sourceId: id, palette: _paletteOf(ref));
}

class _Saved extends ConsumerWidget {
  const _Saved();
  @override
  Widget build(BuildContext context, WidgetRef ref) => BookmarksPage(palette: _paletteOf(ref));
}

class _Me extends ConsumerWidget {
  const _Me();
  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsPage(palette: _paletteOf(ref));
}

class _Search extends ConsumerWidget {
  const _Search();
  @override
  Widget build(BuildContext context, WidgetRef ref) => SearchPage(palette: _paletteOf(ref));
}

class _Article extends ConsumerStatefulWidget {
  const _Article({required this.id});
  final String id;

  @override
  ConsumerState<_Article> createState() => _ArticleState();
}

class _ArticleState extends ConsumerState<_Article> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSelected());
  }

  @override
  void didUpdateWidget(covariant _Article oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSelected());
    }
  }

  void _ensureSelected() {
    if (!mounted) return;
    final news = ref.read(newsProvider);
    if (news.selectedId != widget.id) {
      ref.read(newsProvider.notifier).select(widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final news = ref.watch(newsProvider);
    final settings = ref.watch(settingsProvider);
    final palette = _paletteOf(ref);
    final record = news.records.where((r) => r.item.id == widget.id).firstOrNull ?? news.selected;
    return ArticlePane(
      record: record,
      catalog: news.catalog,
      palette: palette,
      settings: settings,
      loadingBody: news.loadingBody && news.selectedId == widget.id,
      translatingBody: news.translatingBody && news.selectedId == widget.id,
      translateFailed: news.translateFailedId == widget.id,
      onFetchBody: record == null ? null : () => ref.read(newsProvider.notifier).fetchBody(widget.id, force: true),
      onTranslate: record == null ? null : () => ref.read(newsProvider.notifier).translateArticle(widget.id),
      onToggleSaved: record == null ? null : () => ref.read(newsProvider.notifier).toggleSaved(widget.id),
      onClose: () => Navigator.of(context).maybePop(),
    );
  }
}
