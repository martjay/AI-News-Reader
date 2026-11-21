import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key, required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s16, AppTokens.s16, AppTokens.s32),
      children: [
        for (var i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(palette, 88, 10),
                const SizedBox(height: AppTokens.s8),
                _bar(palette, double.infinity, 14),
                const SizedBox(height: 6),
                _bar(palette, 220, 14),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bar(AppPalette palette, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.bgMuted,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
