import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: unused_import
export '../design/design_system.dart' show DS;
import '../utils/status_utils.dart';

class ATColors {
  static const primary     = Color(0xFF00A650);
  static const secondary   = Color(0xFF003DA5);
  static const background  = Color(0xFFF9FAFB);
  static const card        = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const error       = Color(0xFFEF4444);
  static const warning     = Color(0xFFF59E0B);
  static const success     = Color(0xFF10B981);
  static const info        = Color(0xFF3B82F6);

  static Color forRole(String role) {
    switch (role) {
      case 'admin':      return const Color(0xFF7C3AED);
      case 'directeur':  return secondary;
      case 'assistante': return const Color(0xFF0891B2);
      case 'agent_dml':  return warning;
      default:           return primary;
    }
  }

  // Délègue à status_utils.dart — source unique de vérité
  static Color forStatut(String statut) => statusColor(statut);
}

ThemeData buildATTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: ATColors.primary),
    textTheme: GoogleFonts.interTextTheme(),
    scaffoldBackgroundColor: ATColors.background,
    cardTheme: CardThemeData(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: ATColors.card,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ATColors.secondary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ATColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ATColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: ATColors.primary,
      unselectedItemColor: Color(0xFF9CA3AF),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

extension ATContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get cardBg => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get surfaceVariant => isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
  Color get textPrimary => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
  Color get textSecondary => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);
  Color get textMuted => isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);
  Color get borderColor => isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color get shimmerBase => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get shimmerHighlight => isDark ? const Color(0xFF475569) : const Color(0xFFF8FAFC);
  Color get subtleBg => isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF);
  Color get inputFill => isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  Color get dividerColor => isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
  Color get shadowColor => isDark ? Colors.black54 : Colors.black.withValues(alpha: 0.08);
}

/// Theme sombre — palette adaptee mais on garde le vert AT comme accent.
ThemeData buildATThemeDark() {
  const darkBg   = Color(0xFF0F172A);  // bleu-noir
  const darkCard = Color(0xFF1E293B);  // gris-bleu
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ATColors.primary,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: darkBg,
    cardTheme: CardThemeData(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: darkCard,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkCard,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ATColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ATColors.primary, width: 2),
      ),
      filled: true,
      fillColor: darkCard,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      selectedItemColor: ATColors.primary,
      unselectedItemColor: Color(0xFF6B7280),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
