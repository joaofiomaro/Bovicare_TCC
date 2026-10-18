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
import '../../../herd/domain/entities/animal_entity.dart';
import '../../domain/entities/health_event.dart';
import '../../domain/usecases/health_event_use_cases.dart';
import '../providers/health_events_provider.dart';

/// Abre o registro reprodutivo adequado ao estado do animal:
/// - não prenhe → confirmar prenhez;
/// - prenhe → registrar parto ou perda gestacional.
Future<void> showPregnancySheet(
  BuildContext context, {
  required AnimalEntity animal,
}) {
  if (animal.sex != AnimalSex.female) {
    AppToast.info(context, 'Registro reprodutivo disponível apenas para fêmeas.');
    return Future.value();
  }
  return showModalBottomSheet<void>(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    builder:            (_) => PregnancySheet(animal: animal),
  );
}

enum _ReproMode { diagnosis, birth, loss }

class PregnancySheet extends ConsumerStatefulWidget {
  const PregnancySheet({required this.animal, super.key});

  final AnimalEntity animal;

  @override
  ConsumerState<PregnancySheet> createState() => _PregnancySheetState();
}

class _PregnancySheetState extends ConsumerState<PregnancySheet> {
  final _notesController       = TextEditingController();
  final _calfEarTagController  = TextEditingController();
  final _calfNameController    = TextEditingController();
  final _calfWeightController  = TextEditingController();

  late _ReproMode _mode;
  DateTime  _date        = DateTime.now();
  bool      _registerCalf = true;
  AnimalSex _calfSex     = AnimalSex.female;

  bool get _isPregnant => widget.animal.status == AnimalStatus.pregnant;

  @override
  void initState() {
    super.initState();
    _mode = _isPregnant ? _ReproMode.birth : _ReproMode.diagnosis;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _calfEarTagController.dispose();
    _calfNameController.dispose();
    _calfWeightController.dispose();
    super.dispose();
  }

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  HealthEvent _event(HealthEventType type, String title, {String? calfId}) =>
      HealthEvent(
        id:       generateId(),
        animalId: widget.animal.id,
        type:     type,
        date:     _date,
        title:    title,
        notes:    _opt(_notesController),
        calfId:   calfId,
      );

  Future<void> _submit() async {
    final notifier = ref.read(healthEventActionsProvider.notifier);
    final animal   = widget.animal;
    final bool ok;
    final String successMsg;

    switch (_mode) {
      case _ReproMode.diagnosis:
        ok = await notifier.registerPregnancy(
          animal:       animal,
          coverageDate: _date,
          event: _event(
            HealthEventType.pregnancyDiagnosis,
            'Prenhez confirmada — cobertura em ${_date.toBrDate}',
          ),
        );
        successMsg = 'Prenhez registrada.';
      case _ReproMode.birth:
        AnimalEntity? calf;
        if (_registerCalf) {
          final weightText = _calfWeightController.text.trim();
          final weight = weightText.isEmpty
              ? null
              : double.tryParse(weightText.replaceAll(',', '.'));
          if (weightText.isNotEmpty && (weight == null || weight <= 0)) {
            AppToast.error(context, 'Peso do bezerro inválido.');
            return;
          }
          calf = AnimalEntity(
            id:        generateId(),
            earTag:    _calfEarTagController.text.trim(),
            name:      _opt(_calfNameController),
            breed:     animal.breed,
            sex:       _calfSex,
            birthDate: _date,
            status:    AnimalStatus.healthy,
            weightKg:  weight,
          );
        }
        ok = await notifier.registerBirth(
          mother: animal,
          calf:   calf,
          event:  _event(
            HealthEventType.birth,
            calf != null ? 'Parto — bezerro #${calf.earTag}' : 'Parto',
            calfId: calf?.id,
          ),
        );
        successMsg = calf != null
            ? 'Parto registrado e bezerro cadastrado.'
            : 'Parto registrado.';
      case _ReproMode.loss:
        ok = await notifier.registerLoss(
          mother: animal,
          event:  _event(HealthEventType.pregnancyLoss, 'Perda gestacional'),
        );
        successMsg = 'Perda gestacional registrada.';
    }

    if (!mounted) return;
    if (ok) {
      AppToast.success(context, successMsg);
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
    final expected = _mode == _ReproMode.diagnosis
        ? _date.add(const Duration(days: kGestationDays))
        : null;

    return AppSheetContainer(
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_border_rounded, color: AppColors.brandGreen),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Reprodução — ${widget.animal.displayName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        if (_isPregnant)
          SegmentedButton<_ReproMode>(
            segments: const [
              ButtonSegment(
                value: _ReproMode.birth,
                label: Text('Parto'),
                icon:  Icon(Icons.child_friendly_outlined),
              ),
              ButtonSegment(
                value: _ReproMode.loss,
                label: Text('Perda'),
                icon:  Icon(Icons.heart_broken_outlined),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          )
        else
          Text(
            'Confirme a prenhez informando a data da cobertura ou inseminação.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGreen,
                ),
          ),
        const SizedBox(height: AppSpacing.base),
        AppDateField(
          label: switch (_mode) {
            _ReproMode.diagnosis => 'Data da cobertura *',
            _ReproMode.birth     => 'Data do parto *',
            _ReproMode.loss      => 'Data da perda *',
          },
          date:      _date,
          firstDate: _mode == _ReproMode.diagnosis
              ? DateTime.now().subtract(const Duration(days: kGestationDays))
              : null,
          onChanged: (d) => setState(() => _date = d),
        ),
        if (expected != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Parto previsto: ${expected.toBrDate} ($kGestationDays dias)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:      AppColors.brandGreen,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        if (_mode == _ReproMode.birth) ...[
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value:          _registerCalf,
            onChanged:      (v) => setState(() => _registerCalf = v),
            title:          const Text('Cadastrar o bezerro no rebanho'),
            activeThumbColor: AppColors.brandGreen,
          ),
          if (_registerCalf) ...[
            AppTextField(
              label:           'Brinco do bezerro *',
              controller:      _calfEarTagController,
              prefixIcon:      Icons.label_outline_rounded,
              keyboardType:    TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.base),
            AppTextField(
              label:           'Nome do bezerro',
              controller:      _calfNameController,
              prefixIcon:      Icons.badge_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.base),
            AppTextField(
              label:        'Peso ao nascer (kg)',
              controller:   _calfWeightController,
              prefixIcon:   Icons.scale_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.base),
            SegmentedButton<AnimalSex>(
              segments: const [
                ButtonSegment(value: AnimalSex.female, label: Text('Fêmea')),
                ButtonSegment(value: AnimalSex.male,   label: Text('Macho')),
              ],
              selected: {_calfSex},
              onSelectionChanged: (s) => setState(() => _calfSex = s.first),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.base),
        AppTextField(
          label:      'Observações',
          controller: _notesController,
          prefixIcon: Icons.edit_note_rounded,
          maxLines:   2,
        ),
        const SizedBox(height: AppSpacing.x2l),
        AppButton(
          label: switch (_mode) {
            _ReproMode.diagnosis => 'Confirmar prenhez',
            _ReproMode.birth     => 'Registrar parto',
            _ReproMode.loss      => 'Registrar perda',
          },
          icon:      Icons.check_rounded,
          variant:   _mode == _ReproMode.loss
              ? AppButtonVariant.danger
              : AppButtonVariant.primary,
          onPressed: _submit,
          isLoading: isSubmitting,
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
