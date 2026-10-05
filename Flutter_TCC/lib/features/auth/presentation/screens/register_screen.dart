import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.producer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name  = RequiredInput.dirty(_nameController.text);
    final email = EmailInput.dirty(_emailController.text.trim());
    final pass  = PasswordInput.dirty(_passwordController.text);

    final error = switch ((name.error, email.error, pass.error)) {
      (final e?, _, _) => e.message,
      (_, final e?, _) => e.message,
      (_, _, final e?) => e.message,
      _                => null,
    };
    if (error != null) {
      AppToast.error(context, error);
      return false;
    }
    return true;
  }

  Future<void> _onRegister() async {
    if (!_validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
          name:     _nameController.text.trim(),
          email:    _emailController.text.trim(),
          password: _passwordController.text,
          role:     _role,
        );
    if (!mounted) return;
    if (ok) {
      context.goNamed(AppRoutes.dashboard);
    } else {
      final error = ref.read(authProvider).error;
      // Só mensagens amigáveis (Failure) chegam à UI — nunca o texto bruto
      // de uma exceção do Firebase.
      AppToast.error(
        context,
        error is Failure ? error.message : 'Erro ao criar conta.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Criar conta', showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Você é:', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _RoleChip(
                        label: 'Produtor Rural',
                        icon: Icons.agriculture_outlined,
                        selected: _role == UserRole.producer,
                        onTap: () => setState(() => _role = UserRole.producer),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _RoleChip(
                        label: 'Veterinário',
                        icon: Icons.medical_services_outlined,
                        selected: _role == UserRole.vet,
                        onTap: () => setState(() => _role = UserRole.vet),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: 'Nome completo',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  AppTextField(
                    label: 'E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  AppTextField(
                    label: 'Senha (mín. 8 caracteres)',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onRegister(),
                  ),
                  const SizedBox(height: AppSpacing.x2l),
                  AppButton(
                    label: 'Criar conta',
                    onPressed: _onRegister,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.goNamed(AppRoutes.login),
                      child: Text(
                        'Já tenho conta',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.brandGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
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

class _RoleChip extends StatelessWidget {
  const _RoleChip({
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
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandLight : cs.surfaceContainerHighest,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: selected ? AppColors.brandGreen : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.brandGreen : cs.outline, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? AppColors.brandGreen : cs.outline,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
