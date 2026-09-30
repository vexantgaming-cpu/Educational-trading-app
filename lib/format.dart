/// Small formatting helpers (kept dependency-free).
String money(double value, {bool signed = false}) {
  final sign = value < 0 ? '−' : (signed && value > 0 ? '+' : '');
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '$sign\$$whole.${parts[1]}';
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
