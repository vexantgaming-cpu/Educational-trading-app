part of 'lesson_art.dart';

/// Level 2, Risk Management: the numbers made visible.
extension _RiskScenes on LessonArtPainter {
  void _beginnerMistakes(Canvas c) {
    _glow(c, const Offset(150, 70), 90, palette.down);
    const xs = [56.0, 150.0, 244.0];
    const names = ['No stop-loss', 'Too big', 'Chasing losses'];
    for (var i = 0; i < 3; i++) {
      _card(
        c,
        Rect.fromCenter(center: Offset(xs[i], 62), width: 80, height: 76),
        radius: 16,
      );
      _label(
        c,
        names[i],
        Offset(xs[i], 118),
        palette.text,
        size: 10,
        spacing: 0,
        weight: FontWeight.w600,
      );
      _dot(c, Offset(xs[i] + 30, 32), 9, palette.down);
      _cross(c, Offset(xs[i] + 30, 32), 3.5, Colors.white, 2.2);
    }
    // A shield with a gap: no protection.
    final shield = Path()
      ..moveTo(56, 40)
      ..lineTo(76, 48)
      ..lineTo(76, 64)
      ..quadraticBezierTo(75, 80, 56, 90)
      ..quadraticBezierTo(37, 80, 36, 64)
      ..lineTo(36, 48)
      ..close();
    c.drawPath(shield, _stroke(palette.textMuted, 3));
    c.drawLine(
      const Offset(40, 86),
      const Offset(74, 42),
      _stroke(palette.down, 3.5),
    );
    // One oversized position.
    _coin(c, const Offset(150, 64), 24);
    _coin(c, const Offset(124, 82), 7);
    // Going round in circles after a loss.
    final loop = _stroke(palette.down, 4);
    c.drawArc(
      Rect.fromCircle(center: const Offset(244, 64), radius: 18),
      -0.4,
      5.2,
      false,
      loop,
    );
    final end =
        const Offset(244, 64) + Offset(18 * math.cos(4.8), 18 * math.sin(4.8));
    _arrowHead(c, end, 4.8 + math.pi / 2, 8, loop);
  }

  void _onePercent(Canvas c) {
    _glow(c, const Offset(200, 40), 85, palette.up);
    const left = 40.0, right = 240.0, top = 28.0, bottom = 120.0;
    double y(double pct) => bottom - (bottom - top) * pct / 100;
    c.drawLine(
      const Offset(left, bottom),
      const Offset(right, bottom),
      _stroke(palette.outline, 2),
    );
    _dashed(
      c,
      Offset(left, y(100)),
      Offset(right, y(100)),
      palette.outline,
      1.5,
    );
    for (final (risk, color) in [(0.01, palette.up), (0.10, palette.down)]) {
      final pts = [
        for (var k = 0; k <= 10; k++)
          Offset(
            left + (right - left) * k / 10,
            y(100 * math.pow(1 - risk, k).toDouble()),
          ),
      ];
      c.drawPath(_polyline(pts), _stroke(color, 3.5));
      for (final p in pts.skip(1)) {
        c.drawCircle(p, 2.4, Paint()..color = color);
      }
    }
    _label(c, '90%', Offset(264, y(90.4)), palette.up, size: 12, spacing: 0);
    _label(c, '35%', Offset(264, y(34.9)), palette.down, size: 12, spacing: 0);
    _chip(
      c,
      const Offset(86, 14),
      'RISK 1%',
      palette.up,
      size: 8.5,
      filled: true,
    );
    _chip(
      c,
      const Offset(158, 14),
      'RISK 10%',
      palette.down,
      size: 8.5,
      filled: true,
    );
    _label(
      c,
      'ACCOUNT AFTER 10 LOSSES IN A ROW',
      const Offset(140, 134),
      palette.textMuted,
      size: 8,
    );
  }

  void _stopPlacement(Canvas c) {
    _glow(c, const Offset(140, 96), 85, palette.cyan);
    const zone = Rect.fromLTRB(20, 88, 236, 100);
    c.drawRRect(
      RRect.fromRectAndRadius(zone, const Radius.circular(4)),
      Paint()..color = palette.cyan.withValues(alpha: 0.25),
    );
    _label(c, 'SUPPORT', const Offset(40, 80), palette.cyan, size: 8);
    const candles = [
      (60.0, 46.0, 58.0, 42.0, 62.0),
      (80.0, 58.0, 70.0, 54.0, 74.0),
      (100.0, 70.0, 82.0, 66.0, 90.0),
      (120.0, 82.0, 90.0, 78.0, 104.0),
      (140.0, 90.0, 78.0, 74.0, 95.0),
      (160.0, 78.0, 66.0, 62.0, 82.0),
      (180.0, 66.0, 56.0, 50.0, 70.0),
    ];
    for (final (x, o, cl, h, l) in candles) {
      _candle(c, x, o, cl, h, l, width: 12);
    }
    // Too tight: inside the zone, hit by a normal wiggle.
    _dashed(
      c,
      const Offset(20, 96),
      const Offset(236, 96),
      palette.down.withValues(alpha: 0.45),
      1.5,
    );
    _cross(c, const Offset(252, 96), 4, palette.down, 2.2);
    _label(
      c,
      'too tight',
      const Offset(278, 96),
      palette.textMuted,
      size: 8,
      spacing: 0,
      weight: FontWeight.w600,
    );
    // Beyond the zone.
    c.drawLine(
      const Offset(20, 116),
      const Offset(236, 116),
      _stroke(palette.down, 3),
    );
    _tick(c, const Offset(252, 116), 4.5, palette.up, 2.4);
    _label(c, 'STOP', const Offset(278, 116), palette.down, size: 9);
    _label(
      c,
      'normal wiggles stay above it',
      const Offset(128, 134),
      palette.textMuted,
      size: 8.5,
      spacing: 0,
      weight: FontWeight.w600,
    );
  }

  void _rewardRisk(Canvas c) {
    _glow(c, const Offset(140, 56), 85, palette.up);
    const entry = 92.0, stop = 120.0, target = 36.0;
    c.drawRect(
      const Rect.fromLTRB(70, target, 210, entry),
      Paint()..color = palette.up.withValues(alpha: 0.2),
    );
    c.drawRect(
      const Rect.fromLTRB(70, entry, 210, stop),
      Paint()..color = palette.down.withValues(alpha: 0.2),
    );
    c.drawLine(
      const Offset(70, target),
      const Offset(210, target),
      _stroke(palette.up, 3),
    );
    c.drawLine(
      const Offset(70, stop),
      const Offset(210, stop),
      _stroke(palette.down, 3),
    );
    _dashed(
      c,
      const Offset(40, entry),
      const Offset(240, entry),
      palette.textMuted,
      2,
    );
    _label(c, 'REWARD 2R', const Offset(140, 64), palette.up, size: 11);
    _label(c, 'RISK 1R', const Offset(140, 106), palette.down, size: 9);
    _chip(
      c,
      const Offset(254, target),
      'TARGET',
      palette.up,
      size: 8,
      filled: true,
    );
    _chip(c, const Offset(266, entry), 'ENTRY', palette.textMuted, size: 8);
    _chip(
      c,
      const Offset(254, stop),
      'STOP',
      palette.down,
      size: 8,
      filled: true,
    );
    _chip(
      c,
      const Offset(36, 20),
      '2 : 1',
      palette.gold,
      size: 9,
      filled: true,
    );
  }

  void _expectancy(Canvas c) {
    _glow(c, const Offset(150, 80), 90, AppColors.gradientGold);
    const base = 116.0;
    const bars = [
      (70.0, 50.0, '1:1'),
      (150.0, 33.3, '2:1'),
      (230.0, 25.0, '3:1'),
    ];
    for (final (x, pct, rr) in bars) {
      final h = pct * 1.4;
      final rect = Rect.fromLTRB(x - 20, base - h, x + 20, base);
      c.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
        ),
        _gradFill([_lighten(palette.cyan, 0.2), palette.cyan], rect),
      );
      _label(
        c,
        '${pct.round()}%',
        Offset(x, base - h - 11),
        palette.text,
        size: 12,
        spacing: 0,
      );
      _chip(c, Offset(x, base + 14), rr, palette.gold, size: 8.5);
    }
    c.drawLine(
      const Offset(36, base),
      const Offset(264, base),
      _stroke(palette.outline, 2),
    );
    _label(
      c,
      'WIN RATE NEEDED TO BREAK EVEN',
      const Offset(150, 12),
      palette.textMuted,
      size: 8,
    );
  }

  void _positionSize(Canvas c) {
    _glow(c, const Offset(150, 64), 90, AppColors.gradientGold);
    void token(double x, String value, String caption, Color color) {
      _card(
        c,
        Rect.fromCenter(center: Offset(x, 64), width: 72, height: 64),
        radius: 16,
      );
      _label(c, value, Offset(x, 58), color, size: 17, spacing: 0);
      _label(c, caption, Offset(x, 80), palette.textMuted, size: 7.5);
    }

    token(50, '\$100', 'YOU RISK', palette.gold);
    token(150, '\$2', 'STOP DISTANCE', palette.down);
    token(250, '50', 'SHARES', palette.up);
    _label(c, '÷', const Offset(100, 64), palette.text, size: 18, spacing: 0);
    _label(c, '=', const Offset(200, 64), palette.text, size: 18, spacing: 0);
    _label(
      c,
      'size = money at risk ÷ stop distance',
      const Offset(150, 122),
      palette.textMuted,
      size: 9,
      spacing: 0,
      weight: FontWeight.w600,
    );
  }

  void _marginLevel(Canvas c) {
    _glow(c, const Offset(110, 96), 85, palette.orange);
    const center = Offset(150, 112);
    final dial = Rect.fromCircle(center: center, radius: 74);
    double angle(double pct) => math.pi + math.pi * (pct / 200).clamp(0, 1);
    Paint arc(Color color) => _stroke(color, 14)..strokeCap = StrokeCap.butt;
    c.drawArc(dial, angle(0), angle(50) - angle(0), false, arc(palette.down));
    c.drawArc(
      dial,
      angle(50),
      angle(100) - angle(50),
      false,
      arc(palette.orange),
    );
    c.drawArc(
      dial,
      angle(100),
      angle(200) - angle(100),
      false,
      arc(palette.up),
    );
    final a = angle(70);
    final tip = center + Offset(60 * math.cos(a), 60 * math.sin(a));
    final normal = Offset(-math.sin(a), math.cos(a)) * 5;
    c.drawPath(
      Path()
        ..moveTo(center.dx + normal.dx, center.dy + normal.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(center.dx - normal.dx, center.dy - normal.dy)
        ..close(),
      Paint()..color = palette.text,
    );
    _dot(c, center, 8, palette.text);
    final mark = angle(50);
    _label(
      c,
      '50%',
      center + Offset(96 * math.cos(mark), 96 * math.sin(mark)),
      palette.down,
      size: 10,
      spacing: 0,
    );
    _label(c, 'CLOSED', const Offset(52, 132), palette.down, size: 8.5);
    _label(c, 'SAFE', const Offset(248, 132), palette.up, size: 8.5);
    _label(
      c,
      'MARGIN LEVEL',
      const Offset(150, 136),
      palette.textMuted,
      size: 8,
    );
  }

  void _drawdown(Canvas c) {
    _glow(c, const Offset(230, 60), 85, palette.up);
    const base = 96.0;
    const groups = [
      (70.0, 10.0, 11.1),
      (150.0, 25.0, 33.3),
      (230.0, 50.0, 100.0),
    ];
    c.drawLine(
      const Offset(30, base),
      const Offset(270, base),
      _stroke(palette.outline, 2),
    );
    for (final (x, loss, gain) in groups) {
      final down = Rect.fromLTRB(x - 20, base, x - 3, base + loss * 0.8);
      final up = Rect.fromLTRB(x + 3, base - gain * 0.62, x + 20, base);
      c.drawRRect(
        RRect.fromRectAndRadius(down, const Radius.circular(4)),
        Paint()..color = palette.down,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(up, const Radius.circular(4)),
        Paint()..color = palette.up,
      );
      _label(
        c,
        '−${loss.round()}%',
        Offset(x - 11, down.bottom + 9),
        palette.down,
        size: 9,
        spacing: 0,
      );
      _label(
        c,
        '+${gain.round()}%',
        Offset(x + 12, up.top - 9),
        palette.up,
        size: 9,
        spacing: 0,
      );
    }
    _chip(c, const Offset(36, 18), 'LOSS', palette.down, size: 8, filled: true);
    _chip(
      c,
      const Offset(140, 18),
      'GAIN NEEDED TO RECOVER',
      palette.up,
      size: 8,
      filled: true,
    );
  }

  void _tradingCosts(Canvas c) {
    _glow(c, const Offset(150, 64), 90, palette.orange);
    const xs = [56.0, 150.0, 244.0];
    const names = ['Spread', 'Commission', 'Slippage'];
    for (var i = 0; i < 3; i++) {
      _card(
        c,
        Rect.fromCenter(center: Offset(xs[i], 62), width: 80, height: 76),
        radius: 16,
      );
      _label(
        c,
        names[i],
        Offset(xs[i], 118),
        palette.text,
        size: 10,
        spacing: 0,
        weight: FontWeight.w600,
      );
    }
    // Spread: two prices with a gap.
    c.drawLine(
      const Offset(30, 50),
      const Offset(82, 50),
      _stroke(palette.up, 3),
    );
    c.drawLine(
      const Offset(30, 74),
      const Offset(82, 74),
      _stroke(palette.down, 3),
    );
    c.drawRect(
      const Rect.fromLTRB(30, 52, 82, 72),
      Paint()..color = palette.gold.withValues(alpha: 0.2),
    );
    // Commission: a fee per trade.
    _coin(c, const Offset(150, 62), 18);
    _chip(c, const Offset(170, 40), '%', palette.orange, size: 9, filled: true);
    // Slippage: filled further than planned.
    _dashed(c, const Offset(218, 48), const Offset(270, 48), palette.down, 2);
    _arrow(
      c,
      const Offset(232, 40),
      const Offset(256, 82),
      _stroke(palette.textMuted, 3),
      head: 7,
    );
    _dot(c, const Offset(256, 82), 4.5, palette.down);
  }

  void _slippage(Canvas c) {
    _glow(c, const Offset(196, 96), 80, palette.down);
    const stop = 70.0, fill = 98.0;
    const before = [
      (40.0, 46.0, 40.0, 34.0, 52.0),
      (60.0, 40.0, 48.0, 36.0, 52.0),
      (80.0, 48.0, 44.0, 40.0, 54.0),
      (100.0, 44.0, 52.0, 40.0, 58.0),
      (120.0, 52.0, 56.0, 46.0, 62.0),
      (140.0, 56.0, 60.0, 52.0, 64.0),
    ];
    for (final (x, o, cl, h, l) in before) {
      _candle(c, x, o, cl, h, l, width: 12);
    }
    // Opens far below the stop: the gap.
    _candle(c, 172, fill, 118, 92, 124, width: 14, color: palette.down);
    _dashed(
      c,
      const Offset(20, stop),
      const Offset(230, stop),
      palette.down,
      2.5,
    );
    _chip(c, const Offset(262, stop), 'YOUR STOP', palette.down, size: 8);
    _dot(c, const Offset(172, fill), 5, palette.gold);
    _chip(
      c,
      const Offset(262, fill),
      'FILLED',
      palette.gold,
      size: 8,
      filled: true,
    );
    final gap = _stroke(palette.gold, 2);
    _arrow(
      c,
      const Offset(204, stop + 3),
      const Offset(204, fill - 3),
      gap,
      head: 5,
    );
    _label(
      c,
      'slippage',
      const Offset(150, 132),
      palette.gold,
      size: 9,
      spacing: 0,
    );
    _label(
      c,
      'price gapped past the stop',
      const Offset(84, 100),
      palette.textMuted,
      size: 8.5,
      spacing: 0,
      weight: FontWeight.w600,
    );
  }
}
