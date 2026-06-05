import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_chip_filter.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/service_call.dart';
import '../providers/service_calls_provider.dart';

/// Formulário do produtor para abrir um chamado de atendimento veterinário.
class OpenServiceCallScreen extends ConsumerStatefulWidget {
  const OpenServiceCallScreen({super.key});

  @override
  ConsumerState<OpenServiceCallScreen> createState() =>
      _OpenServiceCallScreenState();
}

class _OpenServiceCallScreenState
    extends ConsumerState<OpenServiceCallScreen> {
  final _title       = TextEditingController();
  final _description = TextEditingController();
  final _city        = TextEditingController();
  final _state       = TextEditingController();
  final _earTag      = TextEditingController();

  ServiceUrgency _urgency = ServiceUrgency.normal;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _city.dispose();
    _state.dispose();
    _earTag.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    if (_title.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        _city.text.trim().isEmpty) {
      setState(() => _error = 'Preencha título, descrição e cidade.');
      return;
    }
    setState(() => _error = null);

    final call = ServiceCall(
      id:           DateTime.now().millisecondsSinceEpoch.toString(),
      producerId:   user.id,
      producerName: user.name,
      farmName:     user.farmName,
      city:         _city.text.trim(),
      state:        _state.text.trim().toUpperCase(),
      title:        _title.text.trim(),
      description:  _description.text.trim(),
      animalEarTag: _earTag.text.trim().isEmpty ? null : _earTag.text.trim(),
      urgency:      _urgency,
      status:       ServiceStatus.open,
      createdAt:    DateTime.now(),
    );

    final ok = await ref.read(serviceCallActionsProvider.notifier).open(call);
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, 'Chamado aberto. Aguardando um veterinário.');
      Navigator.of(context).pop();
    } else {
      AppToast.error(context, 'Não foi possível abrir o chamado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(serviceCallActionsProvider).isLoading;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title:    'Solicitar atendimento',
            subtitle: 'Abrir chamado para veterinários',
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label:      'Motivo',
                    hint:       'Ex.: Vaca com dificuldade no parto',
                    controller: _title,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label:      'Descrição',
                    hint:       'Detalhe os sintomas e o que precisa',
                    controller: _description,
                    maxLines:   4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          label:      'Cidade',
                          controller: _city,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppTextField(
                          label:      'UF',
                          controller: _state,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label:      'Brinco do animal (opcional)',
                    controller: _earTag,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    'Urgência',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppChipFilter<ServiceUrgency>(
                    options: ServiceUrgency.values
                        .map((u) => ChipOption(label: u.label, value: u))
                        .toList(),
                    selected: {_urgency},
                    onSelected: (u, {required isSelected}) =>
                        setState(() => _urgency = u),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label:     'Abrir chamado',
                    icon:      Icons.send_rounded,
                    isLoading: isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.x2l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
