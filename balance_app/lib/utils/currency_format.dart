/// Parses a stored amount string (e.g. "-BDT 80", "+USD 1,234.56") to a signed double.
double parseAmountFromStored(String amountStr) {
  final cleaned = amountStr.replaceAll(RegExp(r'[^\d.-]'), '').trim();
  if (cleaned.isEmpty) return 0;
  final neg = amountStr.trimLeft().startsWith('-');
  final v = double.tryParse(cleaned) ?? 0;
  return neg ? -v : v;
}

/// Formats a numeric amount with the given ISO currency code (e.g. "USD", "EUR").
/// Uses code prefix: "-USD 80.00", "USD 1,234.56" (no plus for positive).
String formatAmountWithCurrency(double value, String currencyCode) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  final intPart = abs.floor();
  final dec = abs - intPart;
  final formatted = intPart.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  final decimals = (dec > 0.001)
      ? '.${(dec * 100).round().toString().padLeft(2, '0')}'
      : '';
  return '$sign$currencyCode $formatted$decimals';
}

/// Parses a stored amount string and re-formats it with the given currency code.
String formatStoredAmountWithCurrency(String amountStr, String currencyCode) {
  final value = parseAmountFromStored(amountStr);
  return formatAmountWithCurrency(value, currencyCode);
}
