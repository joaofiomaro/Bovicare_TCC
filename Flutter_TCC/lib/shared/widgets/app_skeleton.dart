import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_radius.dart';

/// Bloco de shimmer genérico para skeleton loading.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({this.width, this.height = 16, this.borderRadius, super.key});

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor:      isDark ? const Color(0xFF2A4A35) : const Color(0xFFE8F0EB),
      highlightColor: isDark ? const Color(0xFF3A5A45) : const Color(0xFFF5FAF6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? AppRadius.smAll,
        ),
      ),
    );
  }
}

/// Skeleton para um item da lista de animais.
class AnimalListTileSkeleton extends StatelessWidget {
  const AnimalListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const AppSkeleton(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeleton(height: 14),
                const SizedBox(height: 6),
                AppSkeleton(width: MediaQuery.sizeOf(context).width * 0.4, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const AppSkeleton(width: 60, height: 24, borderRadius: BorderRadius.all(Radius.circular(999))),
        ],
      ),
    );
  }
}

/// Skeleton para KPI cards do dashboard.
class KpiCardSkeleton extends StatelessWidget {
  const KpiCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(8))),
          SizedBox(height: 12),
          AppSkeleton(height: 28, width: 60),
          SizedBox(height: 6),
          AppSkeleton(height: 12),
        ],
      ),
    );
  }
}
