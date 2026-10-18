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
                if (weighings.length >= 2) ...[
                  const SizedBox(height: AppSpacing.base),
                  SizedBox(
                    height: 120,
                    width:  double.infinity,
                    child:  WeightChart(weighings: weighings),
                  ),
                ],
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

/// Gráfico de linha do peso ao longo do tempo (eixo X proporcional às datas).
/// Desenhado com CustomPaint para não adicionar dependência de gráficos.
class WeightChart extends StatelessWidget {
  const WeightChart({required this.weighings, super.key});

  /// Em qualquer ordem — o gráfico ordena cronologicamente.
  final List<Weighing> weighings;

  @override
  Widget build(BuildContext context) {
    final sorted = [...weighings]..sort((a, b) => a.date.compareTo(b.date));
    final minKg  = sorted.map((w) => w.weightKg).reduce((a, b) => a < b ? a : b);
    final maxKg  = sorted.map((w) => w.weightKg).reduce((a, b) => a > b ? a : b);

    return Semantics(
      label: 'Gráfico de peso de ${minKg.toStringAsFixed(0)} a '
          '${maxKg.toStringAsFixed(0)} kg',
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _axisLabel(context, '${maxKg.toStringAsFixed(0)} kg'),
              _axisLabel(context, '${minKg.toStringAsFixed(0)} kg'),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    size:    Size.infinite,
                    painter: _WeightChartPainter(sorted),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _axisLabel(context, sorted.first.date.toBrDate),
                    _axisLabel(context, sorted.last.date.toBrDate),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _axisLabel(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:    AppColors.mutedGreen,
              fontSize: 10,
            ),
      );
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter(this.points);

  /// Ordenados cronologicamente; pelo menos 2.
  final List<Weighing> points;

  @override
  void paint(Canvas canvas, Size size) {
    final first = points.first.date;
    final spanMs = points.last.date.difference(first).inMilliseconds;
    final minKg = points.map((w) => w.weightKg).reduce((a, b) => a < b ? a : b);
    final maxKg = points.map((w) => w.weightKg).reduce((a, b) => a > b ? a : b);
    final rangeKg = maxKg - minKg;

    Offset toOffset(Weighing w, int index) {
      final x = spanMs == 0
          ? size.width * index / (points.length - 1)
          : size.width * w.date.difference(first).inMilliseconds / spanMs;
      // Margem de 6 px para o marcador não ser cortado nas bordas.
      final y = rangeKg == 0
          ? size.height / 2
          : 6 + (size.height - 12) * (1 - (w.weightKg - minKg) / rangeKg);
      return Offset(x, y);
    }

    final offsets = [
      for (var i = 0; i < points.length; i++) toOffset(points[i], i),
    ];

    final grid = Paint()
      ..color = AppColors.ghostGreen.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, 0), grid)
      ..drawLine(Offset(0, size.height), Offset(size.width, size.height), grid);

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }

    final fill = Path.from(path)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();
    canvas
      ..drawPath(
        fill,
        Paint()..color = AppColors.brandGreen.withValues(alpha: 0.12),
      )
      ..drawPath(
        path,
        Paint()
          ..color = AppColors.brandGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );

    final dot = Paint()..color = AppColors.brandGreen;
    for (final o in offsets) {
      canvas.drawCircle(o, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_WeightChartPainter oldDelegate) =>
      oldDelegate.points != points;
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
