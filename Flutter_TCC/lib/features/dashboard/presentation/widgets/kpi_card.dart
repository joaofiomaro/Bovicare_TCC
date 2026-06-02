import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';

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
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgColor  = isAccent
        ? AppColors.brandGreen
        : (isDark ? AppColors.darkSurface : AppColors.white);
    final labelCol = isAccent ? Colors.white70 : AppColors.mutedGreen;
    final valueCol = valueColor ??
        (isAccent ? Colors.white : Theme.of(context).colorScheme.onSurface);
    final subCol   = isAccent ? Colors.white60 : AppColors.mutedGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.lgAll,
        border: isAccent
            ? null
            : Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
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
                    color: isAccent ? Colors.white70 : AppColors.brandGreen),
                const SizedBox(width: 3),
                Text(trend!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isAccent ? Colors.white70 : AppColors.brandGreen,
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
