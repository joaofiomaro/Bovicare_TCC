import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../domain/entities/weighing.dart';
import '../providers/weighings_provider.dart';

/// Resumo da evolução de peso de um animal (peso atual, ganho total, GMD)
/// + histórico de pesagens. Some quando não há pesagens registradas.
class WeightEvolutionSection extends ConsumerWidget {
  const WeightEvolutionSection({required this.animalId, super.key});

  final String animalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weighings = ref.watch(animalWeighingsProvider(animalId));

    return weighings.maybeWhen(
      data: (list) => list.isEmpty
          ? const SizedBox.shrink()
          : _Content(weighings: list),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.weighings});

  /// Lista já ordenada da mais recente para a mais antiga.
  final List<Weighing> weighings;

  @override
  Widget build(BuildContext context) {
    final gmd        = weighings.gmd;
    final totalGain  = weighings.totalGain;
    final lastWeight = weighings.lastWeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: _SectionLabel('Evolução de peso'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color:        AppColors.brandPale,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(
                color: AppColors.brandGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _Stat(
                      label: 'Atual',
                      value: lastWeight != null
                          ? '${lastWeight.toStringAsFixed(0)} kg'
                          : '—',
                    ),
                    _Stat(
                      label: 'Ganho total',
                      value: weighings.length < 2
                          ? '—'
                          : '${totalGain >= 0 ? '+' : ''}'
                              '${totalGain.toStringAsFixed(0)} kg',
                    ),
                    _Stat(
                      label: 'GMD',
                      value: gmd != null
                          ? '${gmd.toStringAsFixed(2)} kg/dia'
                          : '—',
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                ...weighings.take(5).map((w) => _WeighingRow(weighing: w)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:      AppColors.brandGreen,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGreen,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeighingRow extends StatelessWidget {
  const _WeighingRow({required this.weighing});
  final Weighing weighing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            weighing.date.toBrDate,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGreen,
                ),
          ),
          Text(
            '${weighing.weightKg.toStringAsFixed(0)} kg',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
