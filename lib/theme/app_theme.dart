import 'package:flutter/material.dart';

import 'app_colors.dart';

const headingFont = 'Poppins';
const bodyFont = 'Inter';

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.gold,
    onPrimary: AppColors.onGold,
    primaryContainer: Color(0xFF3A2A0A),
    onPrimaryContainer: AppColors.gold,
    secondary: AppColors.cyan,
    onSecondary: Color(0xFF04141B),
    secondaryContainer: Color(0xFF0F2A36),
    onSecondaryContainer: AppColors.cyan,
    tertiary: AppColors.violet,
    onTertiary: Color(0xFF160B33),
    surface: AppColors.background,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: AppColors.surfaceHighest,
    outline: AppColors.outline,
    outlineVariant: AppColors.outline,
    error: AppColors.down,
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
        color: AppColors.text,
        letterSpacing: -0.2,
      );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: text.copyWith(
      displaySmall: heading(text.displaySmall, FontWeight.w700),
      headlineLarge: heading(text.headlineLarge, FontWeight.w700),
      headlineMedium: heading(text.headlineMedium, FontWeight.w700),
      headlineSmall: heading(text.headlineSmall, FontWeight.w600),
      titleLarge: heading(text.titleLarge, FontWeight.w600),
      titleMedium: heading(text.titleMedium, FontWeight.w600),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.45, color: AppColors.text),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.4, color: AppColors.text),
      bodySmall: text.bodySmall?.copyWith(color: AppColors.textMuted),
      labelSmall: text.labelSmall?.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: headingFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0E131A),
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.gold.withValues(alpha: 0.16),
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: bodyFont,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.textMuted,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.onGold,
        disabledBackgroundColor: AppColors.surfaceHighest,
        disabledForegroundColor: AppColors.textMuted,
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
        foregroundColor: AppColors.gold,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: headingFont,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceHigh,
      selectedColor: AppColors.gold.withValues(alpha: 0.18),
      side: const BorderSide(color: AppColors.outline),
      labelStyle: const TextStyle(
        fontFamily: bodyFont,
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
      checkmarkColor: AppColors.gold,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold.withValues(alpha: 0.16)
              : AppColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.textMuted,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.outline),
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.gold,
      linearTrackColor: AppColors.surfaceHighest,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceHighest,
      contentTextStyle: TextStyle(fontFamily: bodyFont, color: AppColors.text),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outline, space: 1),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.textMuted),
  );
}
