import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

/// Barra de progresso com label, percentual e cor customizável.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.label,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.showPercent = false,
    super.key,
  }) : assert(value >= 0 && value <= 1, 'value deve estar entre 0.0 e 1.0');

  /// Valor entre 0.0 e 1.0.
  final double value;
  final String? label;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = color ?? AppColors.brandGreen;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurface2 : AppColors.brandPale);
    final percent = (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercent)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextMuted : AppColors.mutedGreen,
                    ),
                  ),
                if (showPercent)
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: AppRadius.fullAll,
          child: Stack(
            children: [
              Container(
                height: height,
                width: double.infinity,
                color: bgColor,
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: AppRadius.fullAll,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
