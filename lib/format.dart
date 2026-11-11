/// Small formatting helpers (kept dependency-free).
String money(double value, {bool signed = false}) {
  final sign = value < 0 ? '−' : (signed && value > 0 ? '+' : '');
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$sign\$$whole.${parts[1]}';
}

/// Short money for small tiles: "$9,850", "$10k", "$12.4k", "$1.2M".
String compactMoney(double value) {
  final sign = value < 0 ? '−' : '';
  final v = value.abs();
  String trim(double x) {
    final s = x.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  if (v >= 1000000) return '$sign\$${trim(v / 1000000)}M';
  if (v >= 10000) return '$sign\$${trim(v / 1000)}k';
  final whole = money(value.roundToDouble());
  return whole.substring(0, whole.length - 3); // drop ".00"
}

String quantity(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String rMultiple(double value) =>
    '${value >= 0 ? '+' : '−'}${value.abs().toStringAsFixed(1)}R';
