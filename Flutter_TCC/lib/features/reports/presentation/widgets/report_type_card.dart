import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_palette.dart';
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
    final (iconData, iconColor, iconBg) = _iconProps(type, context.palette);

    return Material(
      color:        isDark ? AppColors.darkSurface : context.palette.card,
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
              color: isDark ? AppColors.darkBorder : context.palette.border,
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
                            color: context.palette.muted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isLoading)
                SizedBox(
                  width:  20,
                  height: 20,
                  child:  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:       context.palette.brand,
                  ),
                )
              else
                Icon(
                  Icons.download_rounded,
                  color: context.palette.brand,
                  size:  22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _iconProps(ReportType t, AppPalette p) => switch (t) {
    ReportType.sanitary     => (Icons.shield_outlined,          p.brand, p.brandTintStrong),
    ReportType.reproductive => (Icons.favorite_outline_rounded, p.brand, p.brandTintStrong),
    ReportType.financial    => (Icons.bar_chart_rounded,        p.amber, p.amberTint),
    ReportType.sales        => (Icons.sell_outlined,            p.brand, p.brandTintStrong),
    ReportType.inventory    => (Icons.list_alt_rounded,         p.muted, p.brandTint),
  };
}
