import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sim/market_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_academy/game/game_scope.dart';
import 'package:trading_academy/game/game_store.dart';
import 'package:trading_academy/game/league_screen.dart';
import 'package:trading_academy/game/market_picker_screen.dart';
import 'package:trading_academy/game/trading_session_screen.dart';
import 'package:trading_academy/theme/app_theme.dart';

import 'support/fonts.dart';

/// The League screens must fit on small phones (320dp wide) and with larger
/// system text sizes: no wrapped button labels, no overflowing rows.
void main() {
  setUpAll(loadAppFonts);

  const sizes = [(320.0, 640.0), (360.0, 740.0), (393.0, 851.0)];
  const scales = [1.0, 1.3];

  Future<GameStore> store() async {
    SharedPreferences.setMockInitialValues({});
    GameStore.reset();
    return GameStore.load(clock: () => DateTime(2026, 9, 30, 10));
  }

  Future<void> pumpAt(
    WidgetTester tester,
    (double, double) size,
    double scale,
    GameStore game,
    Widget home,
  ) async {
    tester.view.physicalSize = Size(size.$1 * 3, size.$2 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GameScope(
        store: game,
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: home,
        ),
      ),
    );
    await tester.pump();
  }

  void expectSingleLine(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    final lines = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: label.length),
        )
        .map((box) => box.top.round())
        .toSet();
    expect(
      lines,
      hasLength(1),
      reason: '"$label" wrapped onto more than one line',
    );
  }

  for (final size in sizes) {
    for (final scale in scales) {
      final name = '${size.$1.toInt()}dp, text ×$scale';

      testWidgets('order ticket fits at $name', (tester) async {
        await pumpAt(
          tester,
          size,
          scale,
          await store(),
          const TradingSessionScreen(
            market: GameMarkets.eurUsd,
            dayNumber: 272,
            ranked: true,
            startingBalance: 10000,
          ),
        );
        for (final label in [
          'Buy',
          'Sell',
          'Mkt',
          'Limit',
          'Stop',
          '0.5%',
          '1%',
          '2%',
        ]) {
          expectSingleLine(tester, label);
        }
        expect(tester.takeException(), isNull, reason: 'layout overflow');
      });

      testWidgets('open position panel fits at $name', (tester) async {
        await pumpAt(
          tester,
          size,
          scale,
          await store(),
          const TradingSessionScreen(
            market: GameMarkets.gold,
            dayNumber: 272,
            ranked: false,
            startingBalance: 10000,
            tick: Duration(milliseconds: 10),
          ),
        );
        await tester.tap(find.byTooltip('Play'));
        await tester.pump(const Duration(milliseconds: 35));
        await tester.tap(find.byTooltip('Pause'));
        await tester.pump();
        final buy = find.textContaining(RegExp(r'^BUY [0-9.]+ @'));
        await tester.ensureVisible(buy);
        await tester.tap(buy);
        await tester.pump();
        expect(find.text('Floating P&L'), findsOneWidget);
        await tester.ensureVisible(find.text('Break-even'));
        expectSingleLine(tester, 'Break-even');
        expect(tester.takeException(), isNull, reason: 'layout overflow');
      });

      testWidgets('league tab and market picker fit at $name', (tester) async {
        final game = await store();
        await pumpAt(
          tester,
          size,
          scale,
          game,
          const Scaffold(body: LeagueScreen()),
        );
        expect(tester.takeException(), isNull, reason: 'league tab overflow');
        await pumpAt(
          tester,
          size,
          scale,
          game,
          const MarketPickerScreen(ranked: true),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'market picker overflow',
        );
      });
    }
  }
}
