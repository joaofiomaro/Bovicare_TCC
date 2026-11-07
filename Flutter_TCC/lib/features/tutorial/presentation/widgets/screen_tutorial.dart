import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/tutorial_step.dart';
import '../providers/tutorial_provider.dart';
import 'tutorial_tour.dart';

/// Envolve uma tela com o tutorial dela. Na primeira visita (se as dicas
/// estiverem ligadas) pergunta se o usuário quer ver o passo a passo; a
/// qualquer momento o [TutorialHelpButton] do cabeçalho mostra de novo.
class ScreenTutorial extends ConsumerStatefulWidget {
  const ScreenTutorial({required this.guide, required this.child, super.key});

  final ScreenGuide guide;
  final Widget child;

  @override
  ConsumerState<ScreenTutorial> createState() => _ScreenTutorialState();
}

class _ScreenTutorialState extends ConsumerState<ScreenTutorial> {
  bool _offered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOffer());
  }

  Future<void> _maybeOffer() async {
    if (_offered || !mounted) return;
    if (!ref.read(tutorialProvider).shouldOffer(widget.guide.id)) return;
    _offered = true;
    // Deixa a tela assentar (transição e primeiros dados) antes de perguntar.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) {
      _offered = false;
      return;
    }
    final notifier = ref.read(tutorialProvider.notifier);
    unawaited(notifier.markSeen(widget.guide.id));

    final choice = await showModalBottomSheet<_InviteChoice>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _TutorialInvite(guide: widget.guide),
    );
    if (!mounted) return;
    switch (choice) {
      case _InviteChoice.tour:
        await start();
      case _InviteChoice.disable:
        await notifier.setTipsEnabled(enabled: false);
        if (mounted) {
          AppToast.info(context, 'Dicas desligadas. Para religar: Perfil › Ajuda e tutoriais.');
        }
      case _InviteChoice.skip || null:
        break;
    }
  }

  Future<void> start() => showTutorialTour(context, widget.guide.steps);

  @override
  Widget build(BuildContext context) {
    // As preferências podem terminar de carregar depois da primeira tela.
    ref.listen(tutorialProvider, (prev, next) {
      if (!(prev?.loaded ?? false) && next.loaded) _maybeOffer();
    });
    return _ScreenTutorialScope(start: start, child: widget.child);
  }
}

class _ScreenTutorialScope extends InheritedWidget {
  const _ScreenTutorialScope({required this.start, required super.child});
  final Future<void> Function() start;

  @override
  bool updateShouldNotify(_ScreenTutorialScope old) => false;
}

/// Botão "?" para o cabeçalho verde: mostra o tutorial da tela atual.
class TutorialHelpButton extends StatelessWidget {
  const TutorialHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_ScreenTutorialScope>();
    if (scope == null) return const SizedBox.shrink();
    return IconButton(
      onPressed: scope.start,
      tooltip:   'Como usar esta tela',
      icon:      const Icon(Icons.help_outline_rounded, color: Colors.white),
    );
  }
}

enum _InviteChoice { tour, skip, disable }

class _TutorialInvite extends StatelessWidget {
  const _TutorialInvite({required this.guide});
  final ScreenGuide guide;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = guide.steps.length;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.base, AppSpacing.base,
        AppSpacing.base + MediaQuery.paddingOf(context).bottom,
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
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.brandLight, shape: BoxShape.circle),
            child: const Icon(Icons.lightbulb_outline_rounded, size: 32, color: AppColors.brandGreen),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'Primeira vez em ${guide.title}?',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mostro em $steps ${steps == 1 ? 'passo' : 'passos'} rápidos como esta '
            'tela funciona. Você pode rever quando quiser no botão ? do topo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label:     'Ver passo a passo',
            icon:      Icons.play_arrow_rounded,
            onPressed: () => Navigator.pop(context, _InviteChoice.tour),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label:     'Pular',
            variant:   AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context, _InviteChoice.skip),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label:     'Não mostrar dicas nas outras telas',
            variant:   AppButtonVariant.ghost,
            onPressed: () => Navigator.pop(context, _InviteChoice.disable),
          ),
        ],
      ),
    );
  }
}
