import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../domain/entities/service_call.dart';
import '../providers/service_calls_provider.dart';
import '../widgets/service_call_tile.dart';
import '../widgets/vet_call_action_sheet.dart';

/// Tela de chamados do veterinário — abas Pool / Meus ativos / Histórico.
class VetCallsScreen extends ConsumerWidget {
  const VetCallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open    = ref.watch(openCallsProvider);
    final myCalls = ref.watch(vetCallsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            const AppHeader(
              title:    'Chamados',
              subtitle: 'Atendimentos veterinários',
            ),
            const TabBar(
              labelColor:       AppColors.brandGreen,
              indicatorColor:   AppColors.brandGreen,
              unselectedLabelColor: AppColors.mutedGreen,
              tabs: [
                Tab(text: 'Abertos'),
                Tab(text: 'Meus ativos'),
                Tab(text: 'Histórico'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Pool de chamados abertos.
                  _CallsList(
                    state:        open,
                    provider:     openCallsProvider,
                    emptyTitle:   'Pool vazio',
                    emptySub:     'Nenhum chamado aberto no momento.',
                    ref:          ref,
                  ),
                  // Meus chamados ativos (aceitos / em atendimento).
                  _CallsList(
                    state:        myCalls,
                    provider:     vetCallsProvider,
                    emptyTitle:   'Sem atendimentos ativos',
                    emptySub:     'Aceite um chamado do pool para começar.',
                    ref:          ref,
                    filter:       (c) => c.isActive,
                  ),
                  // Histórico (concluídos / cancelados).
                  _CallsList(
                    state:        myCalls,
                    provider:     vetCallsProvider,
                    emptyTitle:   'Sem histórico',
                    emptySub:     'Seus atendimentos concluídos aparecem aqui.',
                    ref:          ref,
                    filter:       (c) => c.isClosed,
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

class _CallsList extends StatelessWidget {
  const _CallsList({
    required this.state,
    required this.provider,
    required this.emptyTitle,
    required this.emptySub,
    required this.ref,
    this.filter,
  });

  final AsyncValue<List<ServiceCall>> state;
  final StreamProvider<List<ServiceCall>> provider;
  final String emptyTitle;
  final String emptySub;
  final WidgetRef ref;
  final bool Function(ServiceCall)? filter;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandGreen),
      ),
      error: (e, _) => AppEmptyState(
        icon:        Icons.error_outline_rounded,
        title:       'Erro ao carregar',
        subtitle:    e.toString(),
        actionLabel: 'Tentar novamente',
        onAction:    () => ref.invalidate(provider),
      ),
      data: (calls) {
        final list = filter == null ? calls : calls.where(filter!).toList();
        if (list.isEmpty) {
          return AppEmptyState(
            icon:     Icons.assignment_outlined,
            title:    emptyTitle,
            subtitle: emptySub,
          );
        }
        return RefreshIndicator(
          color:     AppColors.brandGreen,
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.separated(
            padding:   const EdgeInsets.all(AppSpacing.base),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => ServiceCallTile(
              call:  list[i],
              onTap: () => showVetCallActionSheet(context, list[i]),
            ),
          ),
        );
      },
    );
  }
}
