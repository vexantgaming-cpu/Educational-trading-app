import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/game/game_store.dart';
import 'package:upwiq/lessons/lesson_player.dart';
import 'package:upwiq/main.dart';
import 'package:upwiq/progress/progress_store.dart';
import 'package:upwiq/screens/welcome_screen.dart';
import 'package:upwiq/settings/settings_store.dart';
import 'package:upwiq/theme/app_colors.dart';
import 'package:upwiq/theme/app_theme.dart';

import 'support/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  setUp(rootBundle.clear);

  Future<(ProgressStore, GameStore, SettingsStore)> stores([
    Map<String, Object> saved = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(saved);
    ProgressStore.reset();
    GameStore.reset();
    SettingsStore.reset();
    return (
      await ProgressStore.load(),
      await GameStore.load(clock: () => DateTime(2026, 11, 11, 10)),
      await SettingsStore.load(),
    );
  }

  void phone(WidgetTester tester, {double width = 393, double height = 851}) {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
  }

  testWidgets('a newcomer is welcomed and taken to the first lesson', (
    tester,
  ) async {
    phone(tester);
    final (progress, game, settings) = await stores();
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('any market'), findsOneWidget);

    await next(tester);
    expect(find.text('without risk'), findsOneWidget);
    expect(find.textContaining('virtual money'), findsOneWidget);
    await next(tester);
    expect(find.text('every day'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Start my first lesson'),
    );
    await tester.pumpAndSettle();
    expect(settings.welcomeSeen, isTrue);
    expect(
      tester
          .widget<LessonPlayerScreen>(find.byType(LessonPlayerScreen))
          .lessonId,
      'L0-01',
    );
    expect(find.text('Buyers meet sellers'), findsOneWidget);

    // Closing the lesson lands on the app's tabs, not back on the welcome.
    await tester.tap(find.byTooltip('Close lesson'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('START HERE'), findsOneWidget);
  });

  testWidgets('Skip goes straight to the app, and the welcome stays away', (
    tester,
  ) async {
    phone(tester);
    final (progress, game, settings) = await stores();
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    // Next launch.
    SettingsStore.reset();
    final again = await SettingsStore.load();
    expect(again.welcomeSeen, isTrue);
    await tester.pumpWidget(
      UpwiqApp(
        key: UniqueKey(),
        progress: progress,
        game: game,
        settings: again,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets('"Look around first" on the last page opens the app', (
    tester,
  ) async {
    phone(tester);
    final (progress, game, settings) = await stores();
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    await next(tester);
    await next(tester);
    await tester.tap(find.text('Look around first'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(LessonPlayerScreen), findsNothing);
  });

  testWidgets('someone who already has progress is not shown the welcome', (
    tester,
  ) async {
    phone(tester);
    // Saved by a version of the app from before the welcome existed.
    final (progress, game, settings) = await stores({
      'xp': 25,
      'completed_lessons': ['L0-01'],
    });
    expect(settings.welcomeSeen, isFalse);
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.text('UP NEXT'), findsOneWidget);
  });

  for (final palette in [AppPalette.dark, AppPalette.light]) {
    for (final (width, height, scale) in const [
      (320.0, 568.0, 1.3),
      (320.0, 640.0, 1.0),
      (393.0, 851.0, 1.3),
    ]) {
      testWidgets('welcome fits ${width.toInt()}×${height.toInt()} at '
          '${(scale * 100).round()}% text '
          '(${palette.isDark ? 'dark' : 'light'})', (tester) async {
        phone(tester, width: width, height: height);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(palette),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: WelcomeScreen(onStartLearning: () {}, onExplore: () {}),
          ),
        );
        for (var page = 0; page < 3; page++) {
          expect(tester.takeException(), isNull, reason: 'page ${page + 1}');
          if (page < 2) await next(tester);
        }
        expect(
          find.widgetWithText(FilledButton, 'Start my first lesson'),
          findsOneWidget,
        );
      });
    }
  }
}
