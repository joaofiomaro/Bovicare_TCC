import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/file_share_service.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/user_data_export_service.dart';
import '../widgets/sync_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user   = ref.watch(authProvider).valueOrNull;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Meu perfil'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHero(user: user),

                  const _SectionLabel('Conta'),
                  _SettingsRow(
                    icon:     Icons.person_outline_rounded,
                    title:    'Editar dados',
                    subtitle: 'Nome, e-mail, propriedade',
                    onTap:    () => _showEditProfile(context, ref, user),
                  ),
                  if (user?.role == UserRole.vet)
                    _SettingsRow(
                      icon:     Icons.medical_services_outlined,
                      title:    'Perfil profissional',
                      subtitle: 'CRMV, especialidades e área de atendimento',
                      onTap:    () =>
                          context.pushNamed(AppRoutes.vetProfessionalProfile),
                    )
                  else
                    _SettingsRow(
                      icon:     Icons.notifications_outlined,
                      title:    'Configurar alertas',
                      subtitle: 'Antecedência e categorias',
                      onTap:    () => context.pushNamed(AppRoutes.alertSettings),
                    ),
                  _ThemeToggleRow(isDark: isDark, ref: ref),

                  const _SectionLabel('Privacidade — LGPD'),
                  _SettingsRow(
                    icon:      Icons.description_outlined,
                    iconBg:    AppColors.infoLight,
                    iconColor: AppColors.info,
                    title:     'Meus consentimentos',
                    subtitle:  'Visualizar e revogar por finalidade',
                    onTap:     () => context.pushNamed(AppRoutes.consents),
                  ),
                  _SettingsRow(
                    icon:      Icons.download_outlined,
                    iconBg:    AppColors.infoLight,
                    iconColor: AppColors.info,
                    title:     'Exportar meus dados',
                    subtitle:  'Portabilidade — arquivo JSON',
                    onTap:     () => _exportData(context),
                  ),
                  _SettingsRow(
                    icon:      Icons.delete_outline_rounded,
                    iconBg:    AppColors.dangerLight,
                    iconColor: AppColors.danger,
                    title:     'Excluir conta',
                    subtitle:  'Remove a conta e todos os seus dados',
                    onTap:     () => _deleteAccount(context, ref),
                  ),

                  const _SectionLabel('Sincronização'),
                  const SyncCard(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base, AppSpacing.sm,
                      AppSpacing.base, AppSpacing.x2l,
                    ),
                    child: AppButton(
                      label:    'Sair da conta',
                      icon:     Icons.logout_rounded,
                      variant:  AppButtonVariant.danger,
                      onPressed: () => _logout(context, ref),
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

  void _showEditProfile(
    BuildContext context,
    WidgetRef ref,
    UserEntity? user,
  ) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _EditProfileSheet(user: user, ref: ref),
    );
  }

  /// Gera o JSON com todos os dados do usuário e abre o compartilhamento.
  Future<void> _exportData(BuildContext context) async {
    AppToast.info(context, 'Preparando seus dados…');
    try {
      final bytes = await UserDataExportService().exportJsonBytes();
      final today = DateTime.now();
      final stamp = '${today.year}'
          '${today.month.toString().padLeft(2, '0')}'
          '${today.day.toString().padLeft(2, '0')}';
      await FileShareService.shareBytes(
        bytes:    bytes,
        fileName: 'bovicare_meus_dados_$stamp.json',
        mimeType: 'application/json',
        subject:  'BoviCare — meus dados',
      );
    } on Exception catch (_) {
      if (context.mounted) {
        AppToast.error(
          context,
          'Não foi possível exportar. Verifique a conexão e tente novamente.',
        );
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppBottomSheet.show(
      context,
      title:          'Sair da conta?',
      message:        'Você precisará fazer login novamente para acessar o BoviCare.',
      confirmLabel:   'Sair',
      confirmVariant: AppButtonVariant.danger,
      icon:           Icons.logout_rounded,
      iconColor:      AppColors.danger,
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.goNamed(AppRoutes.login);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppBottomSheet.show(
      context,
      title:          'Excluir conta?',
      message:        'Seus dados serão removidos permanentemente. Esta ação não pode ser desfeita.',
      confirmLabel:   'Excluir',
      confirmVariant: AppButtonVariant.danger,
      icon:           Icons.delete_forever_rounded,
      iconColor:      AppColors.danger,
    );
    if (confirmed != true || !context.mounted) return;
    final error = await ref.read(authProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    if (error != null) {
      // Ex.: Firebase exige login recente — o usuário sai, entra e repete.
      AppToast.error(context, error);
      return;
    }
    AppToast.success(context, 'Conta e dados excluídos.');
    context.goNamed(AppRoutes.login);
  }
}

// ── Widgets privados ───────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});
  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final roleLabel = user?.role == UserRole.vet ? 'Veterinário' : 'Produtor';
    final sub = [
      if (user?.farmName != null) user!.farmName!,
      roleLabel,
    ].join(' · ');

    // Largura total: a coluna da tela alinha à esquerda (start), então sem
    // isso o bloco encolhe para o conteúdo e fica encostado no canto.
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical:   AppSpacing.xl,
      ),
      child: Column(
        children: [
          AppAvatar(name: user?.name ?? 'U', radius: 40),
          const SizedBox(height: AppSpacing.md),
          Text(
            user?.name ?? 'Usuário',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedGreen,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.base, AppSpacing.base, AppSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight:    FontWeight.w700,
              color:         AppColors.mutedGreen,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconBg,
    this.iconColor,
  });

  final IconData     icon;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;
  final Color?       iconBg;
  final Color?       iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical:   AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg ??
                    (isDark ? AppColors.darkSurface2 : AppColors.brandPale),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? AppColors.mutedGreen),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedGreen,
                          )),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ghostGreen,
              size:  20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleRow extends StatelessWidget {
  const _ThemeToggleRow({required this.isDark, required this.ref});
  final bool      isDark;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDarkCtx = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical:   AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width:  40,
            height: 40,
            decoration: BoxDecoration(
              color: isDarkCtx ? AppColors.darkSurface2 : AppColors.brandPale,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: const Icon(
              Icons.dark_mode_outlined,
              size:  20,
              color: AppColors.mutedGreen,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modo escuro',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                Text('Ajusta cores para ambiente noturno',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedGreen,
                        )),
              ],
            ),
          ),
          Switch(
            value:              isDark,
            onChanged:          (_) => ref.read(themeProvider.notifier).toggle(),
            activeThumbColor:   AppColors.brandGreen,
            activeTrackColor:   AppColors.brandLight,
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet de edição de perfil ──────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.ref});
  final UserEntity? user;
  final WidgetRef   ref;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _farmController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _farmController = TextEditingController(text: widget.user?.farmName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.error(context, 'O nome não pode ser vazio.');
      return;
    }
    setState(() => _saving = true);
    final updated = widget.user!.copyWith(
      name:     name,
      farmName: _farmController.text.trim().isEmpty
          ? null
          : _farmController.text.trim(),
    );
    final ok = await widget.ref.read(authProvider.notifier).updateProfile(updated);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      AppToast.success(context, 'Perfil atualizado!');
    } else {
      setState(() => _saving = false);
      AppToast.error(context, 'Não foi possível salvar. Tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width:  40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: const BorderRadius.all(Radius.circular(999)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Editar dados',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label:           'Nome completo',
            controller:      _nameController,
            prefixIcon:      Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.base),
          // E-mail é read-only pois é o identificador de login.
          AppTextField(
            label:      'E-mail',
            controller: TextEditingController(text: widget.user?.email ?? ''),
            prefixIcon: Icons.email_outlined,
            enabled:    false,
          ),
          const SizedBox(height: AppSpacing.base),
          AppTextField(
            label:           'Nome da fazenda (opcional)',
            controller:      _farmController,
            prefixIcon:      Icons.landscape_outlined,
            textInputAction: TextInputAction.done,
            onSubmitted:     (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label:     'Salvar alterações',
            onPressed: _save,
            isLoading: _saving,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
