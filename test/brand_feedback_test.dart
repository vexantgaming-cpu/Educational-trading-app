import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/app_info.dart';
import 'package:upwiq/game/game_scope.dart';
import 'package:upwiq/game/game_store.dart';
import 'package:upwiq/lessons/lesson_model.dart';
import 'package:upwiq/lessons/lesson_player.dart';
import 'package:upwiq/lessons/mind_art.dart';
import 'package:upwiq/main.dart';
import 'package:upwiq/progress/progress_scope.dart';
import 'package:upwiq/progress/progress_store.dart';
import 'package:upwiq/screens/feedback_screen.dart';
import 'package:upwiq/settings/settings_store.dart';
import 'package:upwiq/theme/app_colors.dart';
import 'package:upwiq/theme/app_theme.dart';
import 'package:upwiq/widgets/upwiq_logo.dart';

import 'support/fonts.dart';

LessonContent _lesson(String id) => LessonContent.fromJson(
  jsonDecode(File('assets/lessons/$id.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  setUpAll(loadAppFonts);

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

  void phone(WidgetTester tester, {double width = 320, double height = 640}) {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  test('appVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([0-9.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });

  group('logo', () {
    testWidgets('the brand bar shows the Upwiq logo', (tester) async {
      final (progress, game, settings) = await stores();
      await tester.pumpWidget(
        UpwiqApp(progress: progress, game: game, settings: settings),
      );
      final logo = find.byType(UpwiqLogo);
      expect(logo, findsOneWidget);
      expect(find.bySemanticsLabel('Upwiq'), findsOneWidget);
      // Horizontal lockup keeps the artboard's 272.6 : 90 proportions.
      final size = tester.getSize(logo);
      expect(size.height, 28);
      expect(size.width, closeTo(28 * 272.6 / 90, 0.01));
    });

    test('every variant paints in both themes', () {
      for (final variant in UpwiqLogoVariant.values) {
        for (final palette in [AppPalette.dark, AppPalette.light]) {
          final recorder = ui.PictureRecorder();
          UpwiqLogoPainter(
            variant: variant,
            letterColor: palette.text,
          ).paint(Canvas(recorder), const Size(120, 60));
          recorder.endRecording().dispose();
        }
      }
    });
  });

  group('psychology art', () {
    test('every explain step in the Level 7 lessons has art', () {
      final used = <LessonArt>{};
      for (final id in const ['L7-01', 'L7-02', 'L7-03']) {
        for (final step in _lesson(id).steps.whereType<ExplainStep>()) {
          expect(step.art, isNotNull, reason: '$id "${step.title}"');
          used.add(step.art!);
        }
      }
      expect(used, LessonArt.values.toSet(), reason: 'each picture is used');
    });

    test('every picture paints in both themes and at odd sizes', () {
      for (final art in LessonArt.values) {
        expect(art.description, isNotEmpty);
        for (final palette in [AppPalette.dark, AppPalette.light]) {
          for (final size in const [Size(288, 150), Size(600, 150)]) {
            final recorder = ui.PictureRecorder();
            MindArtPainter(art, palette).paint(Canvas(recorder), size);
            recorder.endRecording().dispose();
          }
        }
      }
    });

    for (final palette in [AppPalette.dark, AppPalette.light]) {
      testWidgets('steps with art fit a 320dp phone at 130% text '
          '(${palette.isDark ? 'dark' : 'light'})', (tester) async {
        phone(tester);
        final (progress, _, _) = await stores();
        for (final id in const ['L7-01', 'L7-02', 'L7-03']) {
          final lesson = _lesson(id);
          for (var i = 0; i < lesson.steps.length; i++) {
            final step = lesson.steps[i];
            if (step is! ExplainStep || step.art == null) continue;
            await tester.pumpWidget(
              ProgressScope(
                store: progress,
                child: MaterialApp(
                  theme: buildAppTheme(palette),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(1.3)),
                    child: child!,
                  ),
                  home: LessonPlayerScreen(
                    key: ValueKey('$id-$i'),
                    lessonId: id,
                    content: lesson,
                    initialStep: i,
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(find.byType(LessonArtPanel), findsOneWidget);
            expect(find.text(step.title!), findsOneWidget);
            expect(tester.takeException(), isNull, reason: '$id step $i');
          }
        }
      });
    }
  });

  group('feedback', () {
    Future<void> pumpFeedback(
      WidgetTester tester,
      FeedbackLauncher launcher, {
      double scale = 1.0,
    }) async {
      final (progress, game, settings) = await stores();
      await tester.pumpWidget(
        SettingsScope(
          store: settings,
          child: ProgressScope(
            store: progress,
            child: GameScope(
              store: game,
              child: MaterialApp(
                theme: buildAppTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Builder(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FeedbackScreen(launcher: launcher),
                          ),
                        ),
                        child: const Text('open'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    // The form is a lazy list: scroll each part into view before using it.
    Future<void> reveal(WidgetTester tester, Finder finder) =>
        tester.scrollUntilVisible(
          finder,
          120,
          scrollable: find
              .descendant(
                of: find.byType(FeedbackScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );

    Future<void> fillIn(WidgetTester tester) async {
      await tester.tap(find.byTooltip('4 of 5: Good'));
      await reveal(tester, find.text('Idea'));
      await tester.tap(find.text('Idea'));
      final message = find.byKey(const Key('feedback-message'));
      await reveal(tester, message);
      await tester.enterText(
        message,
        'Please add a lesson on gaps & weekends.',
      );
      await tester.pump();
    }

    Finder sendButton() => find.widgetWithText(FilledButton, 'Send feedback');

    Future<void> send(WidgetTester tester) async {
      await reveal(tester, sendButton());
      await tester.tap(sendButton());
      await tester.pumpAndSettle();
    }

    testWidgets('Account opens the feedback form', (tester) async {
      final (progress, game, settings) = await stores();
      await tester.pumpWidget(
        UpwiqApp(progress: progress, game: game, settings: settings),
      );
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Leave feedback'), 200);
      await tester.tap(find.text('Leave feedback'));
      await tester.pumpAndSettle();
      expect(find.text('How are you finding Upwiq?'), findsOneWidget);
    });

    testWidgets('send is disabled until there is a rating or a message', (
      tester,
    ) async {
      await pumpFeedback(tester, (_) async => true);
      FilledButton button() => tester.widget<FilledButton>(sendButton());
      await reveal(tester, sendButton());
      expect(button().onPressed, isNull);
      await tester.drag(find.byType(ListView), const Offset(0, 2000));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('2 of 5: Not great'));
      await tester.pump();
      await reveal(tester, sendButton());
      expect(button().onPressed, isNotNull);
    });

    testWidgets('opens the email app with the feedback filled in', (
      tester,
    ) async {
      Uri? sent;
      await pumpFeedback(tester, (uri) async {
        sent = uri;
        return true;
      });
      await fillIn(tester);
      await send(tester);

      expect(sent, isNotNull);
      expect(sent!.scheme, 'mailto');
      expect(sent!.path, feedbackEmail);
      final query = sent!.query;
      expect(query, isNot(contains('+')), reason: 'spaces encoded as %20');
      final subject = Uri.decodeComponent(
        RegExp(r'subject=([^&]*)').firstMatch(query)!.group(1)!,
      );
      final body = Uri.decodeComponent(
        RegExp(r'body=([^&]*)').firstMatch(query)!.group(1)!,
      );
      expect(subject, 'Upwiq feedback · Idea · 4/5');
      expect(body, startsWith('Please add a lesson on gaps & weekends.'));
      expect(body, contains('Rating: 4/5 (Good)'));
      expect(body, contains('App: Upwiq $appVersion'));
      expect(body, contains('League: Bronze'));
      // Back on the previous screen with a thank-you note.
      expect(find.text('open'), findsOneWidget);
      expect(find.textContaining('Thank you'), findsOneWidget);
    });

    testWidgets('app details can be left out', (tester) async {
      Uri? sent;
      await pumpFeedback(tester, (uri) async {
        sent = uri;
        return true;
      });
      await fillIn(tester);
      final toggle = find.text('Include app details');
      await reveal(tester, toggle);
      await tester.tap(toggle);
      await tester.pump();
      await send(tester);
      final body = Uri.decodeComponent(sent!.query);
      expect(body, isNot(contains('App: Upwiq')));
      expect(body, isNot(contains('League:')));
    });

    testWidgets('without an email app the feedback is copied', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpFeedback(tester, (_) async => false);
      await fillIn(tester);
      await send(tester);
      expect(find.text('No email app found'), findsOneWidget);
      expect(copied, contains('gaps & weekends'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        find.byType(FeedbackScreen),
        findsOneWidget,
        reason: 'stays on the form so nothing is lost',
      );
      expect(
        find.text('Please add a lesson on gaps & weekends.'),
        findsOneWidget,
      );
    });

    for (final scale in const [1.0, 1.3]) {
      testWidgets('form fits a 320dp phone at ${(scale * 100).round()}% '
          'text', (tester) async {
        phone(tester);
        await pumpFeedback(tester, (_) async => true, scale: scale);
        await fillIn(tester);
        await reveal(tester, sendButton());
        expect(tester.takeException(), isNull);
      });
    }
  });
}
