import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';

/// Primeiro acesso de uma conta sem perfil (ex.: login com Google): o usuário
/// escolhe se é produtor ou veterinário. O papel não pode ser alterado depois.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  late final TextEditingController _name;
  UserRole _role = UserRole.producer;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      AppToast.error(context, 'Informe seu nome.');
      return;
    }
    setState(() => _saving = true);
    final error = await ref
        .read(authProvider.notifier)
        .completeProfile(name: _name.text, role: _role);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    context.goNamed(AppRoutes.dashboard);
  }

  Future<void> _cancel() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.goNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title:    'Complete seu cadastro',
            subtitle: 'Só falta escolher seu perfil',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                Text(
                  'Conectado como $email',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedGreen,
                      ),
                ),
                const SizedBox(height: AppSpacing.base),
                AppTextField(
                  label:      'Nome completo',
                  controller: _name,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Você é:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                      value: UserRole.producer,
                      label: Text('Produtor rural'),
                      icon:  Icon(Icons.agriculture_outlined),
                    ),
                    ButtonSegment(
                      value: UserRole.vet,
                      label: Text('Veterinário'),
                      icon:  Icon(Icons.medical_services_outlined),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Atenção: o perfil não pode ser alterado depois.',
                  style: TextStyle(color: AppColors.amber, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.x2l),
                AppButton(
                  label:     'Concluir cadastro',
                  icon:      Icons.check_rounded,
                  isLoading: _saving,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label:     'Sair',
                  variant:   AppButtonVariant.ghost,
                  onPressed: _saving ? null : _cancel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
