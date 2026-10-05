import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../herd/domain/entities/animal_entity.dart';
import '../../../herd/presentation/providers/animals_provider.dart';
import '../../../vets/presentation/providers/vets_provider.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../domain/entities/vaccine_info.dart';
import '../providers/vaccinations_provider.dart';
import '../widgets/quarantine_calculator.dart';

class VaccinationScreen extends ConsumerStatefulWidget {
  const VaccinationScreen({required this.animalId, super.key});

  final String animalId;

  @override
  ConsumerState<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends ConsumerState<VaccinationScreen> {
  final _lotController = TextEditingController();

  String   _vaccineName = VaccineInfo.vaccines.first;
  String   _dose        = VaccineInfo.doses.first;
  DateTime _date        = DateTime.now();
  String?  _vetName;

  @override
  void dispose() {
    _lotController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _date,
      firstDate:   DateTime(2000),
      lastDate:    DateTime.now(),
      locale:      const Locale('pt', 'BR'),
      builder:     (ctx, child) => Theme(
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

  Future<void> _submit(AnimalEntity animal) async {
    final record = VaccinationRecord(
      id:               generateId(),
      animalId:         widget.animalId,
      vaccineName:      _vaccineName,
      dose:             _dose,
      date:             _date,
      quarantineDays:   VaccineInfo.quarantineDaysFor(_vaccineName),
      lot:              _lotController.text.trim().isEmpty
          ? null
          : _lotController.text.trim(),
      veterinarianName: (_vetName == null || _vetName == 'Não informado')
          ? null
          : _vetName,
      nextDoseDate: VaccineInfo.nextDoseFor(_date, _dose),
    );

    final ok = await ref
        .read(vaccinationFormProvider.notifier)
        .register(record);

    if (!mounted) return;
    if (ok) {
      AppToast.success(context, 'Vacinação registrada com sucesso!');
      Navigator.of(context).pop();
    } else {
      AppToast.error(context, 'Erro ao registrar. Tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final animalAsync  = ref.watch(animalDetailProvider(widget.animalId));
    final isSubmitting = ref.watch(vaccinationFormProvider).isLoading;
    final vetOptions   = ref.watch(vetOptionsProvider).valueOrNull ??
        const ['Não informado'];

    return Scaffold(
      body: animalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erro: $e')),
        data:    (animal) => animal == null
            ? const Center(child: Text('Animal não encontrado.'))
            : _Form(
                animal:      animal,
                isSubmitting: isSubmitting,
                lotController: _lotController,
                vaccineName:  _vaccineName,
                dose:         _dose,
                date:         _date,
                vetName:      _vetName,
                vetOptions:   vetOptions,
                onVaccineChanged: (v) => setState(() => _vaccineName = v),
                onDoseChanged:    (v) => setState(() => _dose = v),
                onPickDate:       _pickDate,
                onVetChanged: (v) =>
                    setState(() => _vetName = v == 'Não informado' ? null : v),
                onSubmit: () => _submit(animal),
              ),
      ),
    );
  }
}

// ── Formulário ─────────────────────────────────────────────────────────────────

class _Form extends StatelessWidget {
  const _Form({
    required this.animal,
    required this.isSubmitting,
    required this.lotController,
    required this.vaccineName,
    required this.dose,
    required this.date,
    required this.vetName,
    required this.vetOptions,
    required this.onVaccineChanged,
    required this.onDoseChanged,
    required this.onPickDate,
    required this.onVetChanged,
    required this.onSubmit,
  });

  final AnimalEntity       animal;
  final bool               isSubmitting;
  final TextEditingController lotController;
  final String             vaccineName;
  final String             dose;
  final DateTime           date;
  final String?            vetName;
  final List<String>       vetOptions;
  final void Function(String) onVaccineChanged;
  final void Function(String) onDoseChanged;
  final VoidCallback       onPickDate;
  final void Function(String) onVetChanged;
  final VoidCallback       onSubmit;

  @override
  Widget build(BuildContext context) {
    final dateLabel = date.toBrDate;

    return Column(
      children: [
        AppHeader(
          title:    'Registrar vacinação',
          subtitle: animal.displayName,
          showBack: true,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AnimalCard(animal: animal),
                const SizedBox(height: AppSpacing.xl),

                _LabeledField(
                  label: 'Vacina *',
                  child: _Dropdown(
                    value:     vaccineName,
                    items:     VaccineInfo.vaccines,
                    onChanged: onVaccineChanged,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),

                TextField(
                  controller:      lotController,
                  decoration:      _decoration(context, 'Lote (ex: 22B-2025)'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.base),

                _LabeledField(
                  label: 'Dose *',
                  child: _Dropdown(
                    value:     dose,
                    items:     VaccineInfo.doses,
                    onChanged: onDoseChanged,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),

                _LabeledField(
                  label: 'Data de aplicação *',
                  child: InkWell(
                    onTap:        onPickDate,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: InputDecorator(
                      decoration: _decoration(context, null),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size:  18,
                            color: AppColors.mutedGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(dateLabel),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),

                _LabeledField(
                  label: 'Veterinário responsável',
                  child: _Dropdown(
                    value:     vetName ?? vetOptions.first,
                    items:     vetOptions,
                    onChanged: onVetChanged,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                QuarantineCalculator(
                  vaccineName:     vaccineName,
                  dose:            dose,
                  applicationDate: date,
                ),
                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  label:     'Registrar vacinação',
                  icon:      Icons.check_rounded,
                  onPressed: onSubmit,
                  isLoading: isSubmitting,
                ),
                const SizedBox(height: AppSpacing.base),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(BuildContext context, String? hint) =>
      InputDecoration(
        hintText:    hint,
        filled:      true,
        fillColor:   Theme.of(context).colorScheme.surfaceContainerHighest,
        border:      const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide:   BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical:   AppSpacing.md,
        ),
      );
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal});
  final AnimalEntity animal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        AppColors.brandPale,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width:  40,
            height: 40,
            decoration: const BoxDecoration(
              color:        AppColors.brandLight,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.brandGreen,
              size:  20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '${animal.breed} · '
                  '${animal.sex == AnimalSex.female ? 'Fêmea' : 'Macho'}'
                  '${animal.weightKg != null ? ' · ${animal.weightKg!.toStringAsFixed(0)} kg' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedGreen,
                      ),
                ),
              ],
            ),
          ),
          if (animal.rfid != null)
            const AppBadge(label: 'RFID', type: BadgeType.success),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color:      AppColors.mutedGreen,
              ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String                value;
  final List<String>          items;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: DropdownButton<String>(
        value:      value,
        isExpanded: true,
        underline:  const SizedBox.shrink(),
        onChanged:  (v) => onChanged(v!),
        items:      items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
      ),
    );
  }
}
