import 'dart:math';

import 'package:flutter/material.dart';

class PaperGrain extends StatelessWidget {
  const PaperGrain({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.85, -1.05),
                radius: 1.35,
                colors: [
                  Color(dark ? 0xFF7A94BE : 0xFF5A6A4C).withValues(alpha: dark ? 0.03 : 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          CustomPaint(
            painter: _GrainPainter(color, dark),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.color, this.dark);

  final Color color;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: dark ? 0.012 : 0.018);
    final rnd = Random(11);
    final count = (size.width * size.height / (dark ? 2200 : 1600)).clamp(30, 120).toInt();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 0.6 + 0.25, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dark != dark;
}
