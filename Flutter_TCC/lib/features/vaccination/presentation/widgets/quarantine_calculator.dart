import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/vaccine_info.dart';

/// Card informativo que recalcula dinamicamente próxima dose e fim de carência
/// conforme o usuário preenche o formulário de vacinação.
class QuarantineCalculator extends StatelessWidget {
  const QuarantineCalculator({
    required this.vaccineName,
    required this.dose,
    required this.applicationDate,
    super.key,
  });

  final String    vaccineName;
  final String    dose;
  final DateTime? applicationDate;

  @override
  Widget build(BuildContext context) {
    if (applicationDate == null) return const SizedBox.shrink();

    final quarantineDays = VaccineInfo.quarantineDaysFor(vaccineName);
    final quarantineEnd  = quarantineDays > 0
        ? applicationDate!.add(Duration(days: quarantineDays))
        : null;
    final nextDose = VaccineInfo.nextDoseFor(applicationDate!, dose);

    return Container(
      padding:    const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        context.palette.brandTint,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border:       Border.all(
          color: AppColors.brandGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: context.palette.brand,
                size:  18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Cálculo automático',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color:      context.palette.brand,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (nextDose != null)
            _InfoRow(
              label: 'Próxima dose',
              value: nextDose.toBrDate,
              icon:  Icons.vaccines_outlined,
            ),
          if (quarantineEnd != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              label: 'Carência até',
              value: '${quarantineEnd.toBrDate} ($quarantineDays dias)',
              icon:  Icons.block_rounded,
              color: context.palette.amber,
            ),
          ],
          if (quarantineEnd == null && nextDose == null)
            const _InfoRow(
              label: 'Sem carência',
              value: 'Vacina preventiva sem período de carência',
              icon:  Icons.check_circle_outline_rounded,
            ),
        ],
      ),
    );
  }

}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String   label;
  final String   value;
  final IconData icon;
  /// Padrão: verde da marca do tema atual.
  final Color?   color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.palette.brand;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: context.palette.muted),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color:      color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
