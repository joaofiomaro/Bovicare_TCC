import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

enum BadgeType { success, danger, warning, info, neutral }

/// Badge de status colorido — ex: "Saudável", "Doente", "Prenha".
class AppBadge extends StatelessWidget {
  const AppBadge({required this.label, this.type = BadgeType.neutral, super.key});

  final String label;
  final BadgeType type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.fullAll),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.2)),
    );
  }

  (Color, Color) get _colors => switch (type) {
    BadgeType.success => (AppColors.successLight, AppColors.success),
    BadgeType.danger  => (AppColors.dangerLight,  AppColors.danger),
    BadgeType.warning => (AppColors.amberLight,   AppColors.amber),
    BadgeType.info    => (AppColors.infoLight,    AppColors.info),
    BadgeType.neutral => (AppColors.brandPale,    AppColors.mutedGreen),
  };
}
