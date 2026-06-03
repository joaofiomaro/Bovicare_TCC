import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/animal_entity.dart';
import '../../domain/entities/sale_record.dart';
import '../providers/sales_provider.dart';

enum _ExitMode { sale, death }

/// Abre o sheet de baixa de rebanho para [animals] (1 = individual, N = lote).
/// Retorna `true` se uma baixa foi registrada.
Future<bool?> showAnimalExitSheet(
  BuildContext context, {
  required List<AnimalEntity> animals,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AnimalExitSheet(animals: animals),
  );
}

class AnimalExitSheet extends ConsumerStatefulWidget {
  const AnimalExitSheet({required this.animals, super.key});

  final List<AnimalEntity> animals;

  @override
  ConsumerState<AnimalExitSheet> createState() => _AnimalExitSheetState();
}

class _AnimalExitSheetState extends ConsumerState<AnimalExitSheet> {
  final _buyerController  = TextEditingController();
  final _valueController  = TextEditingController();
  final _weightController = TextEditingController();
  final _causeController  = TextEditingController();
  final _notesController  = TextEditingController();

  _ExitMode _mode = _ExitMode.sale;
  DateTime  _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Sugere o peso total do lote quando todos os animais têm peso.
    final weights = widget.animals.map((a) => a.weightKg).toList();
    if (weights.every((w) => w != null)) {
      final total = weights.fold<double>(0, (sum, w) => sum + w!);
      if (total > 0) _weightController.text = total.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _buyerController.dispose();
    _valueController.dispose();
    _weightController.dispose();
    _causeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _ids => widget.animals.map((a) => a.id).toList();

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

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
    final notifier = ref.read(animalExitProvider.notifier);
    final bool ok;

    if (_mode == _ExitMode.sale) {
      final value = _parse(_valueController.text);
      if (value == null || value < 0) {
        AppToast.error(context, 'Informe o valor total da venda.');
        return;
      }
      final sale = SaleRecord(
        id:        DateTime.now().millisecondsSinceEpoch.toString(),
        date:      _date,
        type:      _ids.length > 1 ? SaleType.lote : SaleType.individual,
        animalIds: _ids,
        headCount: _ids.length,
        totalValue: value,
        buyer: _buyerController.text.trim().isEmpty
            ? null
            : _buyerController.text.trim(),
        totalWeightKg: _parse(_weightController.text),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      ok = await notifier.recordSale(sale);
    } else {
      ok = await notifier.recordDeath(
        animalIds: _ids,
        date:      _date,
        cause: _causeController.text.trim().isEmpty
            ? null
            : _causeController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    }

    if (!mounted) return;
    if (ok) {
      AppToast.success(
        context,
        _ids.length > 1
            ? 'Baixa registrada para ${_ids.length} animais.'
            : 'Baixa registrada.',
      );
      Navigator.of(context).pop(true);
    } else {
      AppToast.error(context, 'Erro ao registrar baixa. Tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final isSubmitting = ref.watch(animalExitProvider).isLoading;
    final count        = widget.animals.length;

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
      child: SingleChildScrollView(
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
            Text(
              count > 1 ? 'Dar baixa — $count animais' : 'Dar baixa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'O animal sai do rebanho ativo, mas o histórico é preservado.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedGreen,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Toggle Venda / Óbito
            Row(
              children: [
                _ModeChip(
                  label:    'Venda',
                  icon:     Icons.sell_outlined,
                  selected: _mode == _ExitMode.sale,
                  onTap:    () => setState(() => _mode = _ExitMode.sale),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ModeChip(
                  label:    'Óbito',
                  icon:     Icons.heart_broken_outlined,
                  selected: _mode == _ExitMode.death,
                  onTap:    () => setState(() => _mode = _ExitMode.death),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),

            if (_mode == _ExitMode.sale) ..._saleFields() else ..._deathFields(),

            const SizedBox(height: AppSpacing.base),
            _DateField(date: _date, onTap: _pickDate),
            const SizedBox(height: AppSpacing.x2l),

            AppButton(
              label:     count > 1 ? 'Confirmar baixa de $count animais' : 'Confirmar baixa',
              icon:      Icons.check_rounded,
              onPressed: _submit,
              isLoading: isSubmitting,
              variant:   AppButtonVariant.danger,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  List<Widget> _saleFields() {
    final value     = _parse(_valueController.text) ?? 0;
    final count     = widget.animals.length;
    final perHead   = count == 0 ? 0.0 : value / count;

    return [
      AppTextField(
        label:           'Comprador',
        controller:      _buyerController,
        prefixIcon:      Icons.person_outline_rounded,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: AppSpacing.base),
      AppTextField(
        label:           r'Valor total (R$) *',
        controller:      _valueController,
        prefixIcon:      Icons.attach_money_rounded,
        keyboardType:    const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        onChanged:       (_) => setState(() {}),
      ),
      const SizedBox(height: AppSpacing.base),
      AppTextField(
        label:           'Peso total do lote (kg)',
        controller:      _weightController,
        prefixIcon:      Icons.scale_outlined,
        keyboardType:    const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
      ),
      if (count > 1 && value > 0) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Média por cabeça: R\$ ${perHead.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:      AppColors.brandGreen,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
      const SizedBox(height: AppSpacing.base),
      AppTextField(
        label:           'Observação',
        controller:      _notesController,
        prefixIcon:      Icons.edit_note_rounded,
        textInputAction: TextInputAction.done,
      ),
    ];
  }

  List<Widget> _deathFields() {
    return [
      AppTextField(
        label:           'Causa',
        controller:      _causeController,
        prefixIcon:      Icons.report_outlined,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: AppSpacing.base),
      AppTextField(
        label:           'Observação',
        controller:      _notesController,
        prefixIcon:      Icons.edit_note_rounded,
        textInputAction: TextInputAction.done,
      ),
    ];
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:  const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandLight
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: selected
                  ? AppColors.brandGreen
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? AppColors.brandGreen
                      : AppColors.mutedGreen),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.brandGreen
                      : AppColors.mutedGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data da baixa *',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color:      AppColors.mutedGreen,
              ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap:        onTap,
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
                Text(date.toBrDate),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
