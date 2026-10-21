import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

enum AppButtonVariant { primary, outline, danger, ghost }

/// Botão padronizado do design system com variantes e estado de loading.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    // Cor do indicator deve contrastar com o fundo de cada variante.
    final loadingColor = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.danger => AppColors.white,
      AppButtonVariant.outline                            => AppColors.brandGreen,
      AppButtonVariant.ghost                             => AppColors.mutedGreen,
    };

    final Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: loadingColor),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              // Flexible: em tela estreita/fonte ampliada o rótulo quebra
              // linha em vez de estourar a largura do botão.
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: AppColors.white,
            minimumSize: fullWidth ? const Size.fromHeight(52) : null,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            elevation: 0,
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brandGreen,
            minimumSize: fullWidth ? const Size.fromHeight(52) : null,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            side: const BorderSide(color: AppColors.brandGreen),
          ),
          child: child,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.white,
            minimumSize: fullWidth ? const Size.fromHeight(52) : null,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            elevation: 0,
          ),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.mutedGreen,
            minimumSize: fullWidth ? const Size.fromHeight(52) : null,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
          child: child,
        ),
    };
  }
}
