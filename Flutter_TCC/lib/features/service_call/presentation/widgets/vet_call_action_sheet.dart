import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/service_call.dart';
import '../extensions/service_call_visuals.dart';
import '../providers/service_calls_provider.dart';

/// Abre o sheet de ações do veterinário sobre um chamado.
Future<void> showVetCallActionSheet(
  BuildContext context,
  ServiceCall call,
) =>
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder:            (_) => _VetCallActionSheet(call: call),
    );

class _VetCallActionSheet extends ConsumerStatefulWidget {
  const _VetCallActionSheet({required this.call});
  final ServiceCall call;

  @override
  ConsumerState<_VetCallActionSheet> createState() =>
      _VetCallActionSheetState();
}

class _VetCallActionSheetState extends ConsumerState<_VetCallActionSheet> {
  final _resolution = TextEditingController();
  DateTime? _scheduledDate;
  String? _error;

  ServiceCall get call => widget.call;

  @override
  void dispose() {
    _resolution.dispose();
    super.dispose();
  }

  Future<void> _run(Future<bool> Function() action, String successMsg) async {
    final ok = await action();
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, successMsg);
      Navigator.of(context).pop();
    } else {
      AppToast.error(context, 'Não foi possível concluir a ação.');
    }
  }

  Future<void> _accept() => _run(
        () => ref.read(serviceCallActionsProvider.notifier).accept(call),
        'Chamado aceito.',
      );

  Future<void> _start() => _run(
        () => ref.read(serviceCallActionsProvider.notifier).advance(
              call,
              to: ServiceStatus.inProgress,
              scheduledDate: _scheduledDate,
            ),
        'Atendimento iniciado.',
      );

  Future<void> _schedule() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
      locale:      const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _complete() async {
    if (_resolution.text.trim().isEmpty) {
      setState(() => _error = 'Informe o laudo para concluir.');
      return;
    }
    await _run(
      () => ref.read(serviceCallActionsProvider.notifier).advance(
            call,
            to: ServiceStatus.completed,
            resolution: _resolution.text.trim(),
          ),
      'Atendimento concluído.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSubmitting = ref.watch(serviceCallActionsProvider).isLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.base, AppSpacing.base,
        AppSpacing.base + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize:       MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        cs.outlineVariant,
                borderRadius: AppRadius.fullAll,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              Expanded(
                child: Text(
                  call.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              AppBadge(label: call.status.label, type: call.status.badge),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            call.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedGreen,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${call.producerName} · ${call.city}/${call.state}'
            '${call.animalEarTag != null ? ' · Brinco #${call.animalEarTag}' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGreen,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          ..._actions(isSubmitting),

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.error,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  List<Widget> _actions(bool isSubmitting) => switch (call.status) {
        ServiceStatus.open => [
            AppButton(
              label:     'Aceitar chamado',
              icon:      Icons.check_rounded,
              isLoading: isSubmitting,
              onPressed: _accept,
            ),
          ],
        ServiceStatus.accepted => [
            if (_scheduledDate != null) ...[
              Text(
                'Agendado para ${_scheduledDate!.toBrDate}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.brandGreen,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton(
              label:     'Agendar visita',
              icon:      Icons.event_outlined,
              variant:   AppButtonVariant.outline,
              onPressed: _schedule,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label:     'Iniciar atendimento',
              icon:      Icons.play_arrow_rounded,
              isLoading: isSubmitting,
              onPressed: _start,
            ),
          ],
        ServiceStatus.inProgress => [
            AppTextField(
              label:      'Laudo / observação final',
              controller: _resolution,
              maxLines:   3,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label:     'Concluir atendimento',
              icon:      Icons.done_all_rounded,
              isLoading: isSubmitting,
              onPressed: _complete,
            ),
          ],
        ServiceStatus.completed || ServiceStatus.cancelled => [
            if (call.resolution != null)
              Text(
                'Laudo: ${call.resolution}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
      };
}
