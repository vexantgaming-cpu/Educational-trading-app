part of 'lesson_art.dart';

/// Level 0, Market Foundations.
extension _FoundationScenes on LessonArtPainter {
  void _person(Canvas c, Offset feet, double h, Color color) {
    final paint = _gradFill([
      _lighten(color, 0.2),
      color,
    ], Rect.fromLTWH(feet.dx - h / 2, feet.dy - h, h, h));
    c.drawCircle(feet + Offset(0, -h * 0.78), h * 0.2, paint);
    c.drawRRect(
      RRect.fromLTRBAndCorners(
        feet.dx - h * 0.3,
        feet.dy - h * 0.52,
        feet.dx + h * 0.3,
        feet.dy,
        topLeft: Radius.circular(h * 0.3),
        topRight: Radius.circular(h * 0.3),
        bottomLeft: Radius.circular(h * 0.06),
        bottomRight: Radius.circular(h * 0.06),
      ),
      paint,
    );
  }

  void _buyersSellers(Canvas c) {
    _glow(c, const Offset(150, 72), 80, AppColors.gradientGold);
    for (final (i, x) in const [26.0, 50.0, 74.0].indexed) {
      _person(c, Offset(x, 96.0 - (i == 1 ? 6 : 0)), 40, palette.up);
    }
    for (final (i, x) in const [226.0, 250.0, 274.0].indexed) {
      _person(c, Offset(x, 96.0 - (i == 1 ? 6 : 0)), 40, palette.down);
    }
    _arrow(
      c,
      const Offset(92, 72),
      const Offset(112, 72),
      _stroke(palette.up, 4),
      head: 7,
    );
    _arrow(
      c,
      const Offset(208, 72),
      const Offset(188, 72),
      _stroke(palette.down, 4),
      head: 7,
    );
    // The agreed price.
    final tag = RRect.fromLTRBR(120, 54, 180, 90, const Radius.circular(12));
    c.drawRRect(tag, _gradFill(_brand, tag.outerRect));
    _label(c, 'PRICE', const Offset(150, 64), AppColors.onGold, size: 8);
    _label(
      c,
      '\$50',
      const Offset(150, 78),
      AppColors.onGold,
      size: 14,
      spacing: 0,
    );
    _label(c, 'BUYERS', const Offset(50, 116), palette.up, size: 9);
    _label(c, 'SELLERS', const Offset(250, 116), palette.down, size: 9);
  }

  void _otherSide(Canvas c) {
    _glow(c, const Offset(150, 62), 80, AppColors.gradientGold);
    _card(c, const Rect.fromLTRB(20, 38, 104, 86));
    _card(c, const Rect.fromLTRB(196, 38, 280, 86));
    _label(c, 'BUY', const Offset(62, 54), palette.up, size: 11);
    _label(
      c,
      '10 shares',
      const Offset(62, 72),
      palette.text,
      size: 10,
      spacing: 0,
      weight: FontWeight.w600,
    );
    _label(c, 'SELL', const Offset(238, 54), palette.down, size: 11);
    _label(
      c,
      '10 shares',
      const Offset(238, 72),
      palette.text,
      size: 10,
      spacing: 0,
      weight: FontWeight.w600,
    );
    final link = _stroke(palette.textMuted.withValues(alpha: 0.7), 3);
    _arrow(c, const Offset(108, 62), const Offset(124, 62), link, head: 6);
    _arrow(c, const Offset(192, 62), const Offset(176, 62), link, head: 6);
    _dot(c, const Offset(150, 62), 22, AppColors.gradientGold, gradient: true);
    _tick(c, const Offset(150, 62), 9, AppColors.onGold, 4);
    _chip(c, const Offset(150, 114), 'ONE TRADE AT \$50', palette.gold);
  }

  void _bidAsk(Canvas c) {
    _glow(c, const Offset(150, 75), 85, AppColors.gradientGold);
    const askY = 50.0, bidY = 100.0;
    c.drawRect(
      const Rect.fromLTRB(70, askY, 222, bidY),
      Paint()..color = palette.gold.withValues(alpha: 0.12),
    );
    c.drawLine(
      const Offset(70, askY),
      const Offset(222, askY),
      _stroke(palette.up, 3),
    );
    c.drawLine(
      const Offset(70, bidY),
      const Offset(222, bidY),
      _stroke(palette.down, 3),
    );
    _chip(c, const Offset(46, askY), 'ASK', palette.up, filled: true);
    _chip(c, const Offset(46, bidY), 'BID', palette.down, filled: true);
    _label(
      c,
      '1.08510',
      const Offset(256, askY),
      palette.text,
      size: 12,
      spacing: 0,
    );
    _label(
      c,
      '1.08500',
      const Offset(256, bidY),
      palette.text,
      size: 12,
      spacing: 0,
    );
    _label(
      c,
      'you buy here',
      const Offset(146, askY - 12),
      palette.textMuted,
      size: 9,
      spacing: 0,
      weight: FontWeight.w600,
    );
    _label(
      c,
      'you sell here',
      const Offset(146, bidY + 12),
      palette.textMuted,
      size: 9,
      spacing: 0,
      weight: FontWeight.w600,
    );
    final gap = _stroke(palette.gold, 2.5);
    _arrow(c, const Offset(196, 75), const Offset(196, askY + 5), gap, head: 6);
    _arrow(c, const Offset(196, 75), const Offset(196, bidY - 5), gap, head: 6);
    _label(c, 'SPREAD', const Offset(146, 75), palette.gold, size: 11);
  }

  void _spreadCost(Canvas c) {
    _glow(c, const Offset(150, 74), 85, palette.down);
    _card(c, const Rect.fromLTRB(56, 20, 244, 130), radius: 18);
    _label(
      c,
      'EUR/USD · LONG 1 LOT',
      const Offset(150, 38),
      palette.textMuted,
      size: 9,
    );
    _label(
      c,
      'Open profit / loss',
      const Offset(150, 58),
      palette.text,
      size: 10,
      spacing: 0,
      weight: FontWeight.w600,
    );
    _label(
      c,
      '−\$10.00',
      const Offset(150, 84),
      palette.down,
      size: 24,
      spacing: 0,
    );
    _chip(
      c,
      const Offset(150, 112),
      'THE SPREAD, PAID ON ENTRY',
      palette.gold,
      size: 8.5,
    );
  }

  void _spreadWiden(Canvas c) {
    _glow(c, const Offset(160, 70), 80, palette.orange);
    double ask(double x) {
      final d = (x - 160) / 28;
      return 62 - 30 * math.exp(-d * d);
    }

    double bid(double x) {
      final d = (x - 160) / 28;
      return 74 + 30 * math.exp(-d * d);
    }

    final top = <Offset>[], bottom = <Offset>[];
    for (var x = 40.0; x <= 280; x += 4) {
      top.add(Offset(x, ask(x)));
      bottom.add(Offset(x, bid(x)));
    }
    final band = _polyline([...top, ...bottom.reversed])..close();
    c.drawPath(band, Paint()..color = palette.gold.withValues(alpha: 0.16));
    c.drawPath(_polyline(top), _stroke(palette.up, 3));
    c.drawPath(_polyline(bottom), _stroke(palette.down, 3));
    _label(c, 'ASK', const Offset(24, 62), palette.up, size: 9);
    _label(c, 'BID', const Offset(24, 74), palette.down, size: 9);
    // Lightning bolt: the news.
    final bolt = Path()
      ..moveTo(164, 6)
      ..lineTo(150, 24)
      ..lineTo(160, 24)
      ..lineTo(154, 40)
      ..lineTo(172, 18)
      ..lineTo(162, 18)
      ..close();
    c.drawPath(bolt, _gradFill(_brand, const Rect.fromLTRB(150, 6, 172, 40)));
    _chip(c, const Offset(222, 22), 'BIG NEWS', palette.orange, size: 8.5);
    _label(
      c,
      'normal',
      const Offset(80, 116),
      palette.textMuted,
      size: 9,
      spacing: 0,
      weight: FontWeight.w600,
    );
    _label(
      c,
      'wide',
      const Offset(160, 116),
      palette.gold,
      size: 9,
      spacing: 0,
    );
    _label(
      c,
      'normal',
      const Offset(240, 116),
      palette.textMuted,
      size: 9,
      spacing: 0,
      weight: FontWeight.w600,
    );
  }

  void _marketFamilies(Canvas c) {
    _glow(c, const Offset(150, 64), 90, AppColors.gradientGold);
    const xs = [34.0, 92.0, 150.0, 208.0, 266.0];
    const names = ['Stocks', 'Forex', 'Crypto', 'Commodities', 'Indices'];
    for (var i = 0; i < 5; i++) {
      _card(
        c,
        Rect.fromCenter(center: Offset(xs[i], 62), width: 50, height: 56),
      );
      _label(
        c,
        names[i],
        Offset(xs[i], 108),
        palette.text,
        size: 8.5,
        spacing: 0,
        weight: FontWeight.w600,
      );
    }
    // Stocks: an exchange building.
    final cyan = palette.cyan;
    final roof = Path()
      ..moveTo(20, 54)
      ..lineTo(34, 44)
      ..lineTo(48, 54)
      ..close();
    c.drawPath(roof, Paint()..color = cyan);
    for (final x in const [24.0, 31.0, 38.0, 45.0]) {
      c.drawRect(Rect.fromLTWH(x - 1.6, 56, 3.2, 14), Paint()..color = cyan);
    }
    c.drawRect(const Rect.fromLTRB(19, 72, 49, 76), Paint()..color = cyan);
    // Forex: two currencies.
    _dot(c, const Offset(86, 58), 11, palette.up, gradient: true);
    _dot(c, const Offset(98, 68), 11, AppColors.gradientGold, gradient: true);
    _label(c, '€', const Offset(86, 58), Colors.white, size: 12, spacing: 0);
    _label(
      c,
      '\$',
      const Offset(98, 68),
      AppColors.onGold,
      size: 12,
      spacing: 0,
    );
    // Crypto: a coin with a B.
    _dot(c, const Offset(150, 62), 15, palette.orange, gradient: true);
    _label(c, 'B', const Offset(151, 62), Colors.white, size: 15, spacing: 0);
    final bars = _stroke(Colors.white, 2);
    c.drawLine(const Offset(148, 50), const Offset(148, 54), bars);
    c.drawLine(const Offset(153, 50), const Offset(153, 54), bars);
    c.drawLine(const Offset(148, 70), const Offset(148, 74), bars);
    c.drawLine(const Offset(153, 70), const Offset(153, 74), bars);
    // Commodities: a gold bar and a drop of oil.
    final bar = Path()
      ..moveTo(194, 74)
      ..lineTo(198, 62)
      ..lineTo(214, 62)
      ..lineTo(218, 74)
      ..close();
    c.drawPath(bar, _gradFill(_brand, const Rect.fromLTRB(194, 62, 218, 74)));
    final drop = Path()
      ..moveTo(214, 42)
      ..quadraticBezierTo(222, 52, 222, 55)
      ..arcToPoint(const Offset(206, 55), radius: const Radius.circular(8))
      ..quadraticBezierTo(206, 52, 214, 42)
      ..close();
    c.drawPath(drop, Paint()..color = palette.textMuted);
    // Indices: a basket of stocks moving together.
    for (final (i, h) in const [10.0, 16.0, 22.0].indexed) {
      final x = 256.0 + i * 10;
      c.drawRRect(
        RRect.fromLTRBR(x - 3.5, 76 - h, x + 3.5, 76, const Radius.circular(2)),
        Paint()..color = palette.up.withValues(alpha: 0.85),
      );
    }
    c.drawPath(
      _polyline(const [Offset(252, 58), Offset(262, 52), Offset(280, 44)]),
      _stroke(palette.gold, 2.5),
    );
  }

  void _tradingHours(Canvas c) {
    _glow(c, const Offset(150, 64), 90, palette.cyan);
    void dial(
      Offset center,
      double fromHour,
      double hours,
      List<Color> colors,
    ) {
      final rect = Rect.fromCircle(center: center, radius: 30);
      c.drawCircle(center, 30, _stroke(palette.surfaceHighest, 9));
      final start = fromHour / 24 * 2 * math.pi - math.pi / 2;
      final sweep = hours / 24 * 2 * math.pi;
      c.drawArc(
        rect,
        start,
        sweep,
        false,
        _gradStroke(colors, rect, 9)..strokeCap = StrokeCap.butt,
      );
    }

    dial(const Offset(60, 60), 9.5, 6.5, [palette.cyan, palette.cyan]);
    dial(const Offset(150, 60), 0, 24, [palette.up, palette.up]);
    dial(const Offset(240, 60), 0, 24, _brand);
    _label(c, '9:30', const Offset(60, 56), palette.text, size: 10, spacing: 0);
    _label(
      c,
      '16:00',
      const Offset(60, 68),
      palette.textMuted,
      size: 8,
      spacing: 0,
    );
    _label(c, '24h', const Offset(150, 60), palette.text, size: 12, spacing: 0);
    _label(
      c,
      '24/7',
      const Offset(240, 60),
      palette.text,
      size: 12,
      spacing: 0,
    );
    _label(
      c,
      'Stocks',
      const Offset(60, 106),
      palette.text,
      size: 10,
      spacing: 0,
      weight: FontWeight.w600,
    );
    _label(
      c,
      'Forex',
      const Offset(150, 106),
      palette.text,
      size: 10,
      spacing: 0,
      weight: FontWeight.w600,
    );
    _label(
      c,
      'Crypto',
      const Offset(240, 106),
      palette.text,
      size: 10,
      spacing: 0,
      weight: FontWeight.w600,
    );
    _label(c, 'MON–FRI', const Offset(60, 122), palette.textMuted, size: 8);
    _label(c, 'MON–FRI', const Offset(150, 122), palette.textMuted, size: 8);
    _label(c, 'EVERY DAY', const Offset(240, 122), palette.textMuted, size: 8);
  }

  void _leverage(Canvas c) {
    _glow(c, const Offset(110, 70), 90, palette.cyan);
    const pivot = Offset(112, 96);
    double plankY(double x) => pivot.dy + (x - pivot.dx) * 0.16;
    // Fulcrum.
    final fulcrum = Path()
      ..moveTo(pivot.dx, pivot.dy + 3)
      ..lineTo(pivot.dx + 16, 128)
      ..lineTo(pivot.dx - 16, 128)
      ..close();
    c.drawPath(fulcrum, Paint()..color = palette.textMuted);
    c.drawLine(
      Offset(30, plankY(30)),
      Offset(282, plankY(282)),
      _stroke(palette.text.withValues(alpha: 0.8), 5),
    );
    // The large position, lifted.
    final boxBottom = plankY(52) - 3;
    final box = Rect.fromLTRB(22, boxBottom - 52, 84, boxBottom);
    c.save();
    c.translate(53, boxBottom);
    c.rotate(math.atan(0.16));
    c.translate(-53, -boxBottom);
    c.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(10)),
      _gradFill([_lighten(palette.cyan, 0.2), palette.cyan], box),
    );
    _label(c, 'POSITION', Offset(53, boxBottom - 34), Colors.white, size: 8);
    _label(
      c,
      '\$30,000',
      Offset(53, boxBottom - 18),
      Colors.white,
      size: 12,
      spacing: 0,
    );
    c.restore();
    // The small deposit, pushing down.
    _coin(c, Offset(262, plankY(262) - 14), 13);
    _label(
      c,
      'DEPOSIT \$1,000',
      const Offset(232, 86),
      palette.gold,
      size: 8.5,
    );
    _chip(c, const Offset(158, 134), '30:1 LEVERAGE', palette.gold, size: 8.5);
  }

  void _longShort(Canvas c) {
    _glow(c, const Offset(150, 70), 90, AppColors.gradientGold);
    _card(c, const Rect.fromLTRB(16, 16, 144, 134), radius: 18);
    _card(c, const Rect.fromLTRB(156, 16, 284, 134), radius: 18);
    // Long: buy low, sell higher.
    final up = _stroke(palette.up, 4);
    c.drawPath(
      _polyline(const [
        Offset(34, 96),
        Offset(58, 84),
        Offset(72, 90),
        Offset(98, 64),
        Offset(110, 70),
        Offset(126, 46),
      ]),
      up,
    );
    _arrowHead(c, const Offset(126, 46), -0.98, 9, up);
    _chip(c, const Offset(40, 110), 'BUY', palette.up, size: 8.5, filled: true);
    _chip(c, const Offset(118, 30), 'SELL', palette.up, size: 8.5);
    _label(c, 'LONG', const Offset(84, 124), palette.up, size: 10);
    // Short: sell high, buy back lower.
    final down = _stroke(palette.down, 4);
    c.drawPath(
      _polyline(const [
        Offset(174, 46),
        Offset(198, 60),
        Offset(212, 54),
        Offset(238, 80),
        Offset(250, 74),
        Offset(266, 98),
      ]),
      down,
    );
    _arrowHead(c, const Offset(266, 98), 0.98, 9, down);
    _chip(
      c,
      const Offset(182, 30),
      'SELL',
      palette.down,
      size: 8.5,
      filled: true,
    );
    _chip(c, const Offset(260, 112), 'BUY', palette.down, size: 8.5);
    _label(c, 'SHORT', const Offset(220, 124), palette.down, size: 10);
  }

  void _marketOrder(Canvas c) {
    _glow(c, const Offset(214, 74), 80, AppColors.gradientGold);
    final line = _polyline(const [
      Offset(24, 84),
      Offset(52, 78),
      Offset(76, 88),
      Offset(104, 74),
      Offset(132, 80),
      Offset(160, 70),
      Offset(196, 76),
    ]);
    c.drawPath(line, _stroke(palette.textMuted, 3.5));
    c.drawCircle(
      const Offset(196, 76),
      12,
      Paint()..color = palette.gold.withValues(alpha: 0.25),
    );
    _dot(c, const Offset(196, 76), 6, AppColors.gradientGold, gradient: true);
    final bolt = Path()
      ..moveTo(236, 34)
      ..lineTo(222, 56)
      ..lineTo(232, 56)
      ..lineTo(226, 78)
      ..lineTo(246, 50)
      ..lineTo(236, 50)
      ..close();
    c.drawPath(bolt, _gradFill(_brand, const Rect.fromLTRB(222, 34, 246, 78)));
    _chip(c, const Offset(234, 104), 'FILLED NOW', palette.up, size: 9);
    _chip(
      c,
      const Offset(70, 40),
      'BUY AT MARKET',
      palette.gold,
      size: 9,
      filled: true,
    );
  }

  void _limitOrder(Canvas c) {
    _glow(c, const Offset(176, 98), 75, palette.cyan);
    const level = 100.0;
    _dashed(
      c,
      const Offset(20, level),
      const Offset(280, level),
      palette.cyan,
      2.5,
    );
    _chip(
      c,
      const Offset(246, level + 16),
      'BUY LIMIT',
      palette.cyan,
      size: 8.5,
      filled: true,
    );
    final price = _polyline(const [
      Offset(20, 44),
      Offset(48, 56),
      Offset(72, 46),
      Offset(104, 74),
      Offset(128, 66),
      Offset(152, 88),
      Offset(176, level),
      Offset(204, 78),
      Offset(232, 64),
      Offset(276, 50),
    ]);
    c.drawPath(price, _stroke(palette.textMuted, 3.5));
    _dot(c, const Offset(176, level), 10, palette.up);
    _tick(c, const Offset(176, level), 4.5, Colors.white, 2.6);
    _label(
      c,
      'waits for the dip',
      const Offset(94, 124),
      palette.textMuted,
      size: 9,
      spacing: 0,
      weight: FontWeight.w600,
    );
  }

  void _stopOrder(Canvas c) {
    _glow(c, const Offset(190, 40), 75, palette.up);
    const buyStop = 40.0, sellStop = 110.0;
    _dashed(
      c,
      const Offset(20, buyStop),
      const Offset(280, buyStop),
      palette.up,
      2.5,
    );
    _dashed(
      c,
      const Offset(20, sellStop),
      const Offset(280, sellStop),
      palette.down,
      2.5,
    );
    _chip(
      c,
      const Offset(52, buyStop - 14),
      'BUY STOP',
      palette.up,
      size: 8.5,
      filled: true,
    );
    _chip(
      c,
      const Offset(52, sellStop + 14),
      'SELL STOP',
      palette.down,
      size: 8.5,
      filled: true,
    );
    final price = _polyline(const [
      Offset(20, 80),
      Offset(44, 70),
      Offset(68, 86),
      Offset(96, 66),
      Offset(120, 82),
      Offset(148, 62),
      Offset(170, 70),
      Offset(190, buyStop),
      Offset(216, 30),
      Offset(240, 36),
      Offset(272, 18),
    ]);
    c.drawPath(price, _stroke(palette.textMuted, 3.5));
    // Triggered.
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      c.drawLine(
        Offset(190 + 9 * math.cos(a), buyStop + 9 * math.sin(a)),
        Offset(190 + 14 * math.cos(a), buyStop + 14 * math.sin(a)),
        _stroke(palette.up, 2),
      );
    }
    _dot(c, const Offset(190, buyStop), 5, palette.up);
    _label(
      c,
      'triggered',
      const Offset(224, 58),
      palette.up,
      size: 9,
      spacing: 0,
    );
  }

  void _candleColours(Canvas c) {
    _glow(c, const Offset(150, 72), 85, AppColors.gradientGold);
    _candle(c, 96, 102, 44, 32, 114, width: 30, color: palette.up);
    _candle(c, 204, 44, 102, 32, 114, width: 30, color: palette.down);
    void tag(Offset at, String text, Color color, {bool left = false}) {
      c.drawLine(at, at + Offset(left ? -10 : 10, 0), _stroke(color, 1.5));
      final tp = _textPainter(text, 9, FontWeight.w700, 0.8, color);
      tp.paint(c, at + Offset(left ? -14 - tp.width : 14, -tp.height / 2));
    }

    tag(const Offset(80, 44), 'CLOSE', palette.up, left: true);
    tag(const Offset(80, 102), 'OPEN', palette.textMuted, left: true);
    tag(const Offset(220, 44), 'OPEN', palette.textMuted);
    tag(const Offset(220, 102), 'CLOSE', palette.down);
    _label(
      c,
      'closed higher',
      const Offset(96, 132),
      palette.up,
      size: 9,
      spacing: 0,
    );
    _label(
      c,
      'closed lower',
      const Offset(204, 132),
      palette.down,
      size: 9,
      spacing: 0,
    );
  }

  void _candleShapes(Canvas c) {
    _glow(c, const Offset(150, 70), 90, AppColors.gradientGold);
    // One side in control.
    _candle(c, 60, 104, 34, 28, 110, width: 26, color: palette.up);
    // Pushed back from the lows.
    _candle(c, 150, 46, 36, 30, 110, width: 26, color: palette.up);
    // Undecided.
    _candle(c, 240, 70, 67, 34, 104, width: 26, color: palette.textMuted);
    _label(c, 'STRONG BODY', const Offset(60, 128), palette.text, size: 8.5);
    _label(c, 'LONG WICK', const Offset(150, 128), palette.text, size: 8.5);
    _label(c, 'TINY BODY', const Offset(240, 128), palette.text, size: 8.5);
    _arrow(
      c,
      const Offset(184, 100),
      const Offset(158, 106),
      _stroke(palette.orange, 2),
      head: 5,
    );
    _label(
      c,
      'pushed back',
      const Offset(194, 90),
      palette.orange,
      size: 8,
      spacing: 0,
    );
  }

  void _timeframeZoom(Canvas c) {
    _glow(c, const Offset(220, 72), 80, AppColors.gradientGold);
    // Four 1-hour candles...
    const smalls = [
      (64.0, 98.0, 80.0, 60.0, 104.0),
      (88.0, 80.0, 88.0, 70.0, 96.0),
      (112.0, 88.0, 58.0, 40.0, 92.0),
      (136.0, 58.0, 48.0, 36.0, 66.0),
    ];
    for (final (x, o, cl, h, l) in smalls) {
      _candle(c, x, o, cl, h, l, width: 14);
    }
    _label(
      c,
      '4 × 1-HOUR',
      const Offset(100, 126),
      palette.textMuted,
      size: 8.5,
    );
    final brace = _stroke(palette.textMuted.withValues(alpha: 0.6), 2);
    c.drawLine(const Offset(54, 114), const Offset(146, 114), brace);
    // ...make one 4-hour candle: first open, last close, highest high,
    // lowest low.
    _arrow(
      c,
      const Offset(164, 72),
      const Offset(190, 72),
      _stroke(palette.gold, 3),
      head: 7,
    );
    _candle(c, 230, 98, 48, 36, 104, width: 34, color: palette.up);
    _label(c, '1 × 4-HOUR', const Offset(230, 126), palette.gold, size: 8.5);
  }

  void _liquidity(Canvas c) {
    _glow(c, const Offset(80, 70), 80, palette.up);
    void book(double cx, List<double> sizes, String title, Color titleColor) {
      for (var i = 0; i < sizes.length; i++) {
        final y = 30.0 + i * 12;
        final w = sizes[i];
        final isAsk = i < sizes.length / 2;
        final color = (isAsk ? palette.down : palette.up).withValues(
          alpha: w == 0 ? 0 : 0.85,
        );
        c.drawRRect(
          RRect.fromLTRBR(
            cx - w / 2,
            y,
            cx + w / 2,
            y + 8,
            const Radius.circular(3),
          ),
          Paint()..color = color,
        );
      }
      c.drawLine(
        Offset(cx - 52, 77),
        Offset(cx + 52, 77),
        _stroke(palette.gold, 1.5),
      );
      _label(c, title, Offset(cx, 134), titleColor, size: 10);
    }

    book(80, const [70, 84, 78, 92, 96, 100, 88, 94], 'LIQUID', palette.up);
    book(220, const [18, 0, 34, 0, 0, 26, 0, 12], 'ILLIQUID', palette.orange);
    _label(
      c,
      'many orders at every price',
      const Offset(80, 22),
      palette.textMuted,
      size: 8,
      spacing: 0,
      weight: FontWeight.w600,
    );
    _label(
      c,
      'gaps between orders',
      const Offset(220, 22),
      palette.textMuted,
      size: 8,
      spacing: 0,
      weight: FontWeight.w600,
    );
  }
}
