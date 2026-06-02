import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/animal_entity.dart';
import '../providers/animals_provider.dart';

class NewAnimalScreen extends ConsumerStatefulWidget {
  const NewAnimalScreen({super.key});

  @override
  ConsumerState<NewAnimalScreen> createState() => _NewAnimalScreenState();
}

class _NewAnimalScreenState extends ConsumerState<NewAnimalScreen> {
  final _earTagController  = TextEditingController();
  final _nameController    = TextEditingController();
  final _weightController  = TextEditingController();

  AnimalSex    _sex         = AnimalSex.female;
  String       _breed       = 'Nelore';
  DateTime?    _birthDate;
  String?      _rfid;
  bool         _isScanning  = false;
  bool         _isSaving    = false;

  static const _breeds = ['Nelore', 'Gir', 'Angus', 'Girolando', 'Simental', 'Brahman', 'Outra'];

  @override
  void dispose() {
    _earTagController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Simula leitura de RFID do brete — em produção integraria com MqttService.
  Future<void> _simulateRfid() async {
    setState(() => _isScanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final tag = '9001150${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    setState(() {
      _rfid       = tag;
      _isScanning = false;
    });
    AppToast.success(context, 'RFID lido: $tag');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
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
    if (picked != null) setState(() => _birthDate = picked);
  }

  bool _validate() {
    if (_earTagController.text.trim().isEmpty) {
      AppToast.error(context, 'Brinco/ID é obrigatório.');
      return false;
    }
    if (_birthDate == null) {
      AppToast.error(context, 'Informe a data de nascimento.');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);

    final animal = AnimalEntity(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      earTag:    _earTagController.text.trim(),
      name:      _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      breed:     _breed,
      sex:       _sex,
      birthDate: _birthDate!,
      status:    AnimalStatus.healthy,
      weightKg:  double.tryParse(_weightController.text),
      rfid:      _rfid,
    );

    await ref.read(animalsProvider.notifier).save(animal);

    if (mounted) {
      setState(() => _isSaving = false);
      AppToast.success(context, 'Animal cadastrado com sucesso!');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthLabel = _birthDate != null
        ? '${_birthDate!.day.toString().padLeft(2, '0')}/'
          '${_birthDate!.month.toString().padLeft(2, '0')}/'
          '${_birthDate!.year}'
        : 'Selecionar data';

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title:    'Novo animal',
            subtitle: 'Preencha os dados',
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // RFID scanner
                  _RfidScanner(
                    rfid:      _rfid,
                    scanning:  _isScanning,
                    onScan:    _simulateRfid,
                  ),
                  const SizedBox(height: AppSpacing.base),

                  AppTextField(
                    label:          'Brinco / ID *',
                    controller:     _earTagController,
                    prefixIcon:     Icons.label_outline_rounded,
                    textInputAction: TextInputAction.next,
                    keyboardType:   TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.base),

                  AppTextField(
                    label:      'Nome',
                    controller: _nameController,
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // Raça — DropdownButton direto (sem FormField) pois o estado é gerenciado localmente.
                  _LabeledField(
                    label: 'Raça *',
                    child: Container(
                      padding:    const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color:        Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                      ),
                      child: DropdownButton<String>(
                        value:       _breed,
                        isExpanded:  true,
                        underline:   const SizedBox.shrink(),
                        onChanged:   (v) => setState(() => _breed = v!),
                        items:       _breeds
                            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // Sexo
                  _LabeledField(
                    label: 'Sexo *',
                    child: Row(
                      children: [
                        _SexChip(
                          label:    'Fêmea',
                          selected: _sex == AnimalSex.female,
                          onTap:    () => setState(() => _sex = AnimalSex.female),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _SexChip(
                          label:    'Macho',
                          selected: _sex == AnimalSex.male,
                          onTap:    () => setState(() => _sex = AnimalSex.male),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // Data de nascimento
                  _LabeledField(
                    label: 'Data de nascimento *',
                    child: InkWell(
                      onTap:        _pickDate,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: InputDecorator(
                        decoration: _inputDecoration(context),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: AppColors.mutedGreen),
                            const SizedBox(width: 8),
                            Text(
                              birthLabel,
                              style: TextStyle(
                                color: _birthDate != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : AppColors.mutedGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  AppTextField(
                    label:          'Peso atual (kg)',
                    controller:     _weightController,
                    prefixIcon:     Icons.monitor_weight_outlined,
                    keyboardType:   const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.x2l),

                  AppButton(
                    label:     'Cadastrar animal',
                    icon:      Icons.check_rounded,
                    onPressed: _save,
                    isLoading: _isSaving,
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    return InputDecoration(
      filled:      true,
      fillColor:   Theme.of(context).colorScheme.surfaceContainerHighest,
      border:      const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide:   BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _RfidScanner extends StatelessWidget {
  const _RfidScanner({
    required this.rfid,
    required this.scanning,
    required this.onScan,
  });
  final String? rfid;
  final bool scanning;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        scanning ? null : onScan,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:  const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:        rfid != null ? AppColors.brandPale : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border:       Border.all(
            color: rfid != null ? AppColors.brandGreen.withValues(alpha: 0.4) : AppColors.ghostGreen,
            width: rfid != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(
                color:        AppColors.brandLight,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: scanning
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color:      AppColors.brandGreen,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.rss_feed_rounded,
                        color: AppColors.brandGreen, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanning ? 'Lendo tag RFID…' : 'Ler tag RFID',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    rfid != null
                        ? rfid!
                        : 'Aproxime a tag ao leitor do brete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedGreen,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.qr_code_scanner_rounded,
                color: AppColors.brandGreen, size: 20),
          ],
        ),
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
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedGreen,
                )),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SexChip extends StatelessWidget {
  const _SexChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
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
            color:        selected ? AppColors.brandLight : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: selected ? AppColors.brandGreen : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:      selected ? AppColors.brandGreen : AppColors.mutedGreen,
            ),
          ),
        ),
      ),
    );
  }
}
