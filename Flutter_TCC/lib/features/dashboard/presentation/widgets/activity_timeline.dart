import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../domain/entities/activity_item.dart';

/// Timeline vertical de atividades recentes, fiel ao protótipo web.
class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({required this.activities, super.key});

  final List<ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const AppEmptyState(
        icon: Icons.history_rounded,
        title: 'Nenhuma atividade',
        subtitle: 'As ações recentes aparecerão aqui.',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (int i = 0; i < activities.length; i++)
            _TimelineRow(
              item:   activities[i],
              isLast: i == activities.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});

  final ActivityItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isDark ? AppColors.brandLight : AppColors.brandGreen;
    final lineColor = isDark ? AppColors.darkBorder : AppColors.ghostGreen;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spine: ponto + linha vertical
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Conteúdo
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [item.date.toTimelineLabel, if (item.subtitle != null) item.subtitle!]
                        .join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedGreen,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
