const List<String> kMonthsPt = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Absolute month index (`year * 12 + monthIndex0based`) for [date].
int absoluteMonth(DateTime date) => date.year * 12 + (date.month - 1);

/// Absolute month index for the current date.
int currentAbsoluteMonth() => absoluteMonth(DateTime.now());

/// "Setembro 2026" style label for the absolute month index [abs].
String formatMonthLabel(int abs) {
  final mod = abs % 12; // Dart's % is already non-negative for a positive divisor.
  final year = (abs - mod) ~/ 12;
  return '${kMonthsPt[mod]} $year';
}

/// "R\$ 1.234,56" style label, matching pt-BR grouping.
String formatMoney(num value) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final dotIndex = fixed.indexOf('.');
  final intPart = fixed.substring(0, dotIndex);
  final decPart = fixed.substring(dotIndex + 1);

  final grouped = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final remaining = intPart.length - i;
    if (i > 0 && remaining % 3 == 0) grouped.write('.');
    grouped.write(intPart[i]);
  }

  return '${isNegative ? '-' : ''}R\$ $grouped,$decPart';
}

/// Reads a money amount the user typed, accepting both "1234,56" and
/// "1234.56". Returns null when the text isn't a usable positive amount —
/// the callers treat that as "don't submit", so it also rejects zero and
/// negatives instead of letting the backend do it.
double? parseMoney(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || value <= 0) return null;
  return value;
}

/// Deterministic hue (0-359) derived from a label, so the same person/card
/// name always gets the same tag/avatar color. "Nós" (the user) is pinned to
/// a fixed hue so it doesn't clash with the app's own accent color. The
/// yellow band (40-70) is skipped entirely: it reads poorly as a fill behind
/// white avatar text/icons.
int hueForLabel(String label) {
  if (label == 'Nós') return 258;
  var hash = 0;
  for (final unit in label.codeUnits) {
    hash = (hash * 31 + unit) % 330;
  }
  return hash < 40 ? hash : hash + 30;
}
