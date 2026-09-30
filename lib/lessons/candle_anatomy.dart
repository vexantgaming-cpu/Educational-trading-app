import 'package:flutter/material.dart';

import '../chart/chart_models.dart';

/// A labelled bullish and bearish candle, used to teach OHLC.
class CandleAnatomy extends StatelessWidget {
  const CandleAnatomy({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChartColors.of(context);
    return AspectRatio(
      aspectRatio: 1.5,
      child: CustomPaint(
        painter: _AnatomyPainter(
          up: colors.up,
          down: colors.down,
          text: Theme.of(context).colorScheme.onSurface,
          muted: colors.text,
        ),
      ),
    );
  }
}

class _AnatomyPainter extends CustomPainter {
  _AnatomyPainter({
    required this.up,
    required this.down,
    required this.text,
    required this.muted,
  });

  final Color up;
  final Color down;
  final Color text;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    // Same high/low for both; the body is flipped.
    final high = h * 0.1, low = h * 0.9, top = h * 0.3, bottom = h * 0.7;
    _candle(
      canvas,
      size.width * 0.25,
      high,
      low,
      top,
      bottom,
      up,
      topLabel: 'Close',
      bottomLabel: 'Open',
      title: 'Bullish (up)',
    );
    _candle(
      canvas,
      size.width * 0.72,
      high,
      low,
      top,
      bottom,
      down,
      topLabel: 'Open',
      bottomLabel: 'Close',
      title: 'Bearish (down)',
    );
  }

  void _candle(
    Canvas canvas,
    double x,
    double high,
    double low,
    double top,
    double bottom,
    Color color, {
    required String topLabel,
    required String bottomLabel,
    required String title,
  }) {
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTRB(x - 2, high, x + 2, low), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 22, top, x + 22, bottom),
        const Radius.circular(3),
      ),
      paint,
    );
    _label(canvas, 'High', Offset(x + 10, high - 7));
    _label(canvas, 'Low', Offset(x + 10, low - 7));
    _label(canvas, topLabel, Offset(x + 28, top - 7));
    _label(canvas, bottomLabel, Offset(x + 28, bottom - 7));
    _label(canvas, 'Body', Offset(x - 70, (top + bottom) / 2 - 7), muted: true);
    _label(canvas, 'Wick', Offset(x - 62, (high + top) / 2 - 7), muted: true);
    _label(canvas, 'Wick', Offset(x - 62, (bottom + low) / 2 - 7), muted: true);
    _label(canvas, title, Offset(x - 40, low + 6), bold: true, color: color);
  }

  void _label(
    Canvas canvas,
    String s,
    Offset at, {
    bool muted = false,
    bool bold = false,
    Color? color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color ?? (muted ? this.muted : text),
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _AnatomyPainter old) => false;
}
