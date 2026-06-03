import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../dashboard/domain/entities/activity_item.dart';
import '../../../dashboard/presentation/widgets/activity_timeline.dart';
import '../../../vaccination/domain/entities/vaccination_record.dart';
import '../../../vaccination/presentation/providers/vaccinations_provider.dart';
import '../../domain/entities/animal_entity.dart';
import '../providers/animals_provider.dart';

class AnimalProfileScreen extends ConsumerWidget {
  const AnimalProfileScreen({required this.animalId, super.key});

  final String animalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(animalDetailProvider(animalId));

    return detail.when(
      loading: () => const Scaffold(body: _ProfileSkeleton()),
      error: (e, _) => Scaffold(
        body: AppEmptyState(
          icon:        Icons.error_outline_rounded,
          title:       'Animal não encontrado',
          subtitle:    e.toString(),
          actionLabel: 'Voltar',
          onAction:    () => Navigator.of(context).maybePop(),
        ),
      ),
      data: (animal) {
        if (animal == null) {
          return Scaffold(
            body: AppEmptyState(
              icon:        Icons.pets_rounded,
              title:       'Animal não encontrado',
              subtitle:    'Este registro pode ter sido removido.',
              actionLabel: 'Voltar',
              onAction:    () => Navigator.of(context).maybePop(),
            ),
          );
        }
        return _AnimalProfileContent(animal: animal);
      },
    );
  }
}

// ── Scaffold com tabs ─────────────────────────────────────────────────────────

class _AnimalProfileContent extends StatelessWidget {
  const _AnimalProfileContent({required this.animal});
  final AnimalEntity animal;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Column(
          children: [
            _AnimalHeader(animal: animal),
            _AnimalTabBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _ResumoTab(animal: animal),
                  _SanitarioTab(animalId: animal.id),
                  _ReproducaoTab(animal: animal),
                  _HistoricoTab(animal: animal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header verde ──────────────────────────────────────────────────────────────

class _AnimalHeader extends StatelessWidget {
  const _AnimalHeader({required this.animal});
  final AnimalEntity animal;

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
            top:    MediaQuery.of(context).padding.top + 8,
            left:   AppSpacing.base,
            right:  AppSpacing.base,
            bottom: AppSpacing.x2l,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed:  () => Navigator.of(context).maybePop(),
                    icon:       const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  AppBadge(
                    label: _statusLabel(animal.status),
                    type:  _statusBadge(animal.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Icon(Icons.pets_rounded, color: Colors.white, size: 36),
              const SizedBox(height: 8),
              Text(
                animal.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _infoLine(animal),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
              if (animal.rfid != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        Colors.white.withValues(alpha: 0.15),
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rss_feed_rounded, color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'RFID ${animal.rfid}',
                        style: const TextStyle(
                          color:      Colors.white70,
                          fontSize:   11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
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

  String _infoLine(AnimalEntity a) {
    final breed = a.breed;
    final sex   = a.sex == AnimalSex.female ? 'Fêmea' : 'Macho';
    final birth = '${a.birthDate.day.toString().padLeft(2, '0')}/'
        '${a.birthDate.month.toString().padLeft(2, '0')}/'
        '${a.birthDate.year}';
    final weight = a.weightKg != null
        ? ' · ${a.weightKg!.toStringAsFixed(0)} kg'
        : '';
    return '$breed · $sex · Nasc. $birth$weight';
  }

  String _statusLabel(AnimalStatus s) => switch (s) {
    AnimalStatus.healthy   => 'Ativo',
    AnimalStatus.pregnant  => 'Prenha',
    AnimalStatus.attention => 'Alerta',
    AnimalStatus.sick      => 'Medicação',
  };

  BadgeType _statusBadge(AnimalStatus s) => switch (s) {
    AnimalStatus.healthy   => BadgeType.info,
    AnimalStatus.pregnant  => BadgeType.success,
    AnimalStatus.attention => BadgeType.warning,
    AnimalStatus.sick      => BadgeType.danger,
  };
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _AnimalTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const TabBar(
      tabs: [
        Tab(text: 'Resumo'),
        Tab(text: 'Sanitário'),
        Tab(text: 'Reprodução'),
        Tab(text: 'Histórico'),
      ],
      labelColor:         AppColors.brandGreen,
      unselectedLabelColor: AppColors.mutedGreen,
      indicatorColor:     AppColors.brandGreen,
      indicatorWeight:    2.5,
      labelStyle:           TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
    );
  }
}

// ── Tab: Resumo ───────────────────────────────────────────────────────────────

class _ResumoTab extends ConsumerWidget {
  const _ResumoTab({required this.animal});
  final AnimalEntity animal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentEvents = ref.watch(vaccinationsProvider(animal.id)).maybeWhen(
          data: (records) => records
              .take(3)
              .map(
                (r) => ActivityItem(
                  type:     ActivityType.vaccination,
                  title:    '${r.vaccineName} — ${r.dose}',
                  subtitle: r.lot != null ? 'Lote ${r.lot}' : null,
                  date:     r.date,
                ),
              )
              .toList(),
          orElse: () => <ActivityItem>[],
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (animal.status == AnimalStatus.pregnant) ...[
            const SizedBox(height: AppSpacing.base),
            _PregnancyCard(animal: animal),
          ],
          const SizedBox(height: AppSpacing.base),
          const _SectionLabel('Registrar manejo'),
          const SizedBox(height: AppSpacing.sm),
          _ActionGrid(animal: animal),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Histórico recente'),
          const SizedBox(height: AppSpacing.sm),
          if (recentEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.base),
              child: AppEmptyState(
                icon:     Icons.history_rounded,
                title:    'Sem registros',
                subtitle: 'As ações registradas aparecerão aqui.',
              ),
            )
          else
            ActivityTimeline(activities: recentEvents),
        ],
      ),
    );
  }
}

class _PregnancyCard extends StatelessWidget {
  const _PregnancyCard({required this.animal});
  final AnimalEntity animal;

  @override
  Widget build(BuildContext context) {
    final days     = animal.pregnancyDays;
    final progress = animal.pregnancyProgress;
    final expected = animal.expectedBirthDate;
    final expectedStr = expected != null
        ? '${expected.day.toString().padLeft(2, '0')}/'
          '${expected.month.toString().padLeft(2, '0')}/'
          '${expected.year}'
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color:        AppColors.brandPale,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border:       Border.all(color: AppColors.brandGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(
                color:        AppColors.brandLight,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: AppColors.brandGreen, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prenha · $days dias',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandGreen,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Parto previsto: $expectedStr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedGreen,
                        ),
                  ),
                  const SizedBox(height: 8),
                  AppProgressBar(
                    value:      progress,
                    color:      AppColors.brandGreen,
                    showPercent: true,
                    height:     6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.animal});
  final AnimalEntity animal;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(icon: Icons.vaccines_outlined,        label: 'Vacinação',    onTap: () => context.goNamed(AppRoutes.vaccination, pathParameters: {'id': animal.id})),
      _ActionItem(icon: Icons.medication_liquid_outlined, label: 'Vermifugação', onTap: () => AppToast.info(context, 'Em breve')),
      _ActionItem(icon: Icons.medication_outlined,        label: 'Medicação',    onTap: () => AppToast.info(context, 'Em breve')),
      _ActionItem(icon: Icons.edit_note_rounded,         label: 'Observação',   onTap: () => AppToast.info(context, 'Em breve')),
      _ActionItem(icon: Icons.monitor_weight_outlined,   label: 'Pesar',        onTap: () => AppToast.info(context, 'Em breve')),
      _ActionItem(icon: Icons.favorite_border_rounded,   label: 'Prenhez',      onTap: () => AppToast.info(context, 'Em breve')),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: GridView.count(
        shrinkWrap:  true,
        physics:     const NeverScrollableScrollPhysics(),
        crossAxisCount:   3,
        crossAxisSpacing: 8,
        mainAxisSpacing:  8,
        childAspectRatio: 1.15,
        children:    actions,
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border:       Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.brandGreen, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w500,
                color:      AppColors.mutedGreen,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab: Sanitário ────────────────────────────────────────────────────────────

class _SanitarioTab extends ConsumerWidget {
  const _SanitarioTab({required this.animalId});
  final String animalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaccinations = ref.watch(vaccinationsProvider(animalId));

    return vaccinations.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => AppEmptyState(
        icon:     Icons.error_outline_rounded,
        title:    'Erro ao carregar',
        subtitle: e.toString(),
      ),
      data: (records) {
        if (records.isEmpty) {
          return const AppEmptyState(
            icon:     Icons.vaccines_outlined,
            title:    'Sem vacinações registradas',
            subtitle: 'Registre a primeira vacinação pelo Resumo do animal.',
          );
        }
        return ListView.separated(
          padding:     const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical:   AppSpacing.base,
          ),
          itemCount:   records.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder:  (_, i) => _VaccinationTile(record: records[i]),
        );
      },
    );
  }
}

class _VaccinationTile extends StatelessWidget {
  const _VaccinationTile({required this.record});
  final VaccinationRecord record;

  @override
  Widget build(BuildContext context) {
    final quarantineEnd = record.quarantineDays > 0
        ? record.date.add(Duration(days: record.quarantineDays))
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  36,
            height: 36,
            decoration: const BoxDecoration(
              color:        AppColors.brandLight,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: const Icon(
              Icons.vaccines_outlined,
              color: AppColors.brandGreen,
              size:  18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.vaccineName} — ${record.dose}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.date.toBrDate +
                      (record.lot != null ? ' · Lote ${record.lot}' : '') +
                      (record.veterinarianName != null
                          ? ' · ${record.veterinarianName}'
                          : ''),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedGreen,
                      ),
                ),
                if (quarantineEnd != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.block_rounded,
                        size:  12,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Carência até ${quarantineEnd.toBrDate}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:      AppColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
                if (record.nextDoseDate != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size:  12,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Próxima dose: ${record.nextDoseDate!.toBrDate}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.info,
                            ),
                      ),
                    ],
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

// ── Tab: Reprodução ───────────────────────────────────────────────────────────

class _ReproducaoTab extends StatelessWidget {
  const _ReproducaoTab({required this.animal});
  final AnimalEntity animal;

  @override
  Widget build(BuildContext context) {
    if (animal.status != AnimalStatus.pregnant || animal.pregnancyDate == null) {
      return const AppEmptyState(
        icon:     Icons.child_friendly_outlined,
        title:    'Sem dados reprodutivos',
        subtitle: 'Registre uma prenhez no Resumo do animal.',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          _PregnancyCard(animal: animal),
        ],
      ),
    );
  }
}

// ── Tab: Histórico ────────────────────────────────────────────────────────────

class _HistoricoTab extends ConsumerWidget {
  const _HistoricoTab({required this.animal});
  final AnimalEntity animal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaccinations = ref.watch(vaccinationsProvider(animal.id));

    return vaccinations.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (_, __) => const SizedBox.shrink(),
      data: (records) {
        // Converte VaccinationRecord → ActivityItem para reutilizar a timeline.
        final vaccinationEvents = records.map(
          (r) => ActivityItem(
            type:     ActivityType.vaccination,
            title:    '${r.vaccineName} — ${r.dose}',
            subtitle: r.lot != null ? 'Lote ${r.lot}' : null,
            date:     r.date,
          ),
        );

        // Eventos estáticos do animal (prenhez, etc.) mesclados com vacinações.
        final staticEvents = <ActivityItem>[
          if (animal.status == AnimalStatus.pregnant &&
              animal.pregnancyDate != null)
            ActivityItem(
              type:  ActivityType.birth,
              title: 'Prenhez constatada',
              date:  animal.pregnancyDate!,
            ),
        ];

        final all = [...vaccinationEvents, ...staticEvents]
          ..sort((a, b) => b.date.compareTo(a.date));

        if (all.isEmpty) {
          return const AppEmptyState(
            icon:     Icons.history_rounded,
            title:    'Histórico vazio',
            subtitle: 'As ações realizadas neste animal aparecerão aqui.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          child: ActivityTimeline(activities: all),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
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

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 220,
          color:  AppColors.brandGreen,
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              AppSkeleton(height: 14, width: 160),
              SizedBox(height: 8),
              AppSkeleton(height: 12, width: 200),
              SizedBox(height: 16),
              AppSkeleton(height: 80),
              SizedBox(height: 16),
              AppSkeleton(height: 120),
            ],
          ),
        ),
      ],
    );
  }
}
