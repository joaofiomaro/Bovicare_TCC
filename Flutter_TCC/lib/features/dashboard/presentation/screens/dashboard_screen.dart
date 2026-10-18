import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../alerts/presentation/providers/farm_alerts_provider.dart';
import '../../../alerts/presentation/widgets/farm_alert_tile.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../health/presentation/providers/health_events_provider.dart';
import '../../../herd/presentation/providers/animals_provider.dart';
import '../../../vaccination/presentation/providers/vaccinations_provider.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/activity_timeline.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/kpi_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(authProvider).valueOrNull;
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      body: dashboard.when(
        loading: () => const DashboardSkeleton(),
        error: (e, _) => AppEmptyState(
          icon:        Icons.error_outline_rounded,
          title:       'Erro ao carregar',
          subtitle:    e.toString(),
          actionLabel: 'Tentar novamente',
          onAction:    () => ref.invalidate(dashboardProvider),
        ),
        data: (state) => RefreshIndicator(
          color:    AppColors.brandGreen,
          onRefresh: () async {
            ref
              ..invalidate(allVaccinationsProvider)
              ..invalidate(allHealthEventsProvider)
              ..invalidate(animalsProvider);
            await ref.read(dashboardProvider.notifier).refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(user: user),
                if (state.stats.alertCount > 0)
                  _AlertBanner(stats: state.stats),
                const SizedBox(height: AppSpacing.base),
                _KpiGrid(stats: state.stats),
                const _AlertsSection(),
                const SizedBox(height: AppSpacing.xl),
                const _SectionLabel(title: 'Módulos'),
                const SizedBox(height: AppSpacing.sm),
                const _ModulesList(),
                const SizedBox(height: AppSpacing.xl),
                const _SectionLabel(title: 'Atividade recente'),
                const SizedBox(height: AppSpacing.sm),
                ActivityTimeline(activities: state.activities),
                const SizedBox(height: AppSpacing.x2l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.user});
  final UserEntity? user;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Bom dia';
    if (h >= 12 && h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBackground
        : Colors.white;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.brandGreen,
          padding: EdgeInsets.only(
            top:    MediaQuery.of(context).padding.top + AppSpacing.base,
            left:   AppSpacing.base,
            right:  AppSpacing.base,
            bottom: AppSpacing.x2l,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.name ?? 'Produtor',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (user?.farmName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white60,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            user!.farmName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white60,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              AppAvatar(
                name:     user?.name ?? 'U',
                radius:   22,
              ),
            ],
          ),
        ),
        // Arco decorativo na base — mesmo padrão do AppHeader
        Positioned(
          bottom: 0,
          left:   0,
          right:  0,
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color:        bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Alert Banner ──────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.sm, AppSpacing.base, 0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        AppColors.amberLight,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border:       Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.alertMessage ?? '${stats.alertCount} alertas pendentes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                      ),
                ),
                if (stats.alertDetail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    stats.alertDetail!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.amber,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alertas do rebanho ───────────────────────────────────────────────────────

/// Até 3 alertas mais importantes + atalho para a central de alertas.
/// Some quando não há alertas (ou enquanto carrega).
class _AlertsSection extends ConsumerWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(farmAlertsProvider).valueOrNull ?? const [];
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alertas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed(AppRoutes.alerts),
                child: Text(
                  'Ver todos (${alerts.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:      AppColors.brandGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final alert in alerts.take(3)) FarmAlertTile(alert: alert),
      ],
    );
  }
}

// ── KPI Grid──────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: GridView.count(
        shrinkWrap:  true,
        physics:     const NeverScrollableScrollPhysics(),
        crossAxisCount:   2,
        crossAxisSpacing: 12,
        mainAxisSpacing:  12,
        childAspectRatio: 1.25,
        children: [
          KpiCard(
            label:    'Efetivo total',
            value:    stats.totalAnimals,
            sub:      'animais ativos',
            isAccent: true,
          ),
          KpiCard(
            label: 'Prenhas',
            value: stats.pregnantCount,
            // Sem animais ativos a divisão daria NaN e `.round()` lançaria.
            sub:   stats.totalAnimals == 0
                ? 'sem animais ativos'
                : '${(stats.pregnantCount / stats.totalAnimals * 100).round()}% do rebanho',
            delay: const Duration(milliseconds: 80),
          ),
          KpiCard(
            label:      'Alertas',
            value:      stats.alertCount,
            sub:        'pendentes',
            valueColor: AppColors.danger,
            delay:      const Duration(milliseconds: 160),
          ),
          KpiCard(
            label: 'Vacinações',
            value: stats.upcomingVaccinations,
            sub:   'próximos 30 dias',
            delay: const Duration(milliseconds: 240),
          ),
        ],
      ),
    );
  }
}

// ── Módulos ───────────────────────────────────────────────────────────────────

class _ModulesList extends StatelessWidget {
  const _ModulesList();

  @override
  Widget build(BuildContext context) {
    final items = [
      _ModuleItem(
        icon:     Icons.pets_rounded,
        color:    AppColors.brandGreen,
        bg:       AppColors.brandLight,
        title:    'Rebanho',
        subtitle: 'Gestão de animais',
        onTap:    () => context.goNamed(AppRoutes.herd),
      ),
      _ModuleItem(
        icon:     Icons.settings_remote_rounded,
        color:    AppColors.info,
        bg:       AppColors.infoLight,
        title:    'Brete',
        subtitle: 'Controle IoT',
        onTap:    () => context.goNamed(AppRoutes.brete),
      ),
      _ModuleItem(
        icon:     Icons.medical_services_outlined,
        color:    AppColors.amber,
        bg:       AppColors.amberLight,
        title:    'Veterinários',
        subtitle: 'Profissionais disponíveis',
        onTap:    () => context.goNamed(AppRoutes.vets),
      ),
      _ModuleItem(
        icon:     Icons.assignment_outlined,
        color:    AppColors.info,
        bg:       AppColors.infoLight,
        title:    'Meus chamados',
        subtitle: 'Solicitar e acompanhar atendimentos',
        onTap:    () => context.pushNamed(AppRoutes.myServiceCalls),
      ),
      _ModuleItem(
        icon:     Icons.bar_chart_rounded,
        color:    AppColors.mutedGreen,
        bg:       AppColors.brandPale,
        title:    'Relatórios',
        subtitle: 'Sanitário · Reprodutivo',
        onTap:    () => context.goNamed(AppRoutes.reports),
      ),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical:   AppSpacing.xs,
              ),
              child: item,
            ),
          )
          .toList(),
    );
  }
}

class _ModuleItem extends StatelessWidget {
  const _ModuleItem({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color:        isDark ? AppColors.darkSurface : AppColors.white,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: InkWell(
        onTap:       onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical:   AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width:        40,
                height:       40,
                decoration:   BoxDecoration(color: bg, borderRadius: const BorderRadius.all(Radius.circular(10))),
                child:        Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedGreen,
                            )),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.ghostGreen,
                size:  20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
