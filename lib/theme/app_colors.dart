import 'package:flutter/material.dart';

/// Brand palette: deep night background, warm gold→orange accent, and
/// distinct market up/down colours. Dark-first, like most trading apps.
class AppColors {
  static const background = Color(0xFF0B0F15);
  static const surface = Color(0xFF131922);
  static const surfaceHigh = Color(0xFF1A222E);
  static const surfaceHighest = Color(0xFF232D3B);
  static const outline = Color(0xFF283343);

  static const text = Color(0xFFEAEEF3);
  static const textMuted = Color(0xFF8A96A8);

  /// Primary accent (gold) and its gradient partner (sunset orange).
  static const gold = Color(0xFFFFB627);
  static const orange = Color(0xFFFF7A2F);
  static const onGold = Color(0xFF1B1203);

  static const up = Color(0xFF19C98B);
  static const down = Color(0xFFFF4D6A);
  static const cyan = Color(0xFF3CC8F0);
  static const violet = Color(0xFFA78BFA);
  static const violetDeep = Color(0xFF7C3AED);

  static const primaryGradient = LinearGradient(
    colors: [gold, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const premiumGradient = LinearGradient(
    colors: [Color(0xFFC4B5FD), violetDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1E2736), Color(0xFF121820)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
