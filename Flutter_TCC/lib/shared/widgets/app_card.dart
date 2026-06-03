import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_shadows.dart';

enum AppCardVariant { elevated, outlined }

/// Card padronizado do design system com variantes elevated e outlined.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.onTap,
    this.padding,
    this.margin,
    super.key,
  });

  final Widget child;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final decoration = switch (variant) {
      AppCardVariant.elevated => BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppRadius.lgAll,
          boxShadow: AppShadows.md,
        ),
      AppCardVariant.outlined => BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
          ),
        ),
    };

    return Container(
      margin: margin,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
    );
  }
}
