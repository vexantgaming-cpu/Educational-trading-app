import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Vector key visuals for each tab, drawn in code so they stay crisp at any
/// size and cost nothing to ship.

void _glow(
  Canvas canvas,
  Size size,
  Offset center,
  Color color,
  double radius,
) {
  final rect = Rect.fromCircle(center: center, radius: radius);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.38), color.withValues(alpha: 0)],
      ).createShader(rect),
  );
}

void _sparkle(Canvas canvas, Offset c, double r, Color color) {
  final path = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

void _candle(
  Canvas canvas,
  double x,
  double wickTop,
  double bodyTop,
  double bodyBottom,
  double wickBottom,
  double width,
  Color color,
) {
  final paint = Paint()..color = color;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(x - 1.2, wickTop, x + 1.2, wickBottom),
      const Radius.circular(1),
    ),
    paint,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(x - width / 2, bodyTop, x + width / 2, bodyBottom),
      const Radius.circular(2),
    ),
    paint,
  );
}

Paint _goldStroke(Rect bounds, double width) => Paint()
  ..shader = AppColors.primaryGradient.createShader(bounds)
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Learn: an open book with candles rising out of it and a trend arrow.
class LearnArt extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _glow(canvas, size, Offset(w * 0.55, h * 0.45), AppColors.gold, w * 0.55);

    // Book.
    final cx = w * 0.5;
    final left = Path()
      ..moveTo(cx, h * 0.66)
      ..quadraticBezierTo(w * 0.32, h * 0.58, w * 0.08, h * 0.63)
      ..lineTo(w * 0.08, h * 0.88)
      ..quadraticBezierTo(w * 0.32, h * 0.83, cx, h * 0.93)
      ..close();
    final right = Path()
      ..moveTo(cx, h * 0.66)
      ..quadraticBezierTo(w * 0.68, h * 0.58, w * 0.92, h * 0.63)
      ..lineTo(w * 0.92, h * 0.88)
      ..quadraticBezierTo(w * 0.68, h * 0.83, cx, h * 0.93)
      ..close();
    final pageFill = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.surfaceHighest, AppColors.surfaceHigh],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.58, w, h * 0.36));
    canvas.drawPath(left, pageFill);
    canvas.drawPath(right, pageFill);
    final edge = _goldStroke(Offset.zero & size, 1.6);
    canvas.drawPath(left, edge);
    canvas.drawPath(right, edge);
    final lines = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = h * (0.7 + i * 0.05);
      canvas.drawLine(
        Offset(w * 0.16, y),
        Offset(w * 0.42, y + h * 0.015),
        lines,
      );
      canvas.drawLine(
        Offset(w * 0.58, y + h * 0.015),
        Offset(w * 0.84, y),
        lines,
      );
    }

    // Rising candles.
    final cw = w * 0.075;
    _candle(
      canvas,
      w * 0.27,
      h * 0.44,
      h * 0.48,
      h * 0.58,
      h * 0.62,
      cw,
      AppColors.up,
    );
    _candle(
      canvas,
      w * 0.41,
      h * 0.38,
      h * 0.42,
      h * 0.49,
      h * 0.54,
      cw,
      AppColors.down,
    );
    _candle(
      canvas,
      w * 0.55,
      h * 0.24,
      h * 0.29,
      h * 0.45,
      h * 0.5,
      cw,
      AppColors.up,
    );
    _candle(
      canvas,
      w * 0.69,
      h * 0.1,
      h * 0.15,
      h * 0.33,
      h * 0.38,
      cw,
      AppColors.up,
    );

    // Trend arrow.
    final bounds = Offset.zero & size;
    final arrow = Path()
      ..moveTo(w * 0.14, h * 0.56)
      ..cubicTo(w * 0.36, h * 0.52, w * 0.56, h * 0.36, w * 0.84, h * 0.1);
    canvas.drawPath(arrow, _goldStroke(bounds, 3.2));
    final head = Path()
      ..moveTo(w * 0.86, h * 0.08)
      ..lineTo(w * 0.74, h * 0.1)
      ..moveTo(w * 0.86, h * 0.08)
      ..lineTo(w * 0.84, h * 0.2);
    canvas.drawPath(head, _goldStroke(bounds, 3.2));

    _sparkle(canvas, Offset(w * 0.9, h * 0.34), w * 0.04, AppColors.gold);
    _sparkle(canvas, Offset(w * 0.12, h * 0.26), w * 0.03, AppColors.cyan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Practice: a phone with a live chart, stop/target lines, a crosshair and a
/// virtual coin.
class PracticeArt extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _glow(canvas, size, Offset(w * 0.5, h * 0.5), AppColors.cyan, w * 0.55);

    final phone = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.22, h * 0.05, w * 0.76, h * 0.95),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(phone, Paint()..color = AppColors.surfaceHigh);
    canvas.drawRRect(phone, _goldStroke(phone.outerRect, 2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.43, h * 0.08, w * 0.12, h * 0.018),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.outline,
    );

    // Levels.
    void dashed(double y, Color color) {
      final p = Paint()
        ..color = color
        ..strokeWidth = 1.6;
      for (var x = w * 0.27; x < w * 0.71; x += 7) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, w * 0.71), y), p);
      }
    }

    dashed(h * 0.24, AppColors.up);
    dashed(h * 0.74, AppColors.down);
    canvas.drawLine(
      Offset(w * 0.27, h * 0.55),
      Offset(w * 0.71, h * 0.55),
      Paint()
        ..color = AppColors.cyan.withValues(alpha: 0.8)
        ..strokeWidth = 1.2,
    );

    // Candles.
    final cw = w * 0.045;
    const data = [
      (0.62, 0.66, 0.60, 0.70, true),
      (0.56, 0.60, 0.64, 0.68, false),
      (0.52, 0.55, 0.62, 0.66, true),
      (0.44, 0.47, 0.56, 0.60, true),
      (0.46, 0.49, 0.54, 0.58, false),
      (0.34, 0.37, 0.50, 0.53, true),
      (0.26, 0.29, 0.40, 0.44, true),
    ];
    for (var i = 0; i < data.length; i++) {
      final (wt, bt, bb, wb, up) = data[i];
      _candle(
        canvas,
        w * (0.31 + i * 0.062),
        h * wt,
        h * bt,
        h * bb,
        h * wb,
        cw,
        up ? AppColors.up : AppColors.down,
      );
    }

    // Crosshair.
    final target = Offset(w * 0.5, h * 0.55);
    final ring = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(target, w * 0.075, ring);
    canvas.drawCircle(target, w * 0.02, Paint()..color = AppColors.gold);
    for (final d in [
      const Offset(1, 0),
      const Offset(-1, 0),
      const Offset(0, 1),
      const Offset(0, -1),
    ]) {
      canvas.drawLine(target + d * (w * 0.09), target + d * (w * 0.13), ring);
    }

    // Coin.
    final coin = Offset(w * 0.8, h * 0.78);
    final coinRect = Rect.fromCircle(center: coin, radius: w * 0.13);
    canvas.drawCircle(
      coin,
      w * 0.13,
      Paint()..shader = AppColors.primaryGradient.createShader(coinRect),
    );
    canvas.drawCircle(
      coin,
      w * 0.1,
      Paint()
        ..color = AppColors.onGold.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final dollar = TextPainter(
      text: TextSpan(
        text: '\$',
        style: TextStyle(
          color: AppColors.onGold,
          fontSize: w * 0.14,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    dollar.paint(canvas, coin - Offset(dollar.width / 2, dollar.height / 2));

    // Up badge.
    final badge = Offset(w * 0.16, h * 0.22);
    canvas.drawCircle(badge, w * 0.085, Paint()..color = AppColors.up);
    final arrow = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      badge + Offset(0, w * 0.04),
      badge - Offset(0, w * 0.04),
      arrow,
    );
    canvas.drawLine(
      badge - Offset(0, w * 0.04),
      badge + Offset(-w * 0.035, -w * 0.005),
      arrow,
    );
    canvas.drawLine(
      badge - Offset(0, w * 0.04),
      badge + Offset(w * 0.035, -w * 0.005),
      arrow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Account / achievements: a trophy inside a progress ring, with confetti.
class TrophyArt extends CustomPainter {
  TrophyArt({this.progress = 0.72, this.showRing = true});

  final double progress;
  final bool showRing;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final center = Offset(w * 0.5, h * 0.48);
    _glow(canvas, size, center, AppColors.violet, w * 0.55);

    if (showRing) {
      final r = w * 0.4;
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = AppColors.surfaceHighest
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7,
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.02, 1.0),
        false,
        Paint()
          ..shader = const SweepGradient(
            colors: [AppColors.gold, AppColors.orange, AppColors.gold],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 7,
      );
    }

    // Trophy.
    final cupRect = Rect.fromLTRB(w * 0.33, h * 0.24, w * 0.67, h * 0.72);
    final gold = Paint()
      ..shader = AppColors.primaryGradient.createShader(cupRect);
    final cup = Path()
      ..moveTo(w * 0.35, h * 0.26)
      ..lineTo(w * 0.65, h * 0.26)
      ..quadraticBezierTo(w * 0.65, h * 0.52, w * 0.5, h * 0.55)
      ..quadraticBezierTo(w * 0.35, h * 0.52, w * 0.35, h * 0.26)
      ..close();
    canvas.drawPath(cup, gold);
    final handle = Paint()
      ..shader = AppColors.primaryGradient.createShader(cupRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.35, h * 0.34), radius: w * 0.07),
      math.pi / 2,
      math.pi,
      false,
      handle,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.65, h * 0.34), radius: w * 0.07),
      -math.pi / 2,
      math.pi,
      false,
      handle,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.47, h * 0.54, w * 0.53, h * 0.63),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.38, h * 0.62, w * 0.62, h * 0.69),
        const Radius.circular(4),
      ),
      gold,
    );
    _sparkle(
      canvas,
      Offset(w * 0.5, h * 0.37),
      w * 0.06,
      Colors.white.withValues(alpha: 0.9),
    );

    // Confetti.
    const confetti = [
      (0.14, 0.2, AppColors.cyan),
      (0.86, 0.18, AppColors.up),
      (0.9, 0.62, AppColors.violet),
      (0.1, 0.7, AppColors.orange),
      (0.22, 0.9, AppColors.gold),
      (0.8, 0.9, AppColors.cyan),
    ];
    for (final (x, y, c) in confetti) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * x, h * y),
            width: w * 0.05,
            height: w * 0.025,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = c,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrophyArt oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.showRing != showRing;
}
