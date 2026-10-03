part of 'lesson_art.dart';

/// Level 1, Market Structure: schematic price paths.
extension _StructureScenes on LessonArtPainter {
  void _trendStructure(Canvas c) {
    _glow(c, const Offset(200, 50), 90, palette.up);
    const pts = [
      Offset(22, 122),
      Offset(70, 78),
      Offset(100, 100),
      Offset(150, 56),
      Offset(180, 80),
      Offset(230, 34),
      Offset(256, 56),
      Offset(286, 22),
    ];
    // The rising lows, joined.
    _dashed(c, pts[2], pts[6], palette.cyan.withValues(alpha: 0.6), 2);
    final line = _gradStroke(_brand, const Rect.fromLTRB(22, 22, 286, 122), 4);
    c.drawPath(_polyline(pts.sublist(0, pts.length - 1)), line);
    _arrow(c, pts[pts.length - 2], pts.last, line, head: 9);
    for (final i in const [3, 5]) {
      _dot(c, pts[i], 5, palette.up);
      _chip(
        c,
        pts[i] - const Offset(0, 17),
        'HH',
        palette.up,
        size: 8.5,
        filled: true,
      );
    }
    for (final i in const [2, 4, 6]) {
      _dot(c, pts[i], 5, palette.cyan);
      _chip(
        c,
        pts[i] + const Offset(0, 17),
        'HL',
        palette.cyan,
        size: 8.5,
        filled: true,
      );
    }
    _label(
      c,
      'higher highs, higher lows',
      const Offset(96, 22),
      palette.textMuted,
      size: 9,
      spacing: 0,
      weight: FontWeight.w600,
    );
  }

  void _rangeBox(Canvas c) {
    _glow(c, const Offset(150, 75), 90, palette.cyan);
    const top = Rect.fromLTRB(24, 34, 276, 46);
    const bottom = Rect.fromLTRB(24, 104, 276, 116);
    c.drawRRect(
      RRect.fromRectAndRadius(top, const Radius.circular(4)),
      Paint()..color = palette.orange.withValues(alpha: 0.22),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(bottom, const Radius.circular(4)),
      Paint()..color = palette.cyan.withValues(alpha: 0.22),
    );
    c.drawPath(
      _polyline(const [
        Offset(24, 76),
        Offset(56, 40),
        Offset(88, 110),
        Offset(120, 42),
        Offset(152, 108),
        Offset(186, 38),
        Offset(218, 110),
        Offset(250, 44),
        Offset(276, 80),
      ]),
      _stroke(palette.textMuted, 3.5),
    );
    _label(
      c,
      'RESISTANCE: THE CEILING',
      const Offset(150, 20),
      palette.orange,
      size: 9,
    );
    _label(
      c,
      'SUPPORT: THE FLOOR',
      const Offset(150, 132),
      palette.cyan,
      size: 9,
    );
  }

  void _swingPoints(Canvas c) {
    _glow(c, const Offset(150, 75), 90, AppColors.gradientGold);
    double mid(int i) => 75 - 32 * math.cos((i - 5) * math.pi / 6);
    for (var i = 0; i < 17; i++) {
      final x = 30.0 + i * 15;
      final prev = mid(i - 1), now = mid(i);
      _candle(
        c,
        x,
        prev,
        now,
        math.min(prev, now) - 6,
        math.max(prev, now) + 6,
        width: 9,
      );
    }
    // Lower highs on both sides of the peak, higher lows around the trough.
    for (final i in const [2, 3, 4, 6, 7, 8]) {
      final y = math.min(mid(i - 1), mid(i)) - 6;
      c.drawCircle(
        Offset(30.0 + i * 15, y - 5),
        2,
        Paint()..color = palette.down.withValues(alpha: 0.6),
      );
    }
    final peakY = math.min(mid(4), mid(5)) - 6;
    final troughY = math.max(mid(10), mid(11)) + 6;
    _arrow(
      c,
      Offset(105, peakY - 22),
      Offset(105, peakY - 6),
      _stroke(palette.down, 2.5),
      head: 6,
    );
    _chip(
      c,
      Offset(105, peakY - 30),
      'SWING HIGH',
      palette.down,
      size: 8.5,
      filled: true,
    );
    _arrow(
      c,
      Offset(195, troughY + 22),
      Offset(195, troughY + 6),
      _stroke(palette.up, 2.5),
      head: 6,
    );
    _chip(
      c,
      Offset(195, troughY + 30),
      'SWING LOW',
      palette.up,
      size: 8.5,
      filled: true,
    );
  }

  void _roleReversal(Canvas c) {
    _glow(c, const Offset(180, 74), 80, palette.up);
    const level = 74.0;
    c.drawLine(
      const Offset(20, level),
      const Offset(280, level),
      _stroke(palette.gold.withValues(alpha: 0.55), 7),
    );
    c.drawPath(
      _polyline(const [
        Offset(20, 118),
        Offset(44, 78),
        Offset(66, 102),
        Offset(90, 77),
        Offset(112, 100),
        Offset(136, 50),
        Offset(156, 40),
        Offset(180, 71),
        Offset(208, 46),
        Offset(238, 34),
        Offset(278, 20),
      ]),
      _stroke(palette.text.withValues(alpha: 0.75), 3.5),
    );
    for (final p in const [Offset(44, 78), Offset(90, 77)]) {
      _dot(c, p, 4.5, palette.down);
    }
    _dot(c, const Offset(180, 71), 9, palette.up);
    _tick(c, const Offset(180, 71), 4, Colors.white, 2.4);
    _chip(c, const Offset(66, 124), 'OLD RESISTANCE', palette.down, size: 8.5);
    _chip(c, const Offset(222, 96), 'NEW SUPPORT', palette.up, size: 8.5);
  }

  void _trendChannel(Canvas c) {
    _glow(c, const Offset(150, 75), 90, palette.cyan);
    double lower(double x) => 124 - 0.27 * (x - 20);
    double upper(double x) => lower(x) - 44;
    final pts = <Offset>[];
    for (var i = 0; i < 7; i++) {
      final x = 30.0 + i * 40;
      pts.add(Offset(x, i.isEven ? lower(x) - 2 : upper(x) + 2));
    }
    c.drawLine(
      Offset(20, lower(20)),
      Offset(280, lower(280)),
      _stroke(palette.cyan, 3),
    );
    _dashed(
      c,
      Offset(20, upper(20)),
      Offset(280, upper(280)),
      palette.cyan.withValues(alpha: 0.75),
      2.5,
    );
    c.drawPath(
      _polyline(pts),
      _stroke(palette.text.withValues(alpha: 0.75), 3.5),
    );
    for (var i = 0; i < pts.length; i += 2) {
      _dot(c, pts[i], 4.5, palette.up);
    }
    _chip(
      c,
      Offset(230, lower(230) + 18),
      'TRENDLINE',
      palette.cyan,
      size: 8.5,
      filled: true,
    );
    _chip(
      c,
      Offset(74, upper(74) - 16),
      'CHANNEL LINE',
      palette.cyan,
      size: 8.5,
    );
  }

  void _fakeout(Canvas c) {
    _glow(c, const Offset(176, 52), 75, palette.orange);
    const level = 62.0;
    _dashed(
      c,
      const Offset(20, level),
      const Offset(280, level),
      palette.orange,
      2.5,
    );
    _label(
      c,
      'RESISTANCE',
      const Offset(54, level - 10),
      palette.orange,
      size: 8.5,
    );
    c.drawPath(
      _polyline(const [
        Offset(20, 116),
        Offset(48, 88),
        Offset(74, 100),
        Offset(102, 70),
        Offset(128, 88),
        Offset(158, 72),
      ]),
      _stroke(palette.textMuted, 3.5),
    );
    // Pokes above, closes back below.
    _candle(c, 176, 72, 68, 34, 76, width: 14, color: palette.down);
    c.drawPath(
      _polyline(const [
        Offset(194, 74),
        Offset(216, 92),
        Offset(240, 86),
        Offset(274, 118),
      ]),
      _stroke(palette.textMuted, 3.5),
    );
    _arrowHead(
      c,
      const Offset(274, 118),
      0.9,
      9,
      _stroke(palette.textMuted, 3.5),
    );
    _chip(c, const Offset(226, 30), 'BREAKOUT?', palette.orange, size: 8.5);
    _label(
      c,
      'closed back below: a trap',
      const Offset(150, 136),
      palette.textMuted,
      size: 9,
      spacing: 0,
      weight: FontWeight.w600,
    );
  }

  void _pullback(Canvas c) {
    _glow(c, const Offset(196, 76), 75, AppColors.gradientGold);
    const a = Offset(28, 118), b = Offset(148, 34);
    final move = a.dy - b.dy;
    final y38 = b.dy + move * 0.382, y62 = b.dy + move * 0.618;
    c.drawRect(
      Rect.fromLTRB(148, y38, 250, y62),
      Paint()..color = palette.gold.withValues(alpha: 0.18),
    );
    _dashed(
      c,
      Offset(148, y38),
      Offset(250, y38),
      palette.gold.withValues(alpha: 0.7),
      1.5,
    );
    _dashed(
      c,
      Offset(148, y62),
      Offset(250, y62),
      palette.gold.withValues(alpha: 0.7),
      1.5,
    );
    final up = _stroke(palette.up, 4);
    c.drawLine(a, b, up);
    c.drawLine(b, const Offset(198, 76), _stroke(palette.down, 4));
    c.drawLine(const Offset(198, 76), const Offset(270, 24), up);
    _arrowHead(c, const Offset(270, 24), -0.62, 9, up);
    _chip(c, const Offset(64, 64), 'MOVE UP', palette.up, size: 8.5);
    _chip(c, const Offset(198, 110), 'PULLBACK', palette.down, size: 8.5);
    _label(
      c,
      '38–62%',
      Offset(270, (y38 + y62) / 2),
      palette.gold,
      size: 9,
      spacing: 0,
    );
  }

  void _multiTimeframe(Canvas c) {
    _glow(c, const Offset(216, 96), 70, palette.cyan);
    c.drawPath(
      _polyline(const [
        Offset(18, 124),
        Offset(54, 98),
        Offset(72, 106),
        Offset(110, 78),
        Offset(128, 86),
        Offset(166, 56),
        Offset(186, 64),
        Offset(222, 36),
        Offset(282, 18),
      ]),
      _stroke(palette.up, 3.5),
    );
    _chip(
      c,
      const Offset(66, 30),
      'DAILY: UPTREND',
      palette.up,
      size: 8.5,
      filled: true,
    );
    // Zoom into one dip.
    const lens = Offset(214, 98);
    _dashed(
      c,
      const Offset(186, 64),
      lens + const Offset(-20, -26),
      palette.textMuted.withValues(alpha: 0.6),
      1.5,
    );
    c.drawCircle(lens, 30, Paint()..color = palette.surface);
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: lens, radius: 30)));
    const mini = [
      (196.0, 84.0, 92.0),
      (205.0, 92.0, 100.0),
      (214.0, 100.0, 108.0),
      (223.0, 108.0, 100.0),
      (232.0, 100.0, 92.0),
    ];
    for (final (x, o, cl) in mini) {
      _candle(c, x, o, cl, math.min(o, cl) - 4, math.max(o, cl) + 4, width: 6);
    }
    c.restore();
    c.drawCircle(lens, 30, _stroke(palette.cyan, 3.5));
    c.drawLine(
      lens + const Offset(21, 21),
      lens + const Offset(34, 34),
      _stroke(palette.cyan, 6),
    );
    _label(c, '1-HOUR: A DIP', const Offset(112, 128), palette.cyan, size: 8.5);
  }
}
