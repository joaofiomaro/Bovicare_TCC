import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../domain/entities/vet_entity.dart';
import '../../domain/repositories/vet_repository.dart';

class VetCard extends StatelessWidget {
  const VetCard({
    required this.vet,
    required this.onTap,
    this.animationIndex = 0,
    super.key,
  });

  final VetEntity    vet;
  final VoidCallback onTap;
  final int          animationIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap:        onTap,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Container(
        padding:    const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border:       Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
          ),
        ),
        child: Row(
          children: [
            _VetAvatar(isAvailable: vet.isAvailable),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vet.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vet.specialties.join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedGreen,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size:  11,
                        color: AppColors.mutedGreen,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          _distanceLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedGreen,
                                fontSize: 11,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppBadge(
                  label: vet.isAvailable ? 'Disponível' : 'Ocupado',
                  type:  vet.isAvailable ? BadgeType.success : BadgeType.warning,
                ),
                // Perfis fictícios do protótipo ficam sempre identificados.
                if (vet.isDemo) ...[
                  const SizedBox(height: 4),
                  const AppBadge(label: 'Demonstração'),
                ],
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationIndex * 50))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
  }

  String get _distanceLabel {
    final dist = vet.distanceKm;
    final distStr = dist != null
        ? '${dist < 1 ? '<1' : dist.toStringAsFixed(0)} km · '
        : '';
    return '$distStr${vet.crmv}';
  }
}

class _VetAvatar extends StatelessWidget {
  const _VetAvatar({required this.isAvailable});
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  48,
      height: 48,
      decoration: BoxDecoration(
        color:  isAvailable ? AppColors.brandLight : AppColors.amberLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: isAvailable
              ? AppColors.brandGreen.withValues(alpha: 0.3)
              : AppColors.amber.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.medical_services_outlined,
        color: isAvailable ? AppColors.brandGreen : AppColors.amber,
        size:  22,
      ),
    );
  }
}
