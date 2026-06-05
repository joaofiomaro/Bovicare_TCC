import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/service_call.dart';
import '../providers/service_calls_provider.dart';
import '../widgets/service_call_tile.dart';

/// Lista de chamados do produtor — acompanhamento de status e cancelamento.
class ProducerCallsScreen extends ConsumerWidget {
  const ProducerCallsScreen({super.key});

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    ServiceCall call,
  ) async {
    final confirm = await AppBottomSheet.show(
      context,
      title:          'Cancelar chamado',
      message:        'Deseja cancelar "${call.title}"? Esta ação não pode ser desfeita.',
      confirmLabel:   'Cancelar chamado',
      cancelLabel:    'Voltar',
      icon:           Icons.cancel_outlined,
      iconColor:      AppColors.danger,
    );
    if (confirm != true || !context.mounted) return;

    final ok = await ref.read(serviceCallActionsProvider.notifier).cancel(call);
    if (!context.mounted) return;
    if (ok) {
      AppToast.success(context, 'Chamado cancelado.');
    } else {
      AppToast.error(context, 'Não foi possível cancelar.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(producerCallsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.newServiceCall),
        backgroundColor: AppColors.brandGreen,
        icon:  const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Novo chamado',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          const AppHeader(
            title:    'Meus chamados',
            subtitle: 'Atendimentos solicitados',
            showBack: true,
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
                onAction:    () => ref.invalidate(producerCallsProvider),
              ),
              data: (list) => list.isEmpty
                  ? const AppEmptyState(
                      icon:     Icons.assignment_outlined,
                      title:    'Nenhum chamado',
                      subtitle: 'Solicite atendimento de um veterinário.',
                    )
                  : RefreshIndicator(
                      color:     AppColors.brandGreen,
                      onRefresh: () async =>
                          ref.invalidate(producerCallsProvider),
                      child: ListView.separated(
                        padding:  const EdgeInsets.all(AppSpacing.base),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final call = list[i];
                          return ServiceCallTile(
                            call: call,
                            trailing: _ProducerCallFooter(
                              call:     call,
                              onCancel: () => _cancel(context, ref, call),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProducerCallFooter extends StatelessWidget {
  const _ProducerCallFooter({required this.call, required this.onCancel});

  final ServiceCall call;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (call.vetName != null)
          Text(
            'Veterinário: ${call.vetName}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.brandGreen,
                  fontWeight: FontWeight.w600,
                ),
          ),
        if (call.scheduledDate != null)
          Text(
            'Agendado: ${call.scheduledDate!.toBrDateTime}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGreen,
                ),
          ),
        if (call.resolution != null) ...[
          const SizedBox(height: 4),
          Text(
            'Laudo: ${call.resolution}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGreen,
                ),
          ),
        ],
        if (call.canCancel) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label:     'Cancelar',
            icon:      Icons.close_rounded,
            variant:   AppButtonVariant.outline,
            fullWidth: false,
            onPressed: onCancel,
          ),
        ],
      ],
    );
  }
}
