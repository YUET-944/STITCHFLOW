/// ─────────────────────────────────────────────────────────────────────────────
///  StitchFlow Global Constants
///  Change currency here ONCE and it updates everywhere automatically.
/// ─────────────────────────────────────────────────────────────────────────────

class AppCurrency {
  AppCurrency._(); // non-instantiable

  /// ISO 4217 currency code shown in labels & invoices
  static const String code = 'PKR';

  /// Symbol displayed inline with amounts
  static const String symbol = 'Rs.';

  /// Locale used for NumberFormat (optional — enable if you add intl package)
  static const String locale = 'ur_PK';

  /// ── Formatting helpers ────────────────────────────────────────────────────

  /// e.g.  Rs. 25,000
  static String format(num amount) =>
      '$symbol ${_thousands(amount.round())}';

  /// e.g.  Rs. 25,000 PKR
  static String formatFull(num amount) =>
      '$symbol ${_thousands(amount.round())} $code';

  /// e.g.  25,000 PKR  (no symbol, useful for tables)
  static String formatCode(num amount) =>
      '${_thousands(amount.round())} $code';

  /// e.g.  +Rs. 10,000  or  -Rs. 5,000
  static String formatSigned(num amount) {
    final sign = amount >= 0 ? '+' : '-';
    return '$sign$symbol ${_thousands(amount.abs().round())}';
  }

  /// Compact form: 25k, 1.2L (lakh)
  static String compact(num amount) {
    if (amount >= 100000) {
      final lac = amount / 100000;
      return '$symbol ${lac.toStringAsFixed(lac == lac.roundToDouble() ? 0 : 1)}L';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      return '$symbol ${k.toStringAsFixed(k == k.roundToDouble() ? 0 : 1)}k';
    }
    return format(amount);
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  static String _thousands(int n) {
    final s = n.abs().toString();
    final sign = n < 0 ? '-' : '';
    // Pakistani number grouping: last 3 then groups of 2
    if (s.length <= 3) return '$sign$s';
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final groups = <String>[];
    for (var i = rest.length; i > 0; i -= 2) {
      groups.insert(0, rest.substring(i < 2 ? 0 : i - 2, i));
    }
    final joined = groups.join(',');
    return '$sign$joined,$last3';
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  Other App-Wide Constants
/// ─────────────────────────────────────────────────────────────────────────────

class AppConstants {
  AppConstants._();

  /// Base URL for API (10.0.2.2 = localhost from Android emulator)
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api/v1';

  /// Mock OTP for development (remove in production)
  static const String devOtp = '123456';

  /// Max garments per order
  static const int maxGarmentsPerOrder = 10;

  /// Auto-approve requirements after N hours
  static const int requirementsAutoApproveHours = 24;

  /// Support WhatsApp number
  static const String supportWhatsApp = '+923001234567';
}
