import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final emailVal = EmailInput.dirty(_emailController.text);
    final passVal  = PasswordInput.dirty(_passwordController.text);
    setState(() {
      _emailError    = emailVal.isValid    ? null : 'Informe um e-mail válido.';
      _passwordError = passVal.isValid ? null : 'Senha deve ter ao menos 8 caracteres.';
    });
    return emailVal.isValid && passVal.isValid;
  }

  Future<void> _onLogin() async {
    if (!_validate()) return;
    final ok = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    if (ok) {
      context.goNamed(AppRoutes.dashboard);
    } else {
      final error = ref.read(authProvider).error;
      AppToast.error(context, error?.toString() ?? 'Erro ao fazer login.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.brandGreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3l),
              child: Column(
                children: [
                  Image.asset('assets/images/bovicare_logo.png', width: 80, height: 80),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'BoviCare',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Entrar', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Acesse sua conta para continuar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedGreen,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.x2l),
                      AppTextField(
                        label: 'E-mail',
                        controller: _emailController,
                        errorText: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      AppTextField(
                        label: 'Senha',
                        controller: _passwordController,
                        errorText: _passwordError,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _onLogin(),
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: AppSpacing.x2l),
                      AppButton(
                        label: 'Entrar',
                        onPressed: _onLogin,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ainda não tem conta? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () => context.goNamed(AppRoutes.register),
                            child: Text(
                              'Cadastrar',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.brandGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
