import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sim/market_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/game/game_scope.dart';
import 'package:upwiq/game/game_store.dart';
import 'package:upwiq/game/trading_session_screen.dart';
import 'package:upwiq/lessons/lesson_player.dart';
import 'package:upwiq/main.dart';
import 'package:upwiq/progress/progress_scope.dart';
import 'package:upwiq/progress/progress_store.dart';
import 'package:upwiq/settings/settings_store.dart';
import 'package:upwiq/theme/app_colors.dart';
import 'package:upwiq/theme/app_theme.dart';

import 'support/fonts.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

/// WCAG 2 contrast ratio.
double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUpAll(loadAppFonts);

  group('palettes stay readable', () {
    for (final (name, p) in [
      ('dark', AppPalette.dark),
      ('light', AppPalette.light),
    ]) {
      test('$name: text and accents have enough contrast', () {
        expect(contrast(p.text, p.surface), greaterThanOrEqualTo(7));
        expect(contrast(p.textMuted, p.surface), greaterThanOrEqualTo(4.5));
        for (final accent in [p.gold, p.up, p.down, p.cyan, p.violet]) {
          expect(
            contrast(accent, p.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$name accent $accent on cards',
          );
          expect(
            contrast(accent, p.background),
            greaterThanOrEqualTo(4.3),
            reason: '$name accent $accent on the background',
          );
        }
        // Dark text on the gold→orange call-to-action gradient.
        expect(
          contrast(AppColors.onGold, AppColors.gradientOrange),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  Future<(ProgressStore, GameStore, SettingsStore)> stores() async {
    SharedPreferences.setMockInitialValues({});
    ProgressStore.reset();
    GameStore.reset();
    SettingsStore.reset();
    return (
      await ProgressStore.load(),
      await GameStore.load(clock: () => DateTime(2026, 9, 30, 10)),
      await SettingsStore.load(),
    );
  }

  Brightness brightnessOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(NavigationBar))).brightness;

  testWidgets('switch to light in Account, remembered after restart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (progress, game, settings) = await stores();
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    expect(brightnessOf(tester), Brightness.dark, reason: 'dark by default');

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Light'), 200);
    // Centre it: the tab content scrolls behind the navigation bar.
    await Scrollable.ensureVisible(
      tester.element(find.text('Light')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.light);
    expect(
      Theme.of(tester.element(find.byType(NavigationBar)))
          .scaffoldBackgroundColor,
      AppPalette.light.background,
    );

    SettingsStore.reset();
    expect((await SettingsStore.load()).themeMode, ThemeMode.light);
  });

  testWidgets('Auto follows the phone setting', (tester) async {
    final (progress, game, settings) = await stores();
    await settings.setThemeMode(ThemeMode.system);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    expect(brightnessOf(tester), Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.dark);
  });

  testWidgets('every main screen renders in light mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final (progress, game, settings) = await stores();
    await settings.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    for (final tab in ['Learn', 'Practice', 'League', 'Account']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab tab');
    }

    await tester.pumpWidget(
      ProgressScope(
        store: progress,
        child: MaterialApp(
          theme: buildAppTheme(AppPalette.light),
          home: const LessonPlayerScreen(lessonId: 'L0-05'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'lesson');

    await tester.pumpWidget(
      GameScope(
        store: game,
        child: MaterialApp(
          theme: buildAppTheme(AppPalette.light),
          home: const TradingSessionScreen(
            market: GameMarkets.gold,
            dayNumber: 272,
            ranked: false,
            startingBalance: 10000,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'trading session');
  });
}
