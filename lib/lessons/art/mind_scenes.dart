part of 'lesson_art.dart';

/// Level 7, Trading Psychology: one picture per feeling or idea.
extension _MindScenes on LessonArtPainter {
  // ---------------------------------------------------------------------------
  // Scenes

  void _stress(Canvas c) {
    _glow(c, const Offset(200, 78), 95, palette.down);
    // Pulse line racing into the heart.
    final pulse = Path()
      ..moveTo(16, 84)
      ..lineTo(70, 84)
      ..lineTo(80, 72)
      ..lineTo(90, 98)
      ..lineTo(104, 34)
      ..lineTo(118, 122)
      ..lineTo(130, 62)
      ..lineTo(140, 84)
      ..lineTo(182, 84);
    c.drawPath(
      pulse,
      _gradStroke(
        [palette.orange, palette.down],
        const Rect.fromLTWH(16, 34, 166, 88),
        4.5,
      ),
    );
    // Heart.
    final heart = _heartPath(const Offset(228, 80), 76);
    c.drawPath(
      heart,
      _gradFill([_pink, _pinkDeep], const Rect.fromLTWH(190, 40, 76, 80)),
    );
    c.drawPath(
      Path()
        ..moveTo(206, 66)
        ..quadraticBezierTo(208, 56, 218, 54),
      _stroke(Colors.white.withValues(alpha: 0.55), 4),
    );
    // Beat marks.
    final beat = _stroke(palette.down.withValues(alpha: 0.75), 3.5);
    c.drawArc(
      Rect.fromCircle(center: const Offset(228, 80), radius: 52),
      -0.55,
      0.5,
      false,
      beat,
    );
    c.drawArc(
      Rect.fromCircle(center: const Offset(228, 80), radius: 52),
      0.05,
      0.5,
      false,
      beat,
    );
    c.drawArc(
      Rect.fromCircle(center: const Offset(228, 80), radius: 62),
      -0.35,
      0.7,
      false,
      _stroke(palette.down.withValues(alpha: 0.4), 3),
    );
    _dot(c, const Offset(104, 34), 5, palette.down);
  }

  void _fearGreed(Canvas c) {
    _glow(c, const Offset(150, 64), 90, palette.gold);
    final metal = _stroke(palette.textMuted, 5);
    // Stand.
    c.drawLine(const Offset(150, 42), const Offset(150, 124), metal);
    c.drawRRect(
      RRect.fromLTRBR(116, 122, 184, 132, const Radius.circular(5)),
      Paint()..color = palette.surfaceHighest,
    );
    // Beam, tipped a little towards fear.
    const left = Offset(70, 50), right = Offset(230, 40);
    c.drawLine(left, right, metal);
    _dot(c, const Offset(150, 45), 7, AppColors.gradientGold);
    // Pans.
    _pan(c, left, 40);
    _pan(c, right, 40);

    // Fear: a cold drop that shivers.
    final drop = Path()
      ..moveTo(70, 58)
      ..quadraticBezierTo(82, 72, 82, 78)
      ..arcToPoint(const Offset(58, 78), radius: const Radius.circular(12))
      ..quadraticBezierTo(58, 72, 70, 58)
      ..close();
    c.drawPath(
      drop,
      _gradFill([
        _lighten(palette.cyan, 0.3),
        palette.cyan,
      ], const Rect.fromLTWH(58, 58, 24, 32)),
    );
    final shiver = _stroke(palette.cyan.withValues(alpha: 0.8), 2.5);
    c.drawLine(const Offset(50, 66), const Offset(45, 61), shiver);
    c.drawLine(const Offset(49, 76), const Offset(43, 76), shiver);
    c.drawLine(const Offset(90, 66), const Offset(95, 61), shiver);
    c.drawLine(const Offset(91, 76), const Offset(97, 76), shiver);

    // Greed: a stack of coins.
    for (var i = 0; i < 3; i++) {
      final y = 74.0 - i * 8;
      final side = Rect.fromLTRB(213, y - 4, 247, y + 4);
      c.drawRect(
        side,
        _gradFill([AppColors.gradientOrange, AppColors.gradientGold], side),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(230, y + 4), width: 34, height: 9),
        Paint()..color = AppColors.gradientOrange,
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(230, y - 4), width: 34, height: 9),
        Paint()..color = _lighten(AppColors.gradientGold, 0.25),
      );
    }
    _sparkle(c, const Offset(258, 50), 6, AppColors.gradientGold);
    _sparkle(c, const Offset(206, 46), 4, AppColors.gradientGold);

    _label(c, 'FEAR', const Offset(70, 116), palette.cyan);
    _label(c, 'GREED', const Offset(230, 106), palette.gold);
  }

  void _lossAversion(Canvas c) {
    _glow(c, const Offset(196, 100), 80, palette.down);
    c.drawLine(
      const Offset(46, 70),
      const Offset(254, 70),
      _stroke(palette.outline, 2.5),
    );
    // A $100 win...
    const win = Rect.fromLTRB(82, 44, 130, 70);
    c.drawRRect(
      RRect.fromRectAndCorners(
        win,
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
      ),
      _gradFill([_lighten(palette.up, 0.25), palette.up], win),
    );
    _label(c, '+\$100', const Offset(106, 32), palette.up, size: 12);
    // ...and a $100 loss that feels twice as big.
    const loss = Rect.fromLTRB(170, 70, 218, 122);
    c.drawRRect(
      RRect.fromRectAndCorners(
        loss,
        bottomLeft: const Radius.circular(7),
        bottomRight: const Radius.circular(7),
      ),
      _gradFill([palette.down, _pinkDeep], loss),
    );
    _label(c, '−\$100', const Offset(194, 136), palette.down, size: 12);
    _dot(c, const Offset(246, 96), 17, AppColors.gradientGold, gradient: true);
    _label(
      c,
      '×2',
      const Offset(246, 96),
      AppColors.onGold,
      size: 13,
      spacing: 0,
    );
  }

  void _calmPlan(Canvas c) {
    _glow(c, const Offset(118, 76), 85, palette.cyan);
    // Clipboard.
    const board = Rect.fromLTRB(58, 22, 162, 138);
    c.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(14)),
      _gradFill([palette.surfaceHighest, palette.surfaceHigh], board),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(14)),
      _stroke(palette.outline, 2),
    );
    c.drawRRect(
      RRect.fromLTRBR(90, 15, 130, 31, const Radius.circular(6)),
      _gradFill([
        AppColors.gradientGold,
        AppColors.gradientOrange,
      ], const Rect.fromLTRB(90, 15, 130, 31)),
    );
    // Entry, stop, target: all decided and ticked.
    final rows = [AppColors.gradientGold, palette.down, palette.up];
    for (var i = 0; i < rows.length; i++) {
      final y = 56.0 + i * 28;
      _dot(c, Offset(80, y), 9, rows[i]);
      _tick(c, Offset(80, y), 4.2, Colors.white, 2.6);
      c.drawLine(
        Offset(97, y),
        Offset(i == 1 ? 132 : 146, y),
        _stroke(palette.textMuted.withValues(alpha: 0.5), 5),
      );
    }
    // Calm water.
    for (var i = 0; i < 3; i++) {
      c.drawPath(
        _wave(184, 278, 56.0 + i * 20, 5, 2),
        _stroke(palette.cyan.withValues(alpha: 1 - i * 0.28), 4),
      );
    }
  }

  void _nameIt(Canvas c) {
    _glow(c, const Offset(104, 76), 85, _pink);
    // Head (same profile as the Level 7 badge), with a calm wave inside.
    c.save();
    c.translate(36, 6);
    c.scale(5.2);
    c.drawPath(
      _headPath(),
      _gradFill([_pink, _pinkDeep], const Rect.fromLTWH(5, 3, 16, 18)),
    );
    c.drawPath(
      Path()
        ..moveTo(8.6, 10.5)
        ..cubicTo(9.5, 9.1, 10.4, 9.1, 11.3, 10.5)
        ..cubicTo(12.2, 11.9, 13.1, 11.9, 14.0, 10.5),
      _stroke(Colors.white, 1.4),
    );
    c.restore();
    // Strings to the labels.
    final string = _stroke(palette.textMuted.withValues(alpha: 0.7), 2);
    c.drawPath(
      Path()
        ..moveTo(140, 56)
        ..quadraticBezierTo(156, 50, 172, 56),
      string,
    );
    c.drawPath(
      Path()
        ..moveTo(136, 80)
        ..quadraticBezierTo(158, 98, 180, 99),
      string,
    );
    _tag(c, const Rect.fromLTRB(172, 40, 274, 72), 'anxious', strong: true);
    _tag(c, const Rect.fromLTRB(180, 86, 262, 112), 'excited', strong: false);
  }

  void _lossesNormal(Canvas c) {
    _glow(c, const Offset(248, 56), 80, palette.gold);
    // Ten trades: 4 wins of +2R, 6 losses of -1R.
    const outcomes = [-1, 2, -1, -1, 2, -1, 2, -1, -1, 2];
    const x0 = 42.0, dx = 24.0, base = 132.0;
    final points = <Offset>[const Offset(24, 84)];
    var equity = 0;
    for (var i = 0; i < outcomes.length; i++) {
      final x = x0 + i * dx;
      final win = outcomes[i] > 0;
      final bar = Rect.fromLTRB(x - 7, base - (win ? 22 : 11), x + 7, base);
      c.drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(3)),
        Paint()
          ..color = (win ? palette.up : palette.down).withValues(alpha: 0.9),
      );
      equity += outcomes[i];
      points.add(Offset(x, 84 - equity * 13.0));
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      line,
      _gradStroke(
        [AppColors.gradientGold, AppColors.gradientOrange],
        const Rect.fromLTWH(24, 40, 234, 60),
        4,
      ),
    );
    _dot(c, points.last, 6, AppColors.gradientOrange);
    _label(
      c,
      '+2R',
      Offset(points.last.dx + 22, points.last.dy - 4),
      palette.gold,
      size: 12,
      spacing: 0,
    );
  }

  void _goodBadLoss(Canvas c) {
    _glow(c, const Offset(150, 76), 90, palette.up);
    _verdictTile(c, 30, good: true);
    _verdictTile(c, 160, good: false);
  }

  void _verdictTile(Canvas c, double left, {required bool good}) {
    final tile = Rect.fromLTWH(left, 16, 110, 118);
    c.drawRRect(
      RRect.fromRectAndRadius(tile, const Radius.circular(18)),
      Paint()..color = palette.surface,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(tile, const Radius.circular(18)),
      _stroke(palette.outline, 1.5),
    );
    _label(
      c,
      good ? 'GOOD' : 'BAD',
      Offset(left + 26, 33),
      good ? palette.up : palette.down,
      size: 10,
    );
    // Stop-loss line.
    const stopY = 92.0;
    _dashed(
      c,
      Offset(left + 12, stopY),
      Offset(left + 98, stopY),
      palette.down.withValues(alpha: 0.85),
      2.5,
    );
    // The losing candle: stopped at the line, or straight through it.
    final x = left + 55;
    final wick = good ? const (50.0, 92.0) : const (48.0, 128.0);
    final body = good ? const (58.0, 82.0) : const (56.0, 116.0);
    final red = Paint()..color = palette.down;
    c.drawRRect(
      RRect.fromLTRBR(
        x - 1.5,
        wick.$1,
        x + 1.5,
        wick.$2,
        const Radius.circular(1.5),
      ),
      red,
    );
    c.drawRRect(
      RRect.fromLTRBR(x - 9, body.$1, x + 9, body.$2, const Radius.circular(3)),
      red,
    );
    // Verdict badge.
    final badge = Offset(left + 92, 33);
    _dot(c, badge, 11, good ? palette.up : palette.down);
    if (good) {
      _tick(c, badge, 5, Colors.white, 2.6);
    } else {
      final cross = _stroke(Colors.white, 2.6);
      c.drawLine(
        badge + const Offset(-4.5, -4.5),
        badge + const Offset(4.5, 4.5),
        cross,
      );
      c.drawLine(
        badge + const Offset(4.5, -4.5),
        badge + const Offset(-4.5, 4.5),
        cross,
      );
    }
  }

  void _reset(Canvas c) {
    _glow(c, const Offset(150, 60), 90, palette.gold);
    const y = 62.0;
    final arrows = _stroke(palette.textMuted.withValues(alpha: 0.7), 2.5);
    for (final x in const [96.0, 186.0]) {
      _dashed(
        c,
        Offset(x, y),
        Offset(x + 20, y),
        palette.textMuted.withValues(alpha: 0.7),
        2.5,
      );
      c.drawPath(
        Path()
          ..moveTo(x + 18, y - 5)
          ..lineTo(x + 23, y)
          ..lineTo(x + 18, y + 5),
        arrows,
      );
    }
    // 1. Pause
    const p = Offset(62, y);
    _dot(c, p, 30, palette.cyan, gradient: true);
    final bar = Paint()..color = Colors.white;
    c.drawRRect(
      RRect.fromLTRBR(
        p.dx - 10,
        p.dy - 12,
        p.dx - 3,
        p.dy + 12,
        const Radius.circular(3),
      ),
      bar,
    );
    c.drawRRect(
      RRect.fromLTRBR(
        p.dx + 3,
        p.dy - 12,
        p.dx + 10,
        p.dy + 12,
        const Radius.circular(3),
      ),
      bar,
    );
    // 2. Review
    const r = Offset(150, y);
    _dot(c, r, 30, AppColors.gradientGold, gradient: true);
    final lens = _stroke(AppColors.onGold, 4);
    c.drawCircle(r + const Offset(-3, -3), 9, lens);
    c.drawLine(r + const Offset(4, 4), r + const Offset(11, 11), lens);
    // 3. Reset
    const z = Offset(238, y);
    _dot(c, z, 30, palette.up, gradient: true);
    final loop = _stroke(Colors.white, 4);
    c.drawArc(Rect.fromCircle(center: z, radius: 11), -1.2, 5.0, false, loop);
    final tip = z + Offset(11 * math.cos(-1.2), 11 * math.sin(-1.2));
    c.drawPath(
      Path()
        ..moveTo(tip.dx - 7, tip.dy - 3)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - 2, tip.dy + 7),
      loop,
    );
    _label(c, 'PAUSE', const Offset(62, 112), palette.text, size: 11);
    _label(c, 'REVIEW', const Offset(150, 112), palette.text, size: 11);
    _label(c, 'RESET', const Offset(238, 112), palette.text, size: 11);
  }

  void _lossLimit(Canvas c) {
    _glow(c, const Offset(230, 92), 75, palette.down);
    const limitY = 110.0;
    _dashed(
      c,
      const Offset(20, limitY),
      const Offset(280, limitY),
      palette.down,
      3,
    );
    _label(c, 'DAILY LOSS LIMIT', const Offset(88, 126), palette.down, size: 9);
    final equity = Path()
      ..moveTo(20, 34)
      ..lineTo(48, 50)
      ..lineTo(70, 42)
      ..lineTo(100, 66)
      ..lineTo(124, 58)
      ..lineTo(156, 84)
      ..lineTo(178, 78)
      ..lineTo(204, limitY);
    c.drawPath(equity, _stroke(palette.textMuted, 4));
    _dot(c, const Offset(204, limitY), 6, palette.down);
    // Stop sign.
    const sc = Offset(244, 68);
    c.drawLine(
      sc,
      const Offset(244, limitY - 4),
      _stroke(palette.textMuted, 4),
    );
    final octagon = Path();
    for (var i = 0; i < 8; i++) {
      final a = math.pi / 8 + i * math.pi / 4;
      final pt = sc + Offset(25 * math.cos(a), 25 * math.sin(a));
      i == 0 ? octagon.moveTo(pt.dx, pt.dy) : octagon.lineTo(pt.dx, pt.dy);
    }
    octagon.close();
    c.drawPath(
      octagon,
      _gradFill([
        palette.down,
        _pinkDeep,
      ], Rect.fromCircle(center: sc, radius: 25)),
    );
    _label(c, 'STOP', sc, Colors.white, size: 11);
  }

  void _tilt(Canvas c) {
    _glow(c, const Offset(196, 96), 90, palette.orange);
    const center = Offset(150, 120);
    final dial = Rect.fromCircle(center: center, radius: 78);
    Paint arc(Color col) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    c.drawArc(dial, math.pi + 0.12, 0.8, false, arc(palette.up));
    c.drawArc(dial, math.pi + 1.17, 0.8, false, arc(AppColors.gradientGold));
    c.drawArc(dial, math.pi + 2.22, 0.8, false, arc(palette.down));
    // Needle deep in the red.
    const a = 2 * math.pi - 0.42;
    final tip = center + Offset(64 * math.cos(a), 64 * math.sin(a));
    final normal = Offset(-math.sin(a), math.cos(a)) * 6;
    c.drawPath(
      Path()
        ..moveTo(center.dx + normal.dx, center.dy + normal.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(center.dx - normal.dx, center.dy - normal.dy)
        ..close(),
      Paint()..color = palette.text,
    );
    _dot(c, center, 10, palette.text);
    _dot(c, center, 4, palette.down);
    _label(c, 'CALM', const Offset(48, 138), palette.up, size: 10);
    _label(c, 'TILT', const Offset(252, 138), palette.down, size: 10);
  }

  void _rest(Canvas c) {
    _glow(c, const Offset(214, 56), 75, palette.cyan);
    // Battery, nearly empty.
    const body = Rect.fromLTRB(46, 52, 166, 112);
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(14)),
      _stroke(palette.textMuted, 5),
    );
    c.drawRRect(
      RRect.fromLTRBR(170, 70, 180, 94, const Radius.circular(3)),
      Paint()..color = palette.textMuted,
    );
    const charge = Rect.fromLTRB(57, 63, 80, 101);
    c.drawRRect(
      RRect.fromRectAndRadius(charge, const Radius.circular(6)),
      _gradFill([palette.down, _pinkDeep], charge),
    );
    // Crescent moon and stars.
    final moon = Path.combine(
      PathOperation.difference,
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(222, 56), radius: 27)),
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(236, 46), radius: 23)),
    );
    c.drawPath(
      moon,
      _gradFill([
        AppColors.gradientGold,
        AppColors.gradientOrange,
      ], const Rect.fromLTWH(195, 29, 54, 54)),
    );
    _sparkle(c, const Offset(196, 26), 5, AppColors.gradientGold);
    _sparkle(c, const Offset(270, 34), 4, AppColors.gradientGold);
    _label(
      c,
      'z',
      const Offset(256, 96),
      palette.textMuted,
      size: 16,
      spacing: 0,
    );
    _label(
      c,
      'z',
      const Offset(272, 80),
      palette.textMuted,
      size: 12,
      spacing: 0,
    );
  }

  void _warningSigns(Canvas c) {
    _glow(c, const Offset(150, 80), 90, palette.orange);
    final ripple = palette.orange;
    for (final (r, alpha) in const [(76.0, 0.55), (96.0, 0.3)]) {
      final rect = Rect.fromCircle(center: const Offset(150, 84), radius: r);
      c.drawArc(
        rect,
        -0.45,
        0.9,
        false,
        _stroke(ripple.withValues(alpha: alpha), 3.5),
      );
      c.drawArc(
        rect,
        math.pi - 0.45,
        0.9,
        false,
        _stroke(ripple.withValues(alpha: alpha), 3.5),
      );
    }
    final triangle = Path()
      ..moveTo(150, 30)
      ..lineTo(206, 122)
      ..lineTo(94, 122)
      ..close();
    final shader = const LinearGradient(
      colors: [AppColors.gradientGold, AppColors.gradientOrange],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(const Rect.fromLTRB(94, 30, 206, 122));
    c.drawPath(triangle, Paint()..shader = shader);
    c.drawPath(
      triangle,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawLine(
      const Offset(150, 64),
      const Offset(150, 94),
      _stroke(AppColors.onGold, 10),
    );
    _dot(c, const Offset(150, 112), 6, AppColors.onGold);
  }

  void _support(Canvas c) {
    _glow(c, const Offset(140, 70), 90, _pink);
    // Big bubble with a heart.
    final bubble = Path()
      ..addRRect(RRect.fromLTRBR(66, 22, 190, 104, const Radius.circular(26)))
      ..moveTo(90, 100)
      ..lineTo(80, 126)
      ..lineTo(118, 102)
      ..close();
    c.drawPath(
      bubble,
      _gradFill([
        _lighten(palette.cyan, 0.15),
        palette.cyan,
      ], const Rect.fromLTRB(66, 22, 190, 126)),
    );
    c.drawPath(
      _heartPath(const Offset(128, 64), 50),
      _gradFill([_pink, _pinkDeep], const Rect.fromLTWH(103, 40, 50, 50)),
    );
    // Reply bubble, typing.
    final reply = RRect.fromLTRBR(176, 78, 250, 118, const Radius.circular(20));
    final replyPath = Path()
      ..addRRect(reply)
      ..moveTo(226, 114)
      ..lineTo(244, 132)
      ..lineTo(240, 108)
      ..close();
    c.drawPath(replyPath, Paint()..color = palette.surface);
    c.drawPath(
      Path.combine(
        PathOperation.union,
        Path()..addRRect(reply),
        Path()
          ..moveTo(226, 114)
          ..lineTo(244, 132)
          ..lineTo(240, 108)
          ..close(),
      ),
      _stroke(palette.outline, 1.5),
    );
    for (var i = 0; i < 3; i++) {
      _dot(
        c,
        Offset(198 + i * 15.0, 98),
        4.5,
        palette.textMuted.withValues(alpha: 1 - i * 0.25),
      );
    }
  }

  void _safePractice(Canvas c) {
    _glow(c, const Offset(150, 74), 90, palette.up);
    // Virtual coin behind the shield.
    const coin = Offset(194, 62);
    _dot(c, coin, 36, AppColors.gradientGold, gradient: true);
    c.drawCircle(
      coin,
      28,
      _stroke(AppColors.onGold.withValues(alpha: 0.22), 3),
    );
    _label(
      c,
      '\$',
      coin + const Offset(6, 0),
      AppColors.onGold.withValues(alpha: 0.75),
      size: 28,
      spacing: 0,
    );
    // Shield with a tick.
    final shield = Path()
      ..moveTo(128, 26)
      ..lineTo(170, 42)
      ..lineTo(170, 76)
      ..quadraticBezierTo(168, 110, 128, 130)
      ..quadraticBezierTo(88, 110, 86, 76)
      ..lineTo(86, 42)
      ..close();
    c.drawPath(
      shield,
      _gradFill([
        _lighten(palette.up, 0.2),
        palette.up,
      ], const Rect.fromLTRB(86, 26, 170, 130)),
    );
    c.drawPath(
      Path()
        ..moveTo(108, 78)
        ..lineTo(122, 92)
        ..lineTo(150, 62),
      _stroke(Colors.white, 8),
    );
  }

  // ---------------------------------------------------------------------------
  // Pieces

  void _pan(Canvas c, Offset hook, double width) {
    final y = hook.dy + 38;
    final string = _stroke(palette.textMuted.withValues(alpha: 0.8), 2);
    c.drawLine(hook, Offset(hook.dx - width / 2 + 2, y), string);
    c.drawLine(hook, Offset(hook.dx + width / 2 - 2, y), string);
    final pan = Path()
      ..moveTo(hook.dx - width / 2 - 6, y)
      ..quadraticBezierTo(hook.dx, y + 22, hook.dx + width / 2 + 6, y)
      ..close();
    c.drawPath(pan, Paint()..color = palette.surfaceHighest);
    c.drawPath(pan, _stroke(palette.textMuted, 2.5));
  }

  void _tag(Canvas c, Rect r, String text, {required bool strong}) {
    final path = Path()
      ..moveTo(r.left, r.center.dy)
      ..lineTo(r.left + 14, r.top)
      ..lineTo(r.right - 8, r.top)
      ..quadraticBezierTo(r.right, r.top, r.right, r.top + 8)
      ..lineTo(r.right, r.bottom - 8)
      ..quadraticBezierTo(r.right, r.bottom, r.right - 8, r.bottom)
      ..lineTo(r.left + 14, r.bottom)
      ..close();
    c.drawPath(
      path,
      Paint()..color = palette.surface.withValues(alpha: strong ? 1 : 0.7),
    );
    c.drawPath(
      path,
      _stroke(strong ? _pink : palette.outline, strong ? 2.5 : 1.5),
    );
    c.drawCircle(
      Offset(r.left + 13, r.center.dy),
      3.5,
      Paint()..color = palette.textMuted,
    );
    _label(
      c,
      text,
      Offset(r.center.dx + 6, r.center.dy),
      palette.text.withValues(alpha: strong ? 1 : 0.6),
      size: strong ? 14 : 12,
      spacing: 0,
      weight: FontWeight.w600,
    );
  }
}
