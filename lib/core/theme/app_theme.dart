import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Modern Color Palette
  static const Color _primaryIndigo = Color(0xFF6366F1);
  static const Color _secondaryViolet = Color(0xFF8B5CF6);
  static const Color _bgLight = Color(0xFFF9FAFB);
  static const Color _bgDark = Color(0xFF0F172A);
  static const Color _surfaceDark = Color(0xFF1E293B);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryIndigo,
      brightness: brightness,
      primary: _primaryIndigo,
      secondary: _secondaryViolet,
      surface: isDark ? _surfaceDark : Colors.white,
      onSurface: isDark ? Colors.white : const Color(0xFF1E293B),
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? _bgDark : _bgLight,
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            width: 1,
          ),
        ),
        color: isDark ? _surfaceDark : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF334155) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _primaryIndigo, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? _bgDark : Colors.white,
        indicatorColor: _primaryIndigo.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
