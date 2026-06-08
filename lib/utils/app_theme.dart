import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4A90D9);
  static const primaryDark = Color(0xFF1A3C6E);
  static const secondary = Color(0xFF2ECC71);
  static const danger = Color(0xFFE74C3C);
  static const warning = Color(0xFFF39C12);
  static const surface = Color(0xFFF5F7FA);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);

  // Category colors
  static const electricity = Color(0xFFF59E0B);
  static const water = Color(0xFF3B82F6);
  static const internet = Color(0xFF8B5CF6);
  static const supplies = Color(0xFF10B981);
  static const other = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

class AppConstants {
  static const List<String> expenseCategories = [
    'electricity',
    'water',
    'internet',
    'supplies',
    'other',
  ];

  static const Map<String, String> categoryLabels = {
    'electricity': 'Tiền điện',
    'water': 'Tiền nước',
    'internet': 'Internet',
    'supplies': 'Đồ dùng',
    'other': 'Khác',
  };

  static const Map<String, IconData> categoryIcons = {
    'electricity': Icons.bolt,
    'water': Icons.water_drop,
    'internet': Icons.wifi,
    'supplies': Icons.shopping_bag,
    'other': Icons.more_horiz,
  };

  static Color categoryColor(String cat) {
    switch (cat) {
      case 'electricity':
        return AppColors.electricity;
      case 'water':
        return AppColors.water;
      case 'internet':
        return AppColors.internet;
      case 'supplies':
        return AppColors.supplies;
      default:
        return AppColors.other;
    }
  }
}

// Format tiền VND
String formatVND(double amount) {
  final formatted = amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return '$formatted đ';
}
