import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/kpi_card.dart';
import '../../domain/entities/service_call.dart';
import '../providers/service_calls_provider.dart';
import '../widgets/service_call_tile.dart';
import '../widgets/vet_call_action_sheet.dart';

/// Dashboard inicial do veterinário — KPIs do pool e dos próprios atendimentos.
class VetDashboardScreen extends ConsumerWidget {
  const VetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(authProvider).valueOrNull;
    final open    = ref.watch(openCallsProvider).valueOrNull ?? const [];
    final myCalls = ref.watch(vetCallsProvider).valueOrNull ?? const [];

    final active     = myCalls.where((c) => c.isActive).toList();
    final completed  = myCalls.where((c) => c.status == ServiceStatus.completed);
    final now        = DateTime.now();
    final monthDone  = completed
        .where((c) =>
            c.completedAt != null &&
            c.completedAt!.year == now.year &&
            c.completedAt!.month == now.month)
        .length;
    final nextSched = _nextScheduled(myCalls);

    return Scaffold(
      body: RefreshIndicator(
        color:     AppColors.brandGreen,
        onRefresh: () async {
          ref
            ..invalidate(openCallsProvider)
            ..invalidate(vetCallsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VetHeader(name: user?.name ?? 'Veterinário'),
              const SizedBox(height: AppSpacing.base),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                child: GridView.count(
                  shrinkWrap:       true,
                  physics:          const NeverScrollableScrollPhysics(),
                  crossAxisCount:   2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing:  12,
                  childAspectRatio: 1.25,
                  children: [
                    KpiCard(
                      label:    'Chamados abertos',
                      value:    open.length,
                      sub:      'no pool',
                      isAccent: true,
                    ),
                    KpiCard(
                      label: 'Meus ativos',
                      value: active.length,
                      sub:   'em atendimento',
                      delay: const Duration(milliseconds: 80),
                    ),
                    KpiCard(
                      label: 'Concluídos',
                      value: monthDone,
                      sub:   'neste mês',
                      delay: const Duration(milliseconds: 160),
                    ),
                    KpiCard(
                      label:      'Agendamentos',
                      value:      myCalls.where((c) => c.scheduledDate != null && c.isActive).length,
                      sub:        nextSched != null ? 'próximo em breve' : 'nenhum',
                      delay:      const Duration(milliseconds: 240),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('Chamados abertos no pool'),
              const SizedBox(height: AppSpacing.sm),
              if (open.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                  child: Text(
                    'Nenhum chamado aberto no momento.',
                    style: TextStyle(color: AppColors.mutedGreen),
                  ),
                )
              else
                ...open.take(4).map(
                      (call) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm,
                        ),
                        child: ServiceCallTile(
                          call:  call,
                          onTap: () => showVetCallActionSheet(context, call),
                        ),
                      ),
                    ),
              const SizedBox(height: AppSpacing.x2l),
            ],
          ),
        ),
      ),
    );
  }

  ServiceCall? _nextScheduled(List<ServiceCall> calls) {
    final upcoming = calls
        .where((c) => c.scheduledDate != null && c.isActive)
        .toList()
      ..sort((a, b) => a.scheduledDate!.compareTo(b.scheduledDate!));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}

class _VetHeader extends StatelessWidget {
  const _VetHeader({required this.name});
  final String name;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Área do veterinário',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                'Dr(a). $name',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
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
}

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
