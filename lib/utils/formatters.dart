// Italian locale helpers — no decimal package needed.
// FIX #8: integer arithmetic only (priceCents, quantityMilli).

/// Format price in cents as Italian currency string: "€ 12,50"
String formatPrice(int cents) {
  final euros = cents ~/ 100;
  final remainder = cents % 100;
  return '€ $euros,${remainder.toString().padLeft(2, '0')}';
}

/// Format quantityMilli (quantity × 1000) as Italian decimal: "1,5"
/// FIX #5: integer quantityMilli, no floats stored — conversion only for display.
String formatQty(int quantityMilli) {
  if (quantityMilli % 1000 == 0) {
    return (quantityMilli ~/ 1000).toString();
  }
  // Two decimal places max; trim trailing zeros
  final whole = quantityMilli ~/ 1000;
  final frac  = quantityMilli % 1000;
  if (frac % 100 == 0) {
    return '$whole,${(frac ~/ 100)}';
  }
  if (frac % 10 == 0) {
    return '$whole,${(frac ~/ 10).toString().padLeft(2, '0')}';
  }
  return '$whole,${frac.toString().padLeft(3, '0')}';
}

/// Parse Italian decimal string ("1,5" or "1.5") → quantityMilli integer.
/// Returns 0 if invalid.
int parseQtyToMilli(String text) {
  final normalised = text.trim().replaceAll(',', '.');
  final val = double.tryParse(normalised) ?? 0;
  if (val <= 0) return 0;
  return (val * 1000).round();
}

/// Italian month names for history grouping
const _months = [
  '', 'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
  'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
];

/// Returns Italian date group label: 'Oggi', 'Ieri', or '12 marzo 2026'
String dateGroupLabel(DateTime dt) {
  final local = dt.toLocal();
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day   = DateTime(local.year, local.month, local.day);
  if (day == today) return 'Oggi';
  if (day == today.subtract(const Duration(days: 1))) return 'Ieri';
  return '${local.day} ${_months[local.month]} ${local.year}';
}

/// Format time as 24h: "14:30" (Europe/Rome local time)
String formatTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// Format date as dd/MM/yyyy
String formatDate(DateTime dt) {
  final local = dt.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
