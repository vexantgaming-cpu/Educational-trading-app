import 'package:flutter/material.dart';

/// Brand constants that look the same in light and dark themes.
class AppColors {
  /// The signature call-to-action gradient (gold → sunset orange).
  static const gradientGold = Color(0xFFFFB627);
  static const gradientOrange = Color(0xFFFF7A2F);
  static const onGold = Color(0xFF1B1203);

  static const primaryGradient = LinearGradient(
    colors: [gradientGold, gradientOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const premiumGradient = LinearGradient(
    colors: [Color(0xFFC4B5FD), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Colours that change with the theme. Read them with `context.palette`.
///
/// Light-theme accents are deeper versions of the brand colours so text and
/// numbers keep at least 4.5:1 contrast on white (WCAG AA).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.outline,
    required this.navBar,
    required this.text,
    required this.textMuted,
    required this.gold,
    required this.orange,
    required this.up,
    required this.down,
    required this.cyan,
    required this.violet,
    required this.violetDeep,
    required this.heroTop,
    required this.heroBottom,
  });

  /// Night market: the original, dark-first look.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0B0F15),
    surface: Color(0xFF131922),
    surfaceHigh: Color(0xFF1A222E),
    surfaceHighest: Color(0xFF232D3B),
    outline: Color(0xFF283343),
    navBar: Color(0xFF0E131A),
    text: Color(0xFFEAEEF3),
    textMuted: Color(0xFF8A96A8),
    gold: Color(0xFFFFB627),
    orange: Color(0xFFFF7A2F),
    up: Color(0xFF19C98B),
    down: Color(0xFFFF4D6A),
    cyan: Color(0xFF3CC8F0),
    violet: Color(0xFFA78BFA),
    violetDeep: Color(0xFF7C3AED),
    heroTop: Color(0xFF1E2736),
    heroBottom: Color(0xFF121820),
  );

  /// Daylight: soft grey background, white cards, deeper accents.
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF5F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEEF1F6),
    surfaceHighest: Color(0xFFE3E8F0),
    outline: Color(0xFFD8DEE8),
    navBar: Color(0xFFFFFFFF),
    text: Color(0xFF111827),
    textMuted: Color(0xFF5B6577),
    gold: Color(0xFFA86500),
    orange: Color(0xFFC2410C),
    up: Color(0xFF06855C),
    down: Color(0xFFD92D4A),
    cyan: Color(0xFF0A7EA4),
    violet: Color(0xFF6D28D9),
    violetDeep: Color(0xFF5B21B6),
    heroTop: Color(0xFFFFFFFF),
    heroBottom: Color(0xFFEEF2F8),
  );

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color outline;
  final Color navBar;
  final Color text;
  final Color textMuted;

  /// Accent for text, icons and lines (the gradient stays bright).
  final Color gold;
  final Color orange;
  final Color up;
  final Color down;
  final Color cyan;
  final Color violet;
  final Color violetDeep;
  final Color heroTop;
  final Color heroBottom;

  bool get isDark => brightness == Brightness.dark;

  LinearGradient get heroGradient => LinearGradient(
    colors: [heroTop, heroBottom],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  AppPalette copyWith({Brightness? brightness}) => brightness == null
      ? this
      : (brightness == Brightness.dark ? dark : light);

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      surfaceHighest: l(surfaceHighest, other.surfaceHighest),
      outline: l(outline, other.outline),
      navBar: l(navBar, other.navBar),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      gold: l(gold, other.gold),
      orange: l(orange, other.orange),
      up: l(up, other.up),
      down: l(down, other.down),
      cyan: l(cyan, other.cyan),
      violet: l(violet, other.violet),
      violetDeep: l(violetDeep, other.violetDeep),
      heroTop: l(heroTop, other.heroTop),
      heroBottom: l(heroBottom, other.heroBottom),
    );
  }
}

extension PaletteContext on BuildContext {
  /// The colours of the active theme.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
