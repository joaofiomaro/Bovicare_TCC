import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vets/presentation/providers/vets_provider.dart';
import '../../domain/entities/user_settings.dart';
import '../providers/settings_provider.dart';

/// LGPD — finalidades de tratamento, base legal e consentimentos revogáveis.
class ConsentsScreen extends ConsumerWidget {
  const ConsentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consents = ref.watch(consentSettingsProvider);
    final isVet = ref.watch(authProvider).valueOrNull?.role == UserRole.vet;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title:    'Meus consentimentos',
            subtitle: 'Lei Geral de Proteção de Dados',
            showBack: true,
          ),
          Expanded(
            child: consents.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brandGreen),
              ),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (settings) => ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                children: [
                  const _Section('Revogáveis a qualquer momento'),
                  for (final purpose in ConsentPurpose.values)
                    SwitchListTile(
                      value:    settings.isGranted(purpose),
                      activeThumbColor: AppColors.brandGreen,
                      title:    Text(purpose.title),
                      subtitle: Text(
                        purpose.description +
                            _decidedAt(settings.decisions[purpose]),
                      ),
                      onChanged: (granted) async {
                        final ok = await ref
                            .read(consentSettingsProvider.notifier)
                            .setDecision(purpose, granted: granted);
                        if (!context.mounted) return;
                        if (!ok) {
                          AppToast.error(context, 'Não foi possível salvar.');
                          return;
                        }
                        if (purpose == ConsentPurpose.location) {
                          ref.invalidate(userLocationProvider);
                        }
                      },
                    ),
                  if (isVet)
                    const ListTile(
                      leading:  Icon(Icons.public_rounded),
                      title:    Text('Perfil público de veterinário'),
                      subtitle: Text(
                        'Controlado em Perfil › Perfil profissional: publicar '
                        'torna nome, CRMV, contatos e área de atendimento '
                        'visíveis aos produtores. Despublicar remove os dados.',
                      ),
                    ),
                  const SizedBox(height: AppSpacing.base),
                  const _Section('Necessários ao serviço (LGPD, art. 7º, V)'),
                  const _InfoTile(
                    icon:  Icons.person_outline_rounded,
                    title: 'Conta',
                    text:  'Nome, e-mail e papel — para autenticar e personalizar o app.',
                  ),
                  if (!isVet)
                    const _InfoTile(
                      icon:  Icons.pets_rounded,
                      title: 'Rebanho e manejo',
                      text:  'Animais, vacinas, tratamentos, pesagens e vendas — '
                          'visíveis apenas para você.',
                    ),
                  const _InfoTile(
                    icon:  Icons.assignment_outlined,
                    title: 'Chamados',
                    text:  'Nome, fazenda, cidade e descrição do chamado são '
                        'compartilhados com veterinários enquanto o chamado está '
                        'aberto, e depois só com o veterinário que aceitou.',
                  ),
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.base),
                    child: Text(
                      'Você pode exportar seus dados ou excluir a conta a '
                      'qualquer momento pelo Perfil.',
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

  static String _decidedAt(ConsentDecision? decision) {
    final at = decision?.at;
    if (at == null) return '';
    return '\n${decision!.granted ? 'Concedido' : 'Revogado'} em ${at.toBrDateTime}.';
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xs,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color:      AppColors.mutedGreen,
              ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => ListTile(
        leading:  Icon(icon),
        title:    Text(title),
        subtitle: Text(text),
      );
}
