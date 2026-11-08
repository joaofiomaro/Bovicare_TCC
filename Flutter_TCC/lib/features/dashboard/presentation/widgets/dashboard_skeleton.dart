import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_adaptive_grid.dart';
import '../../../../shared/widgets/app_skeleton.dart';

/// Layout shimmer exibido enquanto os dados do dashboard são carregados.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Container(
            height: 130,
            color: const Color(0xFF1C6B3A),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 60, height: 12),
                      SizedBox(height: 6),
                      AppSkeleton(width: 140, height: 18),
                      SizedBox(height: 6),
                      AppSkeleton(width: 110, height: 11),
                    ],
                  ),
                ),
                AppSkeleton(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // KPI grid skeleton
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppAdaptiveGrid(
              children: [
                KpiCardSkeleton(),
                KpiCardSkeleton(),
                KpiCardSkeleton(),
                KpiCardSkeleton(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Módulos skeleton
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppSkeleton(height: 14, width: 80),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: AppSkeleton(height: 56),
            ),
          ],
          const SizedBox(height: 24),
          // Timeline skeleton
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppSkeleton(height: 14, width: 120),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: AppSkeleton(height: 44),
            ),
          ],
        ],
      ),
    );
  }
}
