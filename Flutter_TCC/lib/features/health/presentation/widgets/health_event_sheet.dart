import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_date_field.dart';
import '../../../../shared/widgets/app_sheet_container.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../vets/presentation/providers/vets_provider.dart';
import '../../domain/entities/health_event.dart';
import '../providers/health_events_provider.dart';

/// Abre o formulário de vermifugação, medicação ou observação.
Future<void> showHealthEventSheet(
  BuildContext context, {
  required String animalId,
  required HealthEventType type,
}) {
  assert(!type.isReproductive, 'Use showPregnancySheet para reprodução');
  return showModalBottomSheet<void>(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    builder: (_) => HealthEventSheet(animalId: animalId, type: type),
  );
}

class HealthEventSheet extends ConsumerStatefulWidget {
  const HealthEventSheet({
    required this.animalId,
    required this.type,
    super.key,
  });

  final String animalId;
  final HealthEventType type;

  @override
  ConsumerState<HealthEventSheet> createState() => _HealthEventSheetState();
}

class _HealthEventSheetState extends ConsumerState<HealthEventSheet> {
  final _titleController      = TextEditingController();
  final _doseController       = TextEditingController();
  final _withdrawalController = TextEditingController();
  final _notesController      = TextEditingController();
  DateTime _date = DateTime.now();
  String?  _vetName;

  bool get _isTreatment => widget.type.isTreatment;

  @override
  void dispose() {
    _titleController.dispose();
    _doseController.dispose();
    _withdrawalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _withdrawalDays =>
      int.tryParse(_withdrawalController.text.trim()) ?? 0;

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    final withdrawalText = _withdrawalController.text.trim();
    if (withdrawalText.isNotEmpty && int.tryParse(withdrawalText) == null) {
      AppToast.error(context, 'Carência deve ser um número inteiro de dias.');
      return;
    }

    final event = HealthEvent(
      id:               generateId(),
      animalId:         widget.animalId,
      type:             widget.type,
      date:             _date,
      title:            _titleController.text.trim(),
      dose:             _isTreatment ? _opt(_doseController) : null,
      withdrawalDays:   _isTreatment ? _withdrawalDays : 0,
      notes:            _opt(_notesController),
      veterinarianName: _vetName,
    );

    final notifier = ref.read(healthEventActionsProvider.notifier);
    final ok = await notifier.register(event);
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, '${widget.type.label} registrada.');
      Navigator.of(context).pop();
    } else {
      AppToast.error(
        context,
        notifier.lastErrorMessage ?? 'Erro ao registrar. Tente novamente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(healthEventActionsProvider).isLoading;
    final vetOptions   = ref.watch(vetOptionsProvider).valueOrNull ??
        const ['Não informado'];
    final withdrawalEnd = _withdrawalDays > 0
        ? _date.add(Duration(days: _withdrawalDays))
        : null;

    return AppSheetContainer(
      children: [
        Row(
          children: [
            Icon(_icon(widget.type), color: AppColors.brandGreen),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Registrar ${widget.type.label.toLowerCase()}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: _isTreatment ? 'Produto *' : 'Assunto *',
          hint:  switch (widget.type) {
            HealthEventType.deworming  => 'Ex.: Ivermectina 1%',
            HealthEventType.medication => 'Ex.: Oxitetraciclina',
            _                          => 'Ex.: Mancando da pata traseira',
          },
          controller:      _titleController,
          prefixIcon:      _isTreatment
              ? Icons.medication_outlined
              : Icons.short_text_rounded,
          textInputAction: TextInputAction.next,
        ),
        if (_isTreatment) ...[
          const SizedBox(height: AppSpacing.base),
          AppTextField(
            label:           'Dose / posologia',
            hint:            'Ex.: 1 mL a cada 50 kg',
            controller:      _doseController,
            prefixIcon:      Icons.science_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.base),
          AppTextField(
            label:           'Carência (dias, conforme a bula)',
            controller:      _withdrawalController,
            prefixIcon:      Icons.block_rounded,
            keyboardType:    TextInputType.number,
            textInputAction: TextInputAction.next,
            onChanged:       (_) => setState(() {}),
          ),
          if (withdrawalEnd != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Carência até ${withdrawalEnd.toBrDate}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:      AppColors.amber,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.base),
        AppDateField(
          label:     'Data *',
          date:      _date,
          onChanged: (d) => setState(() => _date = d),
        ),
        if (_isTreatment) ...[
          const SizedBox(height: AppSpacing.base),
          DropdownButtonFormField<String>(
            initialValue: _vetName ?? vetOptions.first,
            isExpanded:   true,
            decoration:   const InputDecoration(
              labelText: 'Veterinário responsável',
              border:    OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            items: [
              for (final v in vetOptions)
                DropdownMenuItem(value: v, child: Text(v)),
            ],
            onChanged: (v) => setState(
              () => _vetName = v == null || v == 'Não informado' ? null : v,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.base),
        AppTextField(
          label:           _isTreatment ? 'Observações' : 'Descrição',
          controller:      _notesController,
          prefixIcon:      Icons.edit_note_rounded,
          maxLines:        3,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.x2l),
        AppButton(
          label:     'Salvar',
          icon:      Icons.check_rounded,
          onPressed: _submit,
          isLoading: isSubmitting,
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  static IconData _icon(HealthEventType type) => switch (type) {
        HealthEventType.deworming  => Icons.medication_liquid_outlined,
        HealthEventType.medication => Icons.medication_outlined,
        _                          => Icons.edit_note_rounded,
      };
}
