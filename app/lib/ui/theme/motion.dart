import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppMotion {
  static const micro = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 200);
  static const page = Duration(milliseconds: 260);
  static const pane = Duration(milliseconds: 280);
  static const theme = Duration(milliseconds: 240);

  static const out = Cubic(0.16, 1, 0.3, 1);
  static const standard = Curves.easeOutCubic;
  static const enter = Cubic(0.16, 1, 0.3, 1);

  static bool reduce(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  static Widget fadeSlide({
    required Animation<double> animation,
    required Widget child,
    Offset begin = const Offset(0, 0.012),
  }) {
    final curved = CurvedAnimation(parent: animation, curve: out, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> {
  bool _played = false;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduce(context) || _played) return widget.child;
    final start = (widget.index * 0.018).clamp(0.0, 0.22);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + widget.index * 12),
      curve: Interval(start, 1, curve: AppMotion.out),
      onEnd: () {
        if (mounted) setState(() => _played = true);
      },
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 8),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class PressSurface extends StatefulWidget {
  const PressSurface({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
    this.color = Colors.transparent,
    this.hoverColor,
    this.selectedColor,
    this.borderRadius,
    this.margin,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final Color color;
  final Color? hoverColor;
  final Color? selectedColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  State<PressSurface> createState() => _PressSurfaceState();
}

class _PressSurfaceState extends State<PressSurface> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduce(context);
    final hover = widget.hoverColor ?? widget.color;
    final rest = widget.color == Colors.transparent ? hover.withValues(alpha: 0) : widget.color;
    final fill = widget.selected
        ? (widget.selectedColor ?? widget.color)
        : (_hover && !reduce ? hover : rest);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : AppMotion.micro,
          curve: Curves.easeOut,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class GhostIconButton extends StatefulWidget {
  const GhostIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
    this.active = false,
    this.activeColor,
    this.hoverColor,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool active;
  final Color? activeColor;
  final Color? hoverColor;

  @override
  State<GhostIconButton> createState() => _GhostIconButtonState();
}

class _GhostIconButtonState extends State<GhostIconButton> {
  bool _hover = false;
  bool _down = false;

  Color get _iconColor {
    final base = widget.active ? (widget.activeColor ?? widget.color) : widget.color;
    if (widget.onPressed == null) return base.withValues(alpha: 0.4);
    if (_down) return (widget.hoverColor ?? base).withValues(alpha: 0.72);
    if (_hover) return widget.hoverColor ?? widget.color;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final icon = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Icon(widget.icon, size: 18, color: _iconColor),
          ),
        ),
      ),
    );
    if (widget.tooltip == null) return icon;
    return Tooltip(
      message: widget.tooltip!,
      waitDuration: const Duration(milliseconds: 400),
      preferBelow: true,
      child: icon,
    );
  }
}

class RefreshSpinButton extends StatefulWidget {
  const RefreshSpinButton({
    super.key,
    required this.spinning,
    required this.onPressed,
    required this.color,
    required this.tooltip,
    this.hoverColor,
  });

  final bool spinning;
  final VoidCallback onPressed;
  final Color color;
  final String tooltip;
  final Color? hoverColor;

  @override
  State<RefreshSpinButton> createState() => _RefreshSpinButtonState();
}

class _RefreshSpinButtonState extends State<RefreshSpinButton> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 780));
    if (widget.spinning) _spin.repeat();
  }

  @override
  void didUpdateWidget(RefreshSpinButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.spinning && _spin.isAnimating) {
      _spin.animateTo(1, duration: AppMotion.fast, curve: AppMotion.out).whenComplete(() {
        if (mounted && !widget.spinning) {
          _spin
            ..stop()
            ..value = 0;
        }
      });
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, child) {
        return Transform.rotate(
          angle: _spin.value * math.pi * 2,
          child: child,
        );
      },
      child: GhostIconButton(
        tooltip: widget.tooltip,
        onPressed: widget.onPressed,
        icon: LucideIcons.refreshCw,
        color: widget.color,
        hoverColor: widget.hoverColor,
      ),
    );
  }
}

class HoverLift extends StatelessWidget {
  const HoverLift({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressSurface(
      onTap: onTap ?? () {},
      hoverColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
      child: child,
    );
  }
}

CustomTransitionPage<void> inkPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppMotion.page,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondary, child) {
      if (AppMotion.reduce(context)) return child;
      return AppMotion.fadeSlide(animation: animation, child: child);
    },
  );
}
