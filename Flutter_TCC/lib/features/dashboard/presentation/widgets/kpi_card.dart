import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/theme/app_palette.dart';

/// Card de KPI com contador animado.
/// [isAccent] usa fundo verde (card de destaque). [valueColor] sobrescreve a cor do número.
class KpiCard extends StatelessWidget {
  const KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    this.icon,
    this.trend,
    this.isAccent = false,
    this.valueColor,
    this.delay = Duration.zero,
    super.key,
  });

  final String label;
  final int value;
  final String sub;
  final IconData? icon;
  final String? trend;
  final bool isAccent;
  final Color? valueColor;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final palette  = context.palette;
    final bgColor  = isAccent ? AppColors.brandGreen : palette.card;
    final labelCol = isAccent ? AppColors.onBrandMuted : palette.muted;
    final valueCol = valueColor ??
        (isAccent ? Colors.white : Theme.of(context).colorScheme.onSurface);
    final subCol   = isAccent ? AppColors.onBrandMuted : palette.muted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.lgAll,
        border: isAccent
            ? null
            : Border.all(
                color: palette.border,
              ),
        boxShadow: isAccent
            ? [
                BoxShadow(
                  color: AppColors.brandGreen.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: labelCol,
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 6),
          // Contador animado de 0 → value
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, animated, __) => Text(
              '$animated',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: valueCol,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(fontSize: 11, color: subCol)),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    size: 12,
                    color: isAccent ? AppColors.onBrandMuted : palette.brand),
                const SizedBox(width: 3),
                Text(trend!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isAccent ? AppColors.onBrandMuted : palette.brand,
                    )),
              ],
            ),
          ],
        ],
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
