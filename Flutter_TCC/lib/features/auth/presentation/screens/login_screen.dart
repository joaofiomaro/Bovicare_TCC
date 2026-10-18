import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet_container.dart';
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
    final emailVal  = EmailInput.dirty(_emailController.text.trim());
    // No login só se exige senha preenchida: a política de tamanho vale para
    // o cadastro; quem decide se a senha confere é o Firebase Auth.
    final passEmpty = _passwordController.text.isEmpty;
    setState(() {
      _emailError    = emailVal.isValid ? null : 'Informe um e-mail válido.';
      _passwordError = passEmpty ? 'Informe sua senha.' : null;
    });
    return emailVal.isValid && !passEmpty;
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
      final msg = error is Failure
          ? error.message
          : 'Erro ao fazer login.';
      AppToast.error(context, msg);
    }
  }

  Future<void> _showForgotPassword() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showModalBottomSheet<String>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (ctx) => AppSheetContainer(
        children: [
          Text('Redefinir senha', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enviaremos um link para o seu e-mail para criar uma nova senha.',
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGreen,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label:        'E-mail',
            controller:   controller,
            keyboardType: TextInputType.emailAddress,
            prefixIcon:   Icons.email_outlined,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label:     'Enviar link',
            icon:      Icons.send_rounded,
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
    controller.dispose();
    if (email == null || !mounted) return;

    if (!EmailInput.dirty(email).isValid) {
      AppToast.error(context, 'Informe um e-mail válido.');
      return;
    }
    final error =
        await ref.read(authProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    if (error != null) {
      AppToast.error(context, error);
    } else {
      // Mesma mensagem com ou sem conta: não revela e-mails cadastrados.
      AppToast.success(
        context,
        'Se houver uma conta com este e-mail, você receberá o link em instantes.',
      );
    }
  }

  Future<void> _onLoginWithGoogle() async {
    final ok = await ref.read(authProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.goNamed(AppRoutes.dashboard);
    } else {
      // Exibe erro apenas se houve falha real (não cancelamento).
      final error = ref.read(authProvider).error;
      if (error != null) {
        final msg = error is Failure
            ? error.message
            : 'Erro ao fazer login com Google.';
        AppToast.error(context, msg);
      }
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
                  Image.asset(
                    'assets/images/bovicare_logo.png',
                    width: 80,
                    height: 80,
                  ),
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrar',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPassword,
                          child: const Text(
                            'Esqueci minha senha',
                            style: TextStyle(color: AppColors.brandGreen),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      AppButton(
                        label: 'Entrar',
                        onPressed: _onLogin,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      const _Divider(),
                      const SizedBox(height: AppSpacing.base),
                      _GoogleSignInButton(
                        onPressed: _onLoginWithGoogle,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: AppSpacing.x2l),
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
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
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

// ---------------------------------------------------------------------------

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'ou',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGreen,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.onPressed,
    required this.isLoading,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.ghostGreen),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleIcon(),
                  const SizedBox(width: 12),
                  Text(
                    'Continuar com Google',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFF4285F4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
