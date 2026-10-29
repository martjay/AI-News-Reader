import 'package:flutter/material.dart';

class AppTokens {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s10 = 10.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s28 = 28.0;
  static const s32 = 32.0;
  static const s48 = 48.0;

  static const radius = 8.0;
  static const radiusSheet = 10.0;
  static const title = 22.0;
  static const display = 27.0;
  static const section = 16.0;
  static const body = 14.0;
  static const readerBody = 17.0;
  static const caption = 12.0;
  static const measure = 592.0;
  static const control = 36.0;
  static const desktopBreakpoint = 900.0;
  static const listWidth = 400.0;
  static const listWidthMin = 280.0;
  static const listWidthMax = 640.0;
  static const railWidth = 76.0;
}

class AppType {
  static const fallback = [
    'PingFang SC',
    'Noto Sans SC',
    'Microsoft YaHei UI',
    'Segoe UI',
    'Roboto',
  ];

  static TextStyle kicker(Color color) => TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.2,
        fontFamilyFallback: fallback,
      );

  static TextStyle display(Color color) => TextStyle(
        color: color,
        fontSize: AppTokens.display,
        fontWeight: FontWeight.w600,
        height: 1.28,
        letterSpacing: -0.3,
        fontFamilyFallback: fallback,
      );

  static TextStyle brand(Color color) => TextStyle(
        color: color,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
        fontFamilyFallback: fallback,
      );

  static TextStyle section(Color color) => TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.2,
        fontFamilyFallback: fallback,
      );

  static TextStyle listTitle({required Color color, required bool read}) => TextStyle(
        color: color,
        fontSize: 15,
        fontWeight: read ? FontWeight.w400 : FontWeight.w600,
        height: 1.4,
        letterSpacing: -0.05,
        fontFamilyFallback: fallback,
      );

  static TextStyle dek(Color color) => TextStyle(
        color: color,
        fontSize: 13.5,
        height: 1.55,
        fontFamilyFallback: fallback,
      );

  static TextStyle readerBody(Color color) => TextStyle(
        color: color,
        fontSize: AppTokens.readerBody,
        height: 1.75,
        letterSpacing: 0.1,
        fontFamilyFallback: fallback,
      );

  static TextStyle meta(Color color) => TextStyle(
        color: color,
        fontSize: 11.5,
        height: 1.35,
        letterSpacing: 0.1,
        fontFamilyFallback: fallback,
      );
}

class AppPalette {
  const AppPalette({
    required this.bg,
    required this.bgElevated,
    required this.bgMuted,
    required this.fg,
    required this.fgMuted,
    required this.border,
    required this.primary,
    required this.primaryFg,
    required this.accent,
    required this.danger,
    required this.success,
    required this.warning,
    required this.inputBg,
    required this.inputFg,
    required this.placeholder,
    required this.scrollTrack,
    required this.scrollThumb,
    required this.menuBg,
    required this.menuFg,
    required this.menuHover,
  });

  final Color bg;
  final Color bgElevated;
  final Color bgMuted;
  final Color fg;
  final Color fgMuted;
  final Color border;
  final Color primary;
  final Color primaryFg;
  final Color accent;
  final Color danger;
  final Color success;
  final Color warning;
  final Color inputBg;
  final Color inputFg;
  final Color placeholder;
  final Color scrollTrack;
  final Color scrollThumb;
  final Color menuBg;
  final Color menuFg;
  final Color menuHover;

  static const light = AppPalette(
    bg: Color(0xFFD8DFCE),
    bgElevated: Color(0xFFE2E8D8),
    bgMuted: Color(0xFFCDD5C3),
    fg: Color(0xFF2F342E),
    fgMuted: Color(0xFF586056),
    border: Color(0xFFC3CBB8),
    primary: Color(0xFF3A5578),
    primaryFg: Color(0xFFE2E8D8),
    accent: Color(0xFFC45A28),
    danger: Color(0xFFB42318),
    success: Color(0xFF3D6B4F),
    warning: Color(0xFF9A6B2F),
    inputBg: Color(0xFFE2E8D8),
    inputFg: Color(0xFF2F342E),
    placeholder: Color(0xFF7A8276),
    scrollTrack: Color(0xFFCDD5C3),
    scrollThumb: Color(0xFFA8B09E),
    menuBg: Color(0xFFE2E8D8),
    menuFg: Color(0xFF2F342E),
    menuHover: Color(0xFFD8DFCE),
  );

  static const dark = AppPalette(
    bg: Color(0xFF12151A),
    bgElevated: Color(0xFF181C23),
    bgMuted: Color(0xFF242A33),
    fg: Color(0xFFB6B4AA),
    fgMuted: Color(0xFF8E8C84),
    border: Color(0xFF252A32),
    primary: Color(0xFF7A94BE),
    primaryFg: Color(0xFF12151A),
    accent: Color(0xFFE0A36A),
    danger: Color(0xFFC97A7A),
    success: Color(0xFF7EAE90),
    warning: Color(0xFFC4A06A),
    inputBg: Color(0xFF181C23),
    inputFg: Color(0xFFB6B4AA),
    placeholder: Color(0xFF6E726C),
    scrollTrack: Color(0xFF181C23),
    scrollThumb: Color(0xFF3E4450),
    menuBg: Color(0xFF181C23),
    menuFg: Color(0xFFB6B4AA),
    menuHover: Color(0xFF242A33),
  );
}
