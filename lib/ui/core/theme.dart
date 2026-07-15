import 'package:flutter/material.dart';

/// Material 3 theming for Track Team. Follows the system light/dark setting.
abstract final class AppTheme {
  static const _seed = Color(0xFF00695C); // deep teal, public-health tone

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        isDense: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Status colors are semantic, not part of the scheme.
  static Color statusColor(String status, Brightness brightness) {
    final online = brightness == Brightness.dark
        ? const Color(0xFF66BB6A)
        : const Color(0xFF2E7D32);
    final offline = brightness == Brightness.dark
        ? const Color(0xFF9E9E9E)
        : const Color(0xFF757575);
    return status.toUpperCase() == 'ONLINE' ? online : offline;
  }
}
