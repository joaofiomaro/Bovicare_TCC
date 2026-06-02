import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_radius.dart';
import 'app_button.dart';

/// Exibe um bottom sheet de confirmação padronizado.
/// Uso: AppBottomSheet.show(context, ...).
class AppBottomSheet {
  const AppBottomSheet._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancelar',
    AppButtonVariant confirmVariant = AppButtonVariant.primary,
    IconData? icon,
    Color? iconColor,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheetContent(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmVariant: confirmVariant,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  const _BottomSheetContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmVariant,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final AppButtonVariant confirmVariant;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.base, AppSpacing.base,
        AppSpacing.base + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: AppRadius.fullAll),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (icon != null) ...[
            Icon(icon, size: 48, color: iconColor ?? cs.primary),
            const SizedBox(height: AppSpacing.base),
          ],
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.x2l),
          AppButton(label: confirmLabel, onPressed: () => Navigator.pop(context, true), variant: confirmVariant),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: cancelLabel, onPressed: () => Navigator.pop(context, false), variant: AppButtonVariant.ghost),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
