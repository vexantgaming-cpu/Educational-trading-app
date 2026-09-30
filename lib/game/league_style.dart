import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import '../theme/app_colors.dart';

List<Color> leagueColors(League league) => switch (league) {
  League.bronze => const [Color(0xFFF0B27A), Color(0xFF9A5B2E)],
  League.silver => const [Color(0xFFF1F5F9), Color(0xFF94A3B8)],
  League.gold => const [Color(0xFFFFE08A), Color(0xFFD99A00)],
  League.platinum => const [Color(0xFF99F6E4), Color(0xFF14B8A6)],
  League.diamond => const [Color(0xFFBAE6FD), Color(0xFF3B82F6)],
  League.master => const [Color(0xFFF5D0FE), Color(0xFF9333EA)],
};

/// Icon and colours for each market on cards.
(IconData, List<Color>) marketStyle(
  MarketProfile market,
) => switch (market.symbol) {
  'XAUUSD' => (Icons.diamond, const [Color(0xFFFFE08A), Color(0xFFD99A00)]),
  'USOIL' => (Icons.oil_barrel, const [Color(0xFF94A3B8), Color(0xFF334155)]),
  'US500' ||
  'US100' => (Icons.show_chart, const [Color(0xFF34D399), Color(0xFF059669)]),
  'BTCUSD' => (
    Icons.currency_bitcoin,
    const [Color(0xFFFDBA74), Color(0xFFEA580C)],
  ),
  'NOVA' => (
    Icons.precision_manufacturing,
    const [Color(0xFFC4B5FD), Color(0xFF7C3AED)],
  ),
  _ => (Icons.currency_exchange, const [Color(0xFF38BDF8), Color(0xFF2563EB)]),
};

String assetClassLabel(AssetClass c) => switch (c) {
  AssetClass.forex => 'Forex',
  AssetClass.commodity => 'Commodity',
  AssetClass.stockIndex => 'Index',
  AssetClass.crypto => 'Crypto',
  AssetClass.stock => 'Stock (fictional)',
  AssetClass.synthetic => 'Practice',
};

/// A league crest: gradient shield with a star and chevrons for the level.
class LeagueBadgeArt extends CustomPainter {
  LeagueBadgeArt(this.league, {this.glow = true});

  final League league;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final colors = leagueColors(league);
    final rect = Offset.zero & size;
    if (glow) {
      canvas.drawCircle(
        Offset(w / 2, h / 2),
        w * 0.55,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  colors.last.withValues(alpha: 0.4),
                  colors.last.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: Offset(w / 2, h / 2), radius: w * 0.55),
              ),
      );
    }
    final shield = Path()
      ..moveTo(w * 0.5, h * 0.06)
      ..lineTo(w * 0.86, h * 0.2)
      ..lineTo(w * 0.84, h * 0.55)
      ..quadraticBezierTo(w * 0.8, h * 0.8, w * 0.5, h * 0.95)
      ..quadraticBezierTo(w * 0.2, h * 0.8, w * 0.16, h * 0.55)
      ..lineTo(w * 0.14, h * 0.2)
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    canvas.drawPath(
      shield,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025,
    );
    // Inner shield.
    final inner = Path()
      ..moveTo(w * 0.5, h * 0.16)
      ..lineTo(w * 0.76, h * 0.26)
      ..lineTo(w * 0.74, h * 0.54)
      ..quadraticBezierTo(w * 0.71, h * 0.73, w * 0.5, h * 0.85)
      ..quadraticBezierTo(w * 0.29, h * 0.73, w * 0.26, h * 0.54)
      ..lineTo(w * 0.24, h * 0.26)
      ..close();
    canvas.drawPath(
      inner,
      Paint()..color = AppColors.background.withValues(alpha: 0.35),
    );

    // Star.
    final c = Offset(w * 0.5, h * 0.46);
    final r = w * 0.15;
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = Colors.white);

    // One chevron per league level above Bronze.
    final chevron = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    final count = league.index;
    for (var i = 0; i < math.min(count, 3); i++) {
      final y = h * (0.66 + i * 0.06);
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.4, y)
          ..lineTo(w * 0.5, y + h * 0.035)
          ..lineTo(w * 0.6, y),
        chevron,
      );
    }
    if (count > 3) {
      for (final dx in [-0.12, 0.12]) {
        canvas.drawCircle(
          Offset(w * (0.5 + dx), h * 0.3),
          w * 0.025,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LeagueBadgeArt old) => old.league != league;
}

/// Round avatar with initials, coloured from a seed.
class TraderAvatar extends StatelessWidget {
  const TraderAvatar({
    super.key,
    required this.name,
    required this.seed,
    this.isYou = false,
  });

  final String name;
  final int seed;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    const palette = [
      Color(0xFF38BDF8),
      Color(0xFF34D399),
      Color(0xFFF472B6),
      Color(0xFFA78BFA),
      Color(0xFFFB923C),
      Color(0xFF22D3EE),
      Color(0xFFFACC15),
      Color(0xFFF87171),
    ];
    final color = isYou ? AppColors.gold : palette[seed % palette.length];
    final initials = name.replaceAll(RegExp(r'[^A-Z]'), '');
    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(
        isYou
            ? 'You'
            : (initials.isEmpty
                  ? name[0]
                  : initials.substring(0, math.min(2, initials.length))),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: isYou ? 10 : 12,
        ),
      ),
    );
  }
}
