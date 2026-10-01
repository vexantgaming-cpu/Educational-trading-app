import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

const headingFont = 'Poppins';
const bodyFont = 'Inter';

ThemeData buildAppTheme([AppPalette p = AppPalette.dark]) {
  final dark = p.isDark;
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.gold,
    onPrimary: AppColors.onGold,
    primaryContainer: dark ? const Color(0xFF3A2A0A) : const Color(0xFFFFEFD2),
    onPrimaryContainer: p.gold,
    secondary: p.cyan,
    onSecondary: dark ? const Color(0xFF04141B) : Colors.white,
    secondaryContainer: dark
        ? const Color(0xFF0F2A36)
        : const Color(0xFFDDF3FA),
    onSecondaryContainer: p.cyan,
    tertiary: p.violet,
    onTertiary: dark ? const Color(0xFF160B33) : Colors.white,
    surface: p.background,
    onSurface: p.text,
    onSurfaceVariant: p.textMuted,
    surfaceContainerLowest: p.background,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceHigh,
    surfaceContainerHighest: p.surfaceHighest,
    outline: p.outline,
    outlineVariant: p.outline,
    error: p.down,
    onError: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: bodyFont,
  );
  final text = base.textTheme;
  TextStyle heading(TextStyle? style, FontWeight weight) =>
      (style ?? const TextStyle()).copyWith(
        fontFamily: headingFont,
        fontWeight: weight,
        color: p.text,
        letterSpacing: -0.2,
      );
  final overlay = dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

  return base.copyWith(
    extensions: [p],
    scaffoldBackgroundColor: p.background,
    textTheme: text.copyWith(
      displaySmall: heading(text.displaySmall, FontWeight.w700),
      headlineLarge: heading(text.headlineLarge, FontWeight.w700),
      headlineMedium: heading(text.headlineMedium, FontWeight.w700),
      headlineSmall: heading(text.headlineSmall, FontWeight.w600),
      titleLarge: heading(text.titleLarge, FontWeight.w600),
      titleMedium: heading(text.titleMedium, FontWeight.w600),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.45, color: p.text),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.4, color: p.text),
      bodySmall: text.bodySmall?.copyWith(color: p.textMuted),
      labelSmall: text.labelSmall?.copyWith(
        color: p.textMuted,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: overlay,
      titleTextStyle: TextStyle(
        fontFamily: headingFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.outline),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.navBar,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.gold.withValues(alpha: dark ? 0.16 : 0.14),
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? p.gold : p.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: bodyFont,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? p.gold : p.textMuted,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gradientGold,
        foregroundColor: AppColors.onGold,
        disabledBackgroundColor: p.surfaceHighest,
        disabledForegroundColor: p.textMuted,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: headingFont,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.gold,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: p.gold.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: headingFont,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.gold),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surfaceHigh,
      selectedColor: p.gold.withValues(alpha: 0.18),
      side: BorderSide(color: p.outline),
      labelStyle: TextStyle(
        fontFamily: bodyFont,
        color: p.text,
        fontWeight: FontWeight.w500,
      ),
      checkmarkColor: p.gold,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.gold.withValues(alpha: 0.16)
              : p.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.gold : p.textMuted,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: p.outline)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.gold,
      linearTrackColor: p.surfaceHighest,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? p.surfaceHighest : const Color(0xFF1F2937),
      contentTextStyle: TextStyle(
        fontFamily: bodyFont,
        color: dark ? p.text : Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.surface),
    dividerTheme: DividerThemeData(color: p.outline, space: 1),
    listTileTheme: ListTileThemeData(iconColor: p.textMuted),
  );
}
