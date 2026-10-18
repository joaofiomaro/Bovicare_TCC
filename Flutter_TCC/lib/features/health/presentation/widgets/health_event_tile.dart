import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../domain/entities/health_event.dart';

/// Linha de um evento de manejo na ficha do animal.
class HealthEventTile extends StatelessWidget {
  const HealthEventTile({required this.event, super.key});

  final HealthEvent event;

  static IconData iconFor(HealthEventType type) => switch (type) {
        HealthEventType.deworming          => Icons.medication_liquid_outlined,
        HealthEventType.medication         => Icons.medication_outlined,
        HealthEventType.observation        => Icons.edit_note_rounded,
        HealthEventType.pregnancyDiagnosis => Icons.favorite_rounded,
        HealthEventType.birth              => Icons.child_friendly_outlined,
        HealthEventType.pregnancyLoss      => Icons.heart_broken_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final end = event.withdrawalEnd;
    final meta = [
      event.date.toBrDate,
      if (event.dose != null) event.dose!,
      if (event.veterinarianName != null) event.veterinarianName!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  36,
            height: 36,
            decoration: const BoxDecoration(
              color:        AppColors.brandLight,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Icon(iconFor(event.type), color: AppColors.brandGreen, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.type == HealthEventType.observation ||
                          event.type.isReproductive
                      ? event.title
                      : '${event.type.label} — ${event.title}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedGreen,
                      ),
                ),
                if (end != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.block_rounded, size: 12, color: AppColors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Carência até ${end.toBrDate}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:      AppColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
                if (event.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.notes!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
