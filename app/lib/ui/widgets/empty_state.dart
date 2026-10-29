import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.palette,
    required this.message,
    this.icon = LucideIcons.inbox,
    this.action,
  });

  final AppPalette palette;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(AppTokens.radiusSheet),
            color: palette.bgElevated,
          ),
          child: Icon(icon, size: 22, color: palette.fgMuted),
        ),
        const SizedBox(height: AppTokens.s16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.fgMuted, fontSize: AppTokens.body, height: 1.55),
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: AppTokens.s16),
          action!,
        ],
      ],
    );
    if (AppMotion.reduce(context)) {
      return Center(child: Padding(padding: const EdgeInsets.all(AppTokens.s32), child: inner));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s32),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.pane,
          curve: AppMotion.out,
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
            );
          },
          child: inner,
        ),
      ),
    );
  }
}
