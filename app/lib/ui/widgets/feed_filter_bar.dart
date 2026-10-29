import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:news_core/news_core.dart';

import '../../l10n/app_localizations.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

class FeedFilterBar extends StatelessWidget {
  const FeedFilterBar({
    super.key,
    required this.palette,
    required this.selectedId,
    required this.sources,
    required this.chinese,
    required this.onSelected,
    this.caption,
  });

  final AppPalette palette;
  final String selectedId;
  final List<SourceDef> sources;
  final bool chinese;
  final ValueChanged<String> onSelected;
  final String? caption;

  String _label(AppLocalizations l10n) {
    if (selectedId == 'all') return l10n.feedAll;
    for (final source in sources) {
      if (source.id == selectedId) return source.displayName(chinese);
    }
    return l10n.feedAll;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTokens.s12, AppTokens.s8, AppTokens.s16, AppTokens.s8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final menuW = constraints.maxWidth;
            return Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MenuAnchor(
                      alignmentOffset: const Offset(0, 4),
                      style: MenuStyle(
                        backgroundColor: WidgetStatePropertyAll(palette.menuBg),
                        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
                        minimumSize: WidgetStatePropertyAll(Size(menuW, 0)),
                        maximumSize: WidgetStatePropertyAll(Size(menuW, 420)),
                        side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
                        ),
                      ),
                      builder: (context, controller, child) {
                        return _FilterTrigger(
                          palette: palette,
                          open: controller.isOpen,
                          label: _label(l10n),
                          onTap: () => controller.isOpen ? controller.close() : controller.open(),
                        );
                      },
                      menuChildren: [
                        _item(l10n.feedAll, 'all', menuW),
                        for (final source in sources) _item(source.displayName(chinese), source.id, menuW),
                      ],
                    ),
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(width: AppTokens.s12),
                  Text(
                    caption!,
                    style: TextStyle(color: palette.fgMuted, fontSize: AppTokens.caption),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _item(String label, String id, double menuW) {
    final selected = id == selectedId;
    return MenuItemButton(
      onPressed: () {
        if (!selected) onSelected(id);
      },
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(menuW, 40)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return palette.menuHover;
          }
          return Colors.transparent;
        }),
      ),
      child: SizedBox(
        width: menuW - 32,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.menuFg,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: AppTokens.body,
          ),
        ),
      ),
    );
  }
}

class _FilterTrigger extends StatefulWidget {
  const _FilterTrigger({
    required this.palette,
    required this.open,
    required this.label,
    required this.onTap,
  });

  final AppPalette palette;
  final bool open;
  final String label;
  final VoidCallback onTap;

  @override
  State<_FilterTrigger> createState() => _FilterTriggerState();
}

class _FilterTriggerState extends State<_FilterTrigger> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final active = _hover || widget.open;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.out,
          decoration: BoxDecoration(
            color: palette.bgElevated,
            borderRadius: BorderRadius.circular(AppTokens.radiusSheet),
            border: Border.all(color: active ? palette.fgMuted : palette.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  switchInCurve: AppMotion.out,
                  switchOutCurve: AppMotion.out,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    widget.label,
                    key: ValueKey(widget.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.fg,
                      fontSize: AppTokens.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              AnimatedRotation(
                turns: widget.open ? 0.5 : 0,
                duration: AppMotion.fast,
                curve: AppMotion.out,
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: active ? palette.fg : palette.fgMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
