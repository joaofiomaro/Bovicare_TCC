import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/report_data.dart';

class ReportTypeCard extends StatelessWidget {
  const ReportTypeCard({
    required this.type,
    required this.onGenerate,
    this.isLoading = false,
    super.key,
  });

  final ReportType   type;
  final VoidCallback onGenerate;
  final bool         isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (iconData, iconColor, iconBg) = _iconProps(type);

    return Material(
      color:        isDark ? AppColors.darkSurface : AppColors.white,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: InkWell(
        onTap:        isLoading ? null : onGenerate,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical:   AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
            ),
          ),
          child: Row(
            children: [
              Container(
                width:  40,
                height: 40,
                decoration: BoxDecoration(
                  color:        iconBg,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedGreen,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isLoading)
                const SizedBox(
                  width:  20,
                  height: 20,
                  child:  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:       AppColors.brandGreen,
                  ),
                )
              else
                const Icon(
                  Icons.download_rounded,
                  color: AppColors.brandGreen,
                  size:  22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _iconProps(ReportType t) => switch (t) {
    ReportType.sanitary     => (Icons.shield_outlined,        AppColors.brandGreen, AppColors.brandLight),
    ReportType.reproductive => (Icons.favorite_outline_rounded, AppColors.brandGreen, AppColors.brandLight),
    ReportType.financial    => (Icons.bar_chart_rounded,      AppColors.amber,      AppColors.amberLight),
    ReportType.inventory    => (Icons.list_alt_rounded,       AppColors.mutedGreen, AppColors.brandPale),
  };
}
