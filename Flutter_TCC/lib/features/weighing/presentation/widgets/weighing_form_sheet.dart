import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../herd/presentation/providers/animals_provider.dart';
import '../../domain/entities/weighing.dart';
import '../providers/weighings_provider.dart';

/// Abre o bottom sheet de registro de pesagem para [animalId].
Future<void> showWeighingSheet(
  BuildContext context, {
  required String animalId,
  double? currentWeight,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WeighingFormSheet(
      animalId: animalId,
      currentWeight: currentWeight,
    ),
  );
}

class WeighingFormSheet extends ConsumerStatefulWidget {
  const WeighingFormSheet({
    required this.animalId,
    this.currentWeight,
    super.key,
  });

  final String animalId;
  final double? currentWeight;

  @override
  ConsumerState<WeighingFormSheet> createState() => _WeighingFormSheetState();
}

class _WeighingFormSheetState extends ConsumerState<WeighingFormSheet> {
  final _weightController = TextEditingController();
  final _notesController  = TextEditingController();
  DateTime _date = DateTime.now();

  /// Limite superior de sanidade — pesos acima disso são quase certamente erro.
  static const _maxPlausibleKg = 1500.0;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _date,
      firstDate:   DateTime(2000),
      lastDate:    DateTime.now(),
      locale:      const Locale('pt', 'BR'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.brandGreen,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final weight = double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
    if (weight == null || weight <= 0 || weight > _maxPlausibleKg) {
      AppToast.error(context, 'Informe um peso válido (0–$_maxPlausibleKg kg).');
      return;
    }

    final weighing = Weighing(
      id:       generateId(),
      animalId: widget.animalId,
      weightKg: weight,
      date:     _date,
      notes:    _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final ok = await ref.read(weighingFormProvider.notifier).register(weighing);
    if (!mounted) return;

    if (ok) {
      // O peso atual do animal mudou: recarrega ficha e lista.
      ref
        ..invalidate(animalDetailProvider(widget.animalId))
        ..invalidate(animalsProvider);
      AppToast.success(context, 'Pesagem registrada!');
      Navigator.of(context).pop();
    } else {
      AppToast.error(context, 'Erro ao registrar. Tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final isSubmitting = ref.watch(weighingFormProvider).isLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:        cs.outlineVariant,
                borderRadius: const BorderRadius.all(Radius.circular(999)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined,
                  color: AppColors.brandGreen),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Registrar pesagem',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          if (widget.currentWeight != null) ...[
            const SizedBox(height: 4),
            Text(
              'Peso atual: ${widget.currentWeight!.toStringAsFixed(0)} kg',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedGreen,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),

          AppTextField(
            label:           'Peso (kg) *',
            controller:      _weightController,
            prefixIcon:      Icons.scale_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.base),

          Text(
            'Data da pesagem *',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:      AppColors.mutedGreen,
                ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap:        _pickDate,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: InputDecorator(
              decoration: InputDecoration(
                filled:    true,
                fillColor: cs.surfaceContainerHighest,
                border:    const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide:   BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical:   AppSpacing.md,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.mutedGreen),
                  const SizedBox(width: 8),
                  Text(_date.toBrDate),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          AppTextField(
            label:           'Observação',
            controller:      _notesController,
            prefixIcon:      Icons.edit_note_rounded,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.x2l),

          AppButton(
            label:     'Salvar pesagem',
            icon:      Icons.check_rounded,
            onPressed: _submit,
            isLoading: isSubmitting,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
