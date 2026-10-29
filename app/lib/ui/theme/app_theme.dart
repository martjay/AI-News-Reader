import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

ThemeData buildAppTheme(AppPalette p, {required bool dark}) {
  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: p.primary,
    onPrimary: p.primaryFg,
    secondary: p.primary,
    onSecondary: p.primaryFg,
    error: p.danger,
    onError: p.primaryFg,
    surface: p.bgElevated,
    onSurface: p.fg,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    dividerColor: p.border,
    splashFactory: NoSplash.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    textTheme: base.textTheme.apply(
      bodyColor: p.fg,
      displayColor: p.fg,
      fontSizeFactor: 1,
    ).copyWith(
      bodyMedium: TextStyle(color: p.fg, fontSize: AppTokens.body, height: 1.55, fontFamilyFallback: AppType.fallback),
      titleMedium: TextStyle(
        color: p.fg,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: AppType.fallback,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: p.fg,
        fontSize: AppTokens.section,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.bgElevated,
      indicatorColor: p.primary.withValues(alpha: dark ? 0.22 : 0.12),
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return IconThemeData(color: selected ? p.primary : p.fgMuted, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          letterSpacing: 0.2,
          color: selected ? p.primary : p.fgMuted,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.bg,
      selectedIconTheme: IconThemeData(color: p.primary),
      unselectedIconTheme: IconThemeData(color: p.fgMuted),
      selectedLabelTextStyle: TextStyle(color: p.fg, fontSize: AppTokens.caption, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption),
      indicatorColor: p.bgMuted,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.inputBg,
      hintStyle: TextStyle(color: p.placeholder, fontSize: AppTokens.body),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        borderSide: BorderSide(color: p.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.menuBg),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.menuBg,
      textStyle: TextStyle(color: p.menuFg, fontSize: AppTokens.body),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(color: p.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.bgElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(color: p.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.fg,
      contentTextStyle: TextStyle(color: p.bg, fontSize: AppTokens.body),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
      behavior: SnackBarBehavior.floating,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.primary,
      inactiveTrackColor: p.border,
      thumbColor: p.primary,
      overlayColor: p.primary.withValues(alpha: 0.14),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(p.scrollThumb),
      trackColor: WidgetStatePropertyAll(p.scrollTrack),
      thickness: const WidgetStatePropertyAll(5),
      radius: const Radius.circular(8),
      crossAxisMargin: 2,
      mainAxisMargin: 8,
      minThumbLength: 32,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primaryFg : p.fgMuted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primary : p.bgMuted),
    ),
    dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
    listTileTheme: ListTileThemeData(
      iconColor: p.fgMuted,
      textColor: p.fg,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: p.fg,
        minimumSize: const Size(36, 36),
        overlayColor: Colors.transparent,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.primaryFg,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
        minimumSize: const Size(64, 36),
        animationDuration: AppMotion.fast,
        textStyle: const TextStyle(fontSize: AppTokens.body, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.fgMuted,
        minimumSize: const Size(64, 36),
        overlayColor: Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.fgMuted,
        side: BorderSide(color: p.border),
        overlayColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
        minimumSize: const Size(64, 36),
        animationDuration: AppMotion.fast,
      ),
    ),
  );
}
