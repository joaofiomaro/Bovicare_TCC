import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../domain/entities/service_call.dart';
import '../extensions/service_call_visuals.dart';

/// Cartão de um chamado — usado no pool, nas listas do vet e do produtor.
class ServiceCallTile extends StatelessWidget {
  const ServiceCallTile({
    required this.call,
    this.onTap,
    this.trailing,
    super.key,
  });

  final ServiceCall call;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color:        isDark ? AppColors.darkSurface : AppColors.white,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: InkWell(
        onTap:        onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      call.title,
                      maxLines:  1,
                      overflow:  TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppBadge(
                    label: call.urgency.label,
                    type:  call.urgency.badge,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                call.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedGreen,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size:  13,
                    color: AppColors.mutedGreen,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${call.producerName} · ${call.city}/${call.state}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedGreen,
                          ),
                    ),
                  ),
                  AppBadge(label: call.status.label, type: call.status.badge),
                ],
              ),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                trailing!,
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  call.createdAt.toRelative,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:    AppColors.mutedGreen,
                        fontSize: 11,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
