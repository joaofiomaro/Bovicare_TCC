import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/farm_alerts.dart';

/// Linha de alerta — toque abre a ficha do animal.
class FarmAlertTile extends StatelessWidget {
  const FarmAlertTile({required this.alert, super.key});

  final FarmAlert alert;

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = switch (alert.type) {
      FarmAlertType.vaccineOverdue =>
        (AppColors.danger, AppColors.dangerLight, Icons.vaccines_outlined),
      FarmAlertType.vaccineDue =>
        (AppColors.amber, AppColors.amberLight, Icons.vaccines_outlined),
      FarmAlertType.birthDue => (
          alert.severity == FarmAlertSeverity.high
              ? AppColors.danger
              : AppColors.brandGreen,
          alert.severity == FarmAlertSeverity.high
              ? AppColors.dangerLight
              : AppColors.brandLight,
          Icons.child_friendly_outlined,
        ),
      FarmAlertType.withdrawal =>
        (AppColors.info, AppColors.infoLight, Icons.block_rounded),
    };

    return InkWell(
      onTap: () => context.pushNamed(
        AppRoutes.animal,
        pathParameters: {'id': alert.animalId},
      ),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical:   AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width:  38,
              height: 38,
              decoration: BoxDecoration(
                color:        bg,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    alert.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ghostGreen,
              size:  20,
            ),
          ],
        ),
      ),
    );
  }
}
