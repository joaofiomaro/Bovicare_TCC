import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_chip_filter.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/user_settings.dart';
import '../providers/settings_provider.dart';

/// Antecedência e categorias dos alertas do rebanho.
class AlertSettingsScreen extends ConsumerWidget {
  const AlertSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alertSettingsProvider);

    Future<void> save(AlertSettings updated) async {
      final ok = await ref.read(alertSettingsProvider.notifier).save(updated);
      if (!ok && context.mounted) {
        AppToast.error(context, 'Não foi possível salvar. Tente novamente.');
      }
    }

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title:    'Configurar alertas',
            subtitle: 'Antecedência e categorias',
            showBack: true,
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brandGreen),
              ),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (settings) => ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                children: [
                  const _Label('Avisar com antecedência de'),
                  const SizedBox(height: AppSpacing.sm),
                  AppChipFilter<int>(
                    options: [
                      for (final d in AlertSettings.leadOptions)
                        ChipOption(label: '$d dias', value: d),
                    ],
                    selected:   {settings.leadDays},
                    onSelected: (d, {required isSelected}) =>
                        save(settings.copyWith(leadDays: d)),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _Label('Categorias'),
                  SwitchListTile(
                    value:     settings.vaccines,
                    onChanged: (v) => save(settings.copyWith(vaccines: v)),
                    title:     const Text('Vacinas'),
                    subtitle:  const Text('Próximas doses e doses atrasadas'),
                    secondary: const Icon(Icons.vaccines_outlined),
                    activeThumbColor: AppColors.brandGreen,
                  ),
                  SwitchListTile(
                    value:     settings.births,
                    onChanged: (v) => save(settings.copyWith(births: v)),
                    title:     const Text('Partos previstos'),
                    subtitle:  const Text('Fêmeas próximas do fim da gestação'),
                    secondary: const Icon(Icons.child_friendly_outlined),
                    activeThumbColor: AppColors.brandGreen,
                  ),
                  SwitchListTile(
                    value:     settings.withdrawal,
                    onChanged: (v) => save(settings.copyWith(withdrawal: v)),
                    title:     const Text('Carência'),
                    subtitle:  const Text(
                      'Animais que não podem ser abatidos ou ter o leite vendido',
                    ),
                    secondary: const Icon(Icons.block_rounded),
                    activeThumbColor: AppColors.brandGreen,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.base),
                    child: Text(
                      'Os alertas aparecem no início e na central de alertas. '
                      'As preferências ficam salvas na sua conta.',
                      style: TextStyle(color: AppColors.mutedGreen, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}
