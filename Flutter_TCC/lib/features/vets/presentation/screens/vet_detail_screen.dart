import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../domain/entities/vet_entity.dart';
import '../providers/vets_provider.dart';
import '../widgets/contact_buttons.dart';

class VetDetailScreen extends ConsumerWidget {
  const VetDetailScreen({required this.vetId, super.key});
  final String vetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(vetDetailProvider(vetId));

    return detail.when(
      loading: () => const Scaffold(body: _DetailSkeleton()),
      error:   (e, _) => Scaffold(
        body: AppEmptyState(
          icon:        Icons.error_outline_rounded,
          title:       'Veterinário não encontrado',
          subtitle:    e.toString(),
          actionLabel: 'Voltar',
          onAction:    () => Navigator.of(context).maybePop(),
        ),
      ),
      data: (vet) => vet == null
          ? Scaffold(
              body: AppEmptyState(
                icon:        Icons.medical_services_outlined,
                title:       'Veterinário não encontrado',
                subtitle:    'Este perfil pode ter sido removido.',
                actionLabel: 'Voltar',
                onAction:    () => Navigator.of(context).maybePop(),
              ),
            )
          : _VetDetailContent(vet: vet),
    );
  }
}

class _VetDetailContent extends StatelessWidget {
  const _VetDetailContent({required this.vet});
  final VetEntity vet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
            pinned:          true,
            expandedHeight:  200,
            flexibleSpace:   FlexibleSpaceBar(
              background: _VetHeader(vet: vet),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.base),
            sliver:  SliverList(
              delegate: SliverChildListDelegate([
                _SpecialtiesCard(specialties: vet.specialties),
                const SizedBox(height: AppSpacing.md),
                _LocationCard(vet: vet),
                const SizedBox(height: AppSpacing.xl),
                ContactButtons(vet: vet),
                const SizedBox(height: AppSpacing.x2l),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _VetHeader extends StatelessWidget {
  const _VetHeader({required this.vet});
  final VetEntity vet;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brandGreen,
      alignment: Alignment.center,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 44,
        bottom: AppSpacing.base,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  72,
            height: 72,
            decoration: BoxDecoration(
              color:  AppColors.brandLight,
              shape:  BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2.5,
              ),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: AppColors.brandGreen,
              size:  32,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            vet.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            'Médico Veterinário · ${vet.crmv}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          AppBadge(
            label: vet.isAvailable ? 'Disponível agora' : 'Ocupado',
            type:  vet.isAvailable ? BadgeType.success : BadgeType.warning,
          ),
        ],
      ),
    );
  }
}

// ── Cards de informação ───────────────────────────────────────────────────────

class _SpecialtiesCard extends StatelessWidget {
  const _SpecialtiesCard({required this.specialties});
  final List<String> specialties;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border:       Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESPECIALIDADES',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight:    FontWeight.w700,
                  color:         AppColors.mutedGreen,
                  letterSpacing: 0.8,
                  fontSize:      10,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing:  6,
            runSpacing: 6,
            children: specialties
                .map((s) => AppBadge(label: s, type: BadgeType.success))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.vet});
  final VetEntity vet;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dist   = vet.distanceKm;

    return Container(
      padding:    const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border:       Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
        ),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon:  Icons.location_on_outlined,
            label: '${vet.city}, ${vet.state}'
                '${dist != null ? ' · ${dist.toStringAsFixed(0)} km de você' : ''}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon:  Icons.radar_rounded,
            label: 'Atende em raio de ${vet.coverageRadiusKm} km',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedGreen),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 200, color: AppColors.brandGreen),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              AppSkeleton(height: 100),
              SizedBox(height: 12),
              AppSkeleton(height: 80),
              SizedBox(height: 24),
              AppSkeleton(height: 48),
              SizedBox(height: 12),
              AppSkeleton(height: 48),
            ],
          ),
        ),
      ],
    );
  }
}
