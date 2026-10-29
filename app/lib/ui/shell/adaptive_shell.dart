import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/feed_filter.dart';
import '../../core/news_controller.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../article/article_pane.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/paper_grain.dart';

class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({super.key, required this.child});

  final Widget child;

  int _index(String loc) {
    if (loc.startsWith('/sources')) return 1;
    if (loc.startsWith('/saved')) return 2;
    if (loc.startsWith('/me')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loc = GoRouterState.of(context).uri.path;
    final index = _index(loc);
    final settings = ref.watch(settingsProvider);
    final palette = settings.isDark ? AppPalette.dark : AppPalette.light;
    final wide = MediaQuery.sizeOf(context).width >= AppTokens.desktopBreakpoint;
    final nested = loc == '/search' || loc.startsWith('/article') || (loc.startsWith('/sources/') && loc != '/sources');
    final showReader = wide && loc != '/me' && loc != '/search';

    Future<void> openArticle(String id) async {
      await ref.read(newsProvider.notifier).markRead(id);
      ref.read(newsProvider.notifier).select(id);
      if (!context.mounted) return;
      if (loc == '/search') {
        if (settings.feedFilter != 'all') {
          ref.read(settingsProvider.notifier).update(settings.copyWith(feedFilter: 'all'));
        }
        if (wide) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        } else {
          context.go('/');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.push('/article/$id');
          });
        }
        return;
      }
      if (!wide) context.push('/article/$id');
    }

    final destinations = [
      _Nav(LucideIcons.newspaper, l10n.navToday, '/'),
      _Nav(LucideIcons.rss, l10n.navSources, '/sources'),
      _Nav(LucideIcons.bookmark, l10n.navSaved, '/saved'),
      _Nav(LucideIcons.settings, l10n.navMe, '/me'),
    ];

    final list = Column(
      children: [
        if (!nested)
          _TopBar(
            palette: palette,
            brand: l10n.appTitle,
            title: destinations[index.clamp(0, destinations.length - 1)].label,
            onSearch: () => context.push('/search'),
            onRefresh: () => ref.read(newsProvider.notifier).refresh(),
          ),
        if (!nested) _StatusBanner(palette: palette),
        Expanded(child: _InjectOpen(onOpen: openArticle, child: child)),
      ],
    );

    final body = showReader
        ? _DesktopSplit(
            palette: palette,
            list: list,
            reader: _ReaderHost(palette: palette, settings: settings),
          )
        : list;

    final stage = Stack(
      children: [
        ColoredBox(color: palette.bg, child: const SizedBox.expand()),
        PaperGrain(color: palette.fg),
        if (wide)
          Row(
            children: [
              _InkRail(
                palette: palette,
                index: index,
                destinations: destinations,
                onSelect: (i) => context.go(destinations[i].path),
              ),
              Expanded(child: body),
            ],
          )
        else
          Column(
            children: [
              Expanded(child: SafeArea(child: body)),
              if (!loc.startsWith('/article'))
                NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (i) => context.go(destinations[i].path),
                  destinations: [
                    for (final d in destinations)
                      NavigationDestination(
                        icon: d.unread > 0
                            ? Badge(
                                label: Text(d.unread > 99 ? '99+' : '${d.unread}'),
                                child: Icon(d.icon, size: 20),
                              )
                            : Icon(d.icon, size: 20),
                        label: d.label,
                      ),
                  ],
                ),
            ],
          ),
      ],
    );

    void openSearch() {
      if (loc != '/search') context.push('/search');
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): openSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): openSearch,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): () {
          ref.read(newsProvider.notifier).refresh();
        },
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): () {
          ref.read(newsProvider.notifier).refresh();
        },
        const SingleActivator(LogicalKeyboardKey.f5): () {
          ref.read(newsProvider.notifier).refresh();
        },
        const SingleActivator(LogicalKeyboardKey.keyJ): () {
          ref.read(newsProvider.notifier).selectAdjacent(1);
        },
        const SingleActivator(LogicalKeyboardKey.keyK): () {
          ref.read(newsProvider.notifier).selectAdjacent(-1);
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (context.canPop()) {
            context.pop();
            return;
          }
          if (wide && loc == '/' && ref.read(newsProvider).selectedId != null) {
            ref.read(newsProvider.notifier).select(null);
          }
        },
      },
      child: Focus(
        autofocus: loc != '/search',
        child: Scaffold(backgroundColor: palette.bg, body: stage),
      ),
    );
  }
}

class _DesktopSplit extends ConsumerStatefulWidget {
  const _DesktopSplit({
    required this.palette,
    required this.list,
    required this.reader,
  });

  final AppPalette palette;
  final Widget list;
  final Widget reader;

  @override
  ConsumerState<_DesktopSplit> createState() => _DesktopSplitState();
}

class _DesktopSplitState extends ConsumerState<_DesktopSplit> {
  double? _dragWidth;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final maxW = (MediaQuery.sizeOf(context).width - AppTokens.railWidth - 280).clamp(AppTokens.listWidthMin, AppTokens.listWidthMax);
    final width = (_dragWidth ?? settings.listPaneWidth).clamp(AppTokens.listWidthMin, maxW);
    return Row(
      children: [
        SizedBox(
          width: width,
          child: ColoredBox(color: widget.palette.bg, child: widget.list),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragWidth = (width + details.delta.dx).clamp(AppTokens.listWidthMin, maxW);
              });
            },
            onHorizontalDragEnd: (_) {
              final next = _dragWidth ?? width;
              ref.read(settingsProvider.notifier).update(settings.copyWith(listPaneWidth: next));
            },
            child: Container(
              width: 8,
              color: widget.palette.bg,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                width: _hover ? 2 : 1,
                color: _hover ? widget.palette.fgMuted : widget.palette.border,
              ),
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(color: widget.palette.bgElevated, child: widget.reader),
        ),
      ],
    );
  }
}

class _Nav {
  const _Nav(this.icon, this.label, this.path, {this.unread = 0});
  final IconData icon;
  final String label;
  final String path;
  final int unread;
}

class _InkRail extends ConsumerWidget {
  const _InkRail({
    required this.palette,
    required this.index,
    required this.destinations,
    required this.onSelect,
  });

  final AppPalette palette;
  final int index;
  final List<_Nav> destinations;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(newsProvider.select((s) {
      final settings = ref.read(settingsProvider);
      final enabled = resolveEnabledSourceIds(
        enabledSources: settings.enabledSources,
        seenSourceIds: settings.seenSourceIds,
        catalogEnabledIds: [...?s.catalog?.enabled.map((e) => e.id)],
      );
      var n = 0;
      for (final r in s.records) {
        if (!enabled.contains(r.item.sourceId)) continue;
        if (!r.read) n++;
      }
      return n;
    }));
    return Container(
      width: AppTokens.railWidth,
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(right: BorderSide(color: palette.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppTokens.s16),
          for (var i = 0; i < destinations.length; i++)
            _RailItem(
              dest: i == 0 ? _Nav(destinations[i].icon, destinations[i].label, destinations[i].path, unread: unread) : destinations[i],
              selected: i == index,
              palette: palette,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.dest,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final _Nav dest;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final palette = widget.palette;
    final reduce = AppMotion.reduce(context);
    final rest = palette.bgMuted.withValues(alpha: 0);
    final fill = selected ? palette.bgMuted : (_hover && !reduce ? palette.bgMuted : rest);
    final iconColor = selected
        ? palette.primary
        : (_hover ? palette.accent : palette.fgMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: reduce ? Duration.zero : AppMotion.micro,
            curve: Curves.easeOut,
            width: AppTokens.railWidth,
            height: 56,
            color: fill,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: reduce ? Duration.zero : AppMotion.micro,
                      opacity: selected ? 1 : 0,
                      child: ColoredBox(color: palette.primary, child: const SizedBox(width: 2)),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: widget.dest.unread > 0,
                        smallSize: 8,
                        backgroundColor: palette.primary,
                        child: Icon(
                          widget.dest.icon,
                          size: 20,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.dest.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? palette.fg : palette.fgMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.palette,
    required this.brand,
    required this.title,
    required this.onSearch,
    required this.onRefresh,
  });

  final AppPalette palette;
  final String brand;
  final String title;
  final VoidCallback onSearch;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshing = ref.watch(newsProvider.select((s) => s.refreshing));
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8),
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppTokens.s8),
          Text(brand, style: AppType.brand(palette.fg)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8),
            child: Text('·', style: TextStyle(color: palette.fgMuted)),
          ),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            switchInCurve: AppMotion.out,
            switchOutCurve: AppMotion.out,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              title,
              key: ValueKey(title),
              style: TextStyle(color: palette.fgMuted, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Spacer(),
          GhostIconButton(
            tooltip: l10n.actionSearch,
            onPressed: onSearch,
            icon: LucideIcons.search,
            color: palette.fgMuted,
            hoverColor: palette.accent,
          ),
          RefreshSpinButton(
            tooltip: l10n.actionRefresh,
            spinning: refreshing,
            onPressed: onRefresh,
            color: palette.fgMuted,
            hoverColor: palette.accent,
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends ConsumerWidget {
  const _StatusBanner({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final translating = ref.watch(newsProvider.select((s) => s.translating));
    final banner = ref.watch(newsProvider.select((s) => s.banner));
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.out,
      alignment: Alignment.topCenter,
      child: (translating || banner != null)
          ? Material(
              color: palette.bgMuted,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s8, AppTokens.s4, AppTokens.s8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        banner != null
                            ? switch (banner) {
                                'network' => l10n.errorNetwork,
                                'snapshot' => l10n.errorSnapshot,
                                'translate' => l10n.errorTranslate,
                                'body' => l10n.errorBody,
                                _ => l10n.errorPartial,
                              }
                            : l10n.translating,
                        style: TextStyle(
                          color: banner != null ? palette.warning : palette.fgMuted,
                          fontSize: AppTokens.caption,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (banner != null)
                      GhostIconButton(
                        tooltip: l10n.done,
                        onPressed: () => ref.read(newsProvider.notifier).dismissBanner(),
                        icon: LucideIcons.x,
                        color: palette.fgMuted,
                        hoverColor: palette.accent,
                      ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ReaderHost extends ConsumerWidget {
  const _ReaderHost({required this.palette, required this.settings});
  final AppPalette palette;
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(newsProvider.select((s) => s.selected));
    final catalog = ref.watch(newsProvider.select((s) => s.catalog));
    final loadingBody = ref.watch(newsProvider.select((s) => s.loadingBody));
    final translatingBody = ref.watch(newsProvider.select((s) => s.translatingBody));
    final translateFailedId = ref.watch(newsProvider.select((s) => s.translateFailedId));
    return ArticlePane(
      record: selected,
      catalog: catalog,
      palette: palette,
      settings: settings,
      loadingBody: loadingBody,
      translatingBody: translatingBody,
      translateFailed: selected != null && translateFailedId == selected.item.id,
      onFetchBody: selected == null ? null : () => ref.read(newsProvider.notifier).fetchBody(selected.item.id, force: true),
      onTranslate: selected == null ? null : () => ref.read(newsProvider.notifier).translateArticle(selected.item.id),
      onToggleSaved: selected == null ? null : () => ref.read(newsProvider.notifier).toggleSaved(selected.item.id),
      onClose: null,
    );
  }
}

class OpenArticleScope extends InheritedWidget {
  const OpenArticleScope({super.key, required this.onOpen, required super.child});

  final void Function(String id) onOpen;

  static void Function(String id) of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OpenArticleScope>()!.onOpen;
  }

  @override
  bool updateShouldNotify(OpenArticleScope oldWidget) => onOpen != oldWidget.onOpen;
}

class _InjectOpen extends StatelessWidget {
  const _InjectOpen({required this.onOpen, required this.child});
  final void Function(String id) onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) => OpenArticleScope(onOpen: onOpen, child: child);
}
