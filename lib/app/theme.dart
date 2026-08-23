import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema centralizado do Auto em Dia (Material 3).
/// Baseado no design system moderno (Tech Blue, Space Grotesk, Geist).
abstract final class AppTheme {
  // Paleta de marca
  static const primaryColor = Color(0xFF2751D9);
  static const primaryLight = Color(0xFF2563EB);
  static const primaryContainerColor = Color(0xFFDDE1FF);
  static const onPrimaryContainerColor = Color(0xFF001453);
  
  static const backgroundColor = Color(0xFFF8FAFC);
  static const surfaceColor = Color(0xFFFFFFFF);
  static const surfaceContainerHighColor = Color(0xFFF1F5F9);
  static const surfaceVariantColor = Color(0xFFE2E8F0);
  
  static const borderSubtleColor = Color(0xFFE2E8F0);
  static const outlineVariantColor = Color(0xFFCBD5E1);
  
  static const textPrimaryColor = Color(0xFF0F172A);
  static const textMutedColor = Color(0xFF64748B);
  
  static const successColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);
  static const tertiaryColor = Color(0xFF891E00);

  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF1D4ED8) : primaryContainerColor,
      onPrimaryContainer: isDark ? Colors.white : onPrimaryContainerColor,
      secondary: const Color(0xFF64748B),
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      onSecondaryContainer: isDark ? Colors.white : const Color(0xFF1E293B),
      tertiary: tertiaryColor,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFDBD2),
      onTertiaryContainer: const Color(0xFF3C0800),
      error: errorColor,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF93000A),
      surface: isDark ? const Color(0xFF0F172A) : surfaceColor,
      onSurface: isDark ? const Color(0xFFF8FAFC) : textPrimaryColor,
      surfaceContainerLowest: isDark ? const Color(0xFF0B0F19) : Colors.white,
      surfaceContainerLow: isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC),
      surfaceContainer: isDark ? const Color(0xFF1E293B) : Colors.white,
      surfaceContainerHigh: isDark ? const Color(0xFF334155) : surfaceContainerHighColor,
      surfaceContainerHighest: isDark ? const Color(0xFF475569) : surfaceVariantColor,
      onSurfaceVariant: isDark ? const Color(0xFF94A3B8) : textMutedColor,
      outline: const Color(0xFF94A3B8),
      outlineVariant: isDark ? const Color(0xFF334155) : borderSubtleColor,
    );

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        height: 56 / 48,
        letterSpacing: -0.02 * 48,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        height: 44 / 36,
        letterSpacing: -0.02 * 36,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.01 * 32,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        height: 28 / 18,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.02 * 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        height: 16 / 11,
        letterSpacing: 0.05 * 11,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : backgroundColor,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.inter(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 15,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
        elevation: 0,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? primaryColor
                : colorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primaryColor
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
