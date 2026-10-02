import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Which arrangement of the Upwiq mark to draw.
enum UpwiqLogoVariant { horizontal, stacked, symbol, wordmark }

/// The Upwiq logo from the design system: the rising-wick symbol and the
/// lowercase `upwiq` wordmark. It is drawn in code (same geometry as the SVG
/// files in `docs/brand/logo/`), so the letters follow the theme's text
/// colour while the symbol and the i-dot keep the brand gradient.
class UpwiqLogo extends StatelessWidget {
  const UpwiqLogo({
    super.key,
    this.variant = UpwiqLogoVariant.horizontal,
    required this.height,
  });

  const UpwiqLogo.symbol({super.key, required this.height})
    : variant = UpwiqLogoVariant.symbol;

  final UpwiqLogoVariant variant;

  /// Height of the artboard in logical pixels; the width follows the
  /// variant's aspect ratio.
  final double height;

  @override
  Widget build(BuildContext context) {
    final box = _artboard(variant);
    return Semantics(
      label: 'Upwiq',
      image: true,
      child: SizedBox(
        width: height * box.width / box.height,
        height: height,
        child: CustomPaint(
          painter: UpwiqLogoPainter(
            variant: variant,
            letterColor: context.palette.text,
          ),
        ),
      ),
    );
  }
}

/// Artboard sizes of the SVG files (viewBox units).
Size _artboard(UpwiqLogoVariant v) => switch (v) {
  UpwiqLogoVariant.horizontal => const Size(272.6, 90),
  UpwiqLogoVariant.stacked => const Size(220, 195.6),
  UpwiqLogoVariant.symbol => const Size(64, 64),
  UpwiqLogoVariant.wordmark => const Size(220, 88),
};

class UpwiqLogoPainter extends CustomPainter {
  UpwiqLogoPainter({required this.variant, required this.letterColor});

  final UpwiqLogoVariant variant;
  final Color letterColor;

  @override
  void paint(Canvas canvas, Size size) {
    final box = _artboard(variant);
    canvas.save();
    canvas.scale(size.width / box.width, size.height / box.height);
    switch (variant) {
      case UpwiqLogoVariant.symbol:
        _symbol(canvas);
      case UpwiqLogoVariant.wordmark:
        canvas.translate(0, 2);
        _wordmark(canvas, iSparkGradientStart: const Offset(160, 0));
      case UpwiqLogoVariant.horizontal:
        canvas.save();
        canvas.translate(-25.30, -2.20);
        canvas.scale(1.3);
        _symbol(canvas);
        canvas.restore();
        canvas.translate(52.6, 2);
        _wordmark(canvas, iSparkGradientStart: const Offset(150, 0));
      case UpwiqLogoVariant.stacked:
        canvas.save();
        canvas.translate(58.8, -5.6);
        canvas.scale(1.6);
        _symbol(canvas);
        canvas.restore();
        canvas.translate(0, 109.6);
        _wordmark(canvas, iSparkGradientStart: const Offset(150, 0));
    }
    canvas.restore();
  }

  /// The rising-wick symbol on its 64-unit grid.
  static void _symbol(Canvas canvas) {
    final shader = const LinearGradient(
      colors: [AppColors.gradientGold, AppColors.gradientOrange],
    ).createShader(Rect.fromPoints(const Offset(21, 6), const Offset(43, 62)));
    final stroke = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Upper wick turned into an arrow.
    canvas.drawPath(
      Path()
        ..moveTo(23, 17)
        ..lineTo(32, 8)
        ..lineTo(41, 17)
        ..moveTo(32, 8)
        ..lineTo(32, 24),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 24, 16, 28),
        const Radius.circular(4),
      ),
      Paint()..shader = shader,
    );
    canvas.drawLine(const Offset(32, 52), const Offset(32, 60), stroke);
  }

  /// Monoline lowercase `upwiq` on a 40-unit x-height.
  void _wordmark(Canvas canvas, {required Offset iSparkGradientStart}) {
    final ink = Paint()
      ..color = letterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // u
    canvas.drawPath(
      Path()
        ..moveTo(4, 24)
        ..lineTo(4, 40)
        ..arcToPoint(
          const Offset(36, 40),
          radius: const Radius.circular(16),
          clockwise: false,
        )
        ..lineTo(36, 24)
        ..moveTo(36, 24)
        ..lineTo(36, 56),
      ink,
    );
    // p
    canvas.drawLine(const Offset(54, 24), const Offset(54, 76), ink);
    canvas.drawCircle(const Offset(70, 40), 16, ink);
    // w
    canvas.drawPath(
      Path()
        ..moveTo(104, 24)
        ..lineTo(115, 56)
        ..lineTo(126, 26)
        ..lineTo(137, 56)
        ..lineTo(148, 24),
      ink,
    );
    // i and its spark
    canvas.drawLine(const Offset(166, 24), const Offset(166, 56), ink);
    canvas.drawCircle(
      const Offset(166, 8),
      5.5,
      Paint()
        ..shader =
            const LinearGradient(
              colors: [AppColors.gradientGold, AppColors.gradientOrange],
            ).createShader(
              Rect.fromPoints(iSparkGradientStart, const Offset(220, 86)),
            ),
    );
    // q with its wick
    canvas.drawCircle(const Offset(200, 40), 16, ink);
    canvas.drawLine(const Offset(216, 24), const Offset(216, 56), ink);
    canvas.drawLine(
      const Offset(216, 58),
      const Offset(216, 82),
      Paint()
        ..color = letterColor
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(UpwiqLogoPainter old) =>
      old.variant != variant || old.letterColor != letterColor;
}
