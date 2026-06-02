import 'package:flutter/material.dart';

/// Paleta de cores do BoviCare — fiel ao design system do protótipo web.
/// Todas as cores são imutáveis e referenciadas via `AppColors.nome`.
abstract final class AppColors {
  // --- Marca (Verde BoviCare) ---
  static const Color brandGreen = Color(0xFF1C6B3A);
  static const Color brandLight = Color(0xFFE8F5EE);
  static const Color brandPale  = Color(0xFFF2FAF5);
  static const Color brandDeep  = Color(0xFF134D29);

  // --- Neutros ---
  static const Color inkBlack    = Color(0xFF0F1F16);
  static const Color mutedGreen  = Color(0xFF6B8070);
  static const Color ghostGreen  = Color(0xFFB8CCBF);
  static const Color surfaceLight = Color(0xFFF8FBF9);
  static const Color white        = Color(0xFFFFFFFF);

  // --- Semânticas ---
  static const Color danger      = Color(0xFF8B1A1A);
  static const Color dangerLight = Color(0xFFFFF0F0);
  static const Color amber       = Color(0xFFA07000);
  static const Color amberLight  = Color(0xFFFFF8E6);
  static const Color info        = Color(0xFF1A56A0);
  static const Color infoLight   = Color(0xFFEEF4FF);
  static const Color success     = Color(0xFF1C6B3A);
  static const Color successLight = Color(0xFFE8F5EE);

  // --- Dark Mode ---
  static const Color darkBackground  = Color(0xFF0D1A12);
  static const Color darkSurface     = Color(0xFF152B1E);
  static const Color darkSurface2    = Color(0xFF1C3828);
  static const Color darkBorder      = Color(0xFF2A4A35);
  static const Color darkText        = Color(0xFFE0EDE5);
  static const Color darkTextMuted   = Color(0xFF8AAE98);

  // --- Transparências utilitárias ---
  static const Color overlayDark  = Color(0x80000000);
  static const Color overlayLight = Color(0x40FFFFFF);
}
