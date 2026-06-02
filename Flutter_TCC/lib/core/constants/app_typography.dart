import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Escala tipográfica Material 3 com Plus Jakarta Sans.
/// Referenciada pelo ThemeData via AppTypography.textTheme.
abstract final class AppTypography {
  static TextTheme textTheme(Color textColor) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      // Display
      displayLarge:  base.displayLarge?.copyWith(color: textColor, fontWeight: FontWeight.w700, fontSize: 57),
      displayMedium: base.displayMedium?.copyWith(color: textColor, fontWeight: FontWeight.w700, fontSize: 45),
      displaySmall:  base.displaySmall?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 36),
      // Headline
      headlineLarge:  base.headlineLarge?.copyWith(color: textColor, fontWeight: FontWeight.w700, fontSize: 32),
      headlineMedium: base.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 28),
      headlineSmall:  base.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 24),
      // Title
      titleLarge:  base.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 22),
      titleMedium: base.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall:  base.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
      // Body
      bodyLarge:  base.bodyLarge?.copyWith(color: textColor, fontWeight: FontWeight.w400, fontSize: 16),
      bodyMedium: base.bodyMedium?.copyWith(color: textColor, fontWeight: FontWeight.w400, fontSize: 14),
      bodySmall:  base.bodySmall?.copyWith(color: textColor, fontWeight: FontWeight.w400, fontSize: 12),
      // Label
      labelLarge:  base.labelLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium: base.labelMedium?.copyWith(color: textColor, fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall:  base.labelSmall?.copyWith(color: textColor, fontWeight: FontWeight.w500, fontSize: 11),
    );
  }

  /// Estilo customizado para KPI cards (número grande animado).
  static TextStyle kpiNumber(Color color) => GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: color,
  );

  /// Estilo para labels de status/badge.
  static TextStyle badgeLabel(Color color) => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.2,
  );

  static TextStyle get muted => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedGreen,
  );
}
