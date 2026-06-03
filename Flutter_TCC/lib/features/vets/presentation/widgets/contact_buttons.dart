import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/vet_entity.dart';

class ContactButtons extends StatelessWidget {
  const ContactButtons({required this.vet, super.key});
  final VetEntity vet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ContactButton(
          icon:    Icons.phone_rounded,
          label:   'Ligar agora',
          variant: _Variant.primary,
          onTap:   () => _launch(context, 'tel:${vet.phone}'),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (vet.whatsapp != null) ...[
          _ContactButton(
            icon:    Icons.chat_rounded,
            label:   'WhatsApp',
            variant: _Variant.outline,
            onTap:   () => _launch(
              context,
              'https://wa.me/${vet.whatsapp!.replaceAll(RegExp(r'[^\d]'), '')}',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (vet.email != null)
          _ContactButton(
            icon:    Icons.email_outlined,
            label:   'Enviar e-mail',
            variant: _Variant.outline,
            onTap:   () => _launch(context, 'mailto:${vet.email}'),
          ),
      ],
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      AppToast.error(context, 'Não foi possível abrir o aplicativo.');
    }
  }
}

enum _Variant { primary, outline }

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.variant,
    required this.onTap,
  });

  final IconData  icon;
  final String    label;
  final _Variant  variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == _Variant.primary;
    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed:  onTap,
              icon:       Icon(icon, size: 18),
              label:      Text(label),
              style:      ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                minimumSize:     const Size.fromHeight(48),
                shape:           const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                elevation: 0,
              ),
            )
          : OutlinedButton.icon(
              onPressed:  onTap,
              icon:       Icon(icon, size: 18),
              label:      Text(label),
              style:      OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandGreen,
                minimumSize:     const Size.fromHeight(48),
                shape:           const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                side: const BorderSide(color: AppColors.brandGreen),
              ),
            ),
    );
  }
}
