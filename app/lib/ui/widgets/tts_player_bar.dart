import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/tts_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

class TtsPlayerBar extends ConsumerStatefulWidget {
  const TtsPlayerBar({
    super.key,
    required this.palette,
    required this.articleId,
  });

  final AppPalette palette;
  final String articleId;

  @override
  ConsumerState<TtsPlayerBar> createState() => _TtsPlayerBarState();
}

class _TtsPlayerBarState extends ConsumerState<TtsPlayerBar> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = widget.palette;
    final tts = ref.watch(ttsProvider);
    if (!tts.active || tts.articleId != widget.articleId) return const SizedBox.shrink();

    final paused = tts.status == TtsStatus.paused;
    final canPause = tts.status == TtsStatus.playing || paused;
    final durationMs = tts.duration.inMilliseconds;
    final liveMs = tts.position.inMilliseconds.clamp(0, durationMs < 0 ? 0 : durationMs);
    final sliderMs = _dragging ?? liveMs.toDouble();
    final label = tts.preparingChunk
        ? l10n.ttsPreparingChunk(tts.chunkIndex + 1, tts.chunkTotal)
        : [
            if (tts.chunkTotal > 0) l10n.ttsChunkLabel(tts.chunkIndex + 1, tts.chunkTotal),
            if (tts.duration > Duration.zero) l10n.ttsChunkRemaining(formatTtsClock(tts.remaining)),
          ].where((e) => e.isNotEmpty).join('  ·  ');

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.bgElevated,
          borderRadius: BorderRadius.circular(AppTokens.radiusSheet),
          border: Border.all(color: palette.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: palette.primary,
                  inactiveTrackColor: palette.border,
                  thumbColor: palette.primary,
                  overlayColor: palette.primary.withValues(alpha: 0.16),
                ),
                child: Slider(
                  min: 0,
                  max: durationMs > 0 ? durationMs.toDouble() : 1,
                  value: durationMs > 0 ? sliderMs.clamp(0, durationMs.toDouble()) : 0,
                  onChanged: durationMs > 0 && canPause && !tts.preparingChunk
                      ? (value) => setState(() => _dragging = value)
                      : null,
                  onChangeEnd: durationMs > 0 && canPause && !tts.preparingChunk
                      ? (value) {
                          setState(() => _dragging = null);
                          ref.read(ttsProvider.notifier).seek(Duration(milliseconds: value.round()));
                        }
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: Row(
                  children: [
                    GhostIconButton(
                      tooltip: paused ? l10n.resumeSpeech : l10n.pauseSpeech,
                      onPressed: canPause && !tts.preparingChunk
                          ? () => ref.read(ttsProvider.notifier).togglePause()
                          : null,
                      icon: paused ? LucideIcons.play : LucideIcons.pause,
                      color: palette.fgMuted,
                      hoverColor: palette.accent,
                    ),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.meta(palette.fgMuted),
                      ),
                    ),
                    if (tts.duration > Duration.zero) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${formatTtsClock(tts.position)} / ${formatTtsClock(tts.duration)}',
                        style: AppType.meta(palette.fgMuted),
                      ),
                    ],
                    GhostIconButton(
                      tooltip: l10n.stopListening,
                      onPressed: () => ref.read(ttsProvider.notifier).stop(),
                      icon: LucideIcons.square,
                      color: palette.fgMuted,
                      hoverColor: palette.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
