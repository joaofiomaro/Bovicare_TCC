import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../domain/entities/service_call.dart';
import '../providers/service_calls_provider.dart';
import '../widgets/service_call_tile.dart';
import '../widgets/vet_call_action_sheet.dart';

/// Agenda do veterinário — chamados ativos com data agendada, em ordem.
class VetAgendaScreen extends ConsumerWidget {
  const VetAgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(vetCallsProvider);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title:    'Agenda',
            subtitle: 'Visitas agendadas',
          ),
          Expanded(
            child: calls.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brandGreen),
              ),
              error: (e, _) => AppEmptyState(
                icon:        Icons.error_outline_rounded,
                title:       'Erro ao carregar',
                subtitle:    e.toString(),
                actionLabel: 'Tentar novamente',
                onAction:    () => ref.invalidate(vetCallsProvider),
              ),
              data: (list) {
                final scheduled = list
                    .where((c) => c.scheduledDate != null && c.isActive)
                    .toList()
                  ..sort((a, b) =>
                      a.scheduledDate!.compareTo(b.scheduledDate!));

                if (scheduled.isEmpty) {
                  return const AppEmptyState(
                    icon:     Icons.event_busy_outlined,
                    title:    'Agenda vazia',
                    subtitle: 'Agende uma visita ao aceitar um chamado.',
                  );
                }

                return RefreshIndicator(
                  color:     AppColors.brandGreen,
                  onRefresh: () async => ref.invalidate(vetCallsProvider),
                  child: ListView.separated(
                    padding:   const EdgeInsets.all(AppSpacing.base),
                    itemCount: scheduled.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final call = scheduled[i];
                      return ServiceCallTile(
                        call:  call,
                        onTap: () => showVetCallActionSheet(context, call),
                        trailing: _ScheduleLabel(date: call.scheduledDate!),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleLabel extends StatelessWidget {
  const _ScheduleLabel({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.event, size: 14, color: AppColors.brandGreen),
        const SizedBox(width: 4),
        Text(
          date.toBrDate,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:      AppColors.brandGreen,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
