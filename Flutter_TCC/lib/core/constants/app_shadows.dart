import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Sombras padronizadas do design system.
abstract final class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Sombra verde sutil para cards de destaque.
  static final List<BoxShadow> brand = [
    BoxShadow(
      color: AppColors.brandGreen.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
