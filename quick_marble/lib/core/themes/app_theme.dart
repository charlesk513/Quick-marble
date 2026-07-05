import 'package:flutter/material.dart';

/// Brand palette derived from the Quick Marble & Granite logo:
/// black backdrop with red, gold, and green accents.
class AppColors {
  AppColors._();

  static const Color black = Color(0xFF121212);
  static const Color red = Color(0xFFE31E24);
  static const Color gold = Color(0xFFFFD400);
  static const Color green = Color(0xFF2ECC40);

  static const Color surfaceLight = Color(0xFFF7F7F8);
  static const Color surfaceDark = Color(0xFF1B1B1D);

  // Status colors reused across quotations/contracts
  static const Color statusDraft = Color(0xFF9E9E9E);
  static const Color statusPending = gold;
  static const Color statusApproved = green;
  static const Color statusRejected = red;
  static const Color statusActive = green;
  static const Color statusCompleted = Color(0xFF1565C0);
  static const Color statusCancelled = red;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: brightness,
      primary: AppColors.green,
      secondary: AppColors.gold,
      error: AppColors.red,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Maps a quotation/contract status string to its brand color.
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return AppColors.statusDraft;
      case 'pending':
        return AppColors.statusPending;
      case 'approved':
      case 'active':
        return AppColors.statusApproved;
      case 'rejected':
      case 'cancelled':
        return AppColors.statusRejected;
      case 'completed':
        return AppColors.statusCompleted;
      default:
        return AppColors.statusDraft;
    }
  }
}
