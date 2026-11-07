import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/tutorial_step.dart';
import 'tutorial_target.dart';

/// Abre o passo a passo sobre a tela atual: escurece o fundo, destaca o
/// elemento de cada passo e mostra um cartão com a explicação.
Future<void> showTutorialTour(BuildContext context, List<TutorialStep> steps) {
  if (steps.isEmpty) return Future.value();
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque:             false,
      transitionDuration: AppDurations.fast,
      reverseTransitionDuration: AppDurations.fast,
      pageBuilder: (_, __, ___) => _TutorialTour(steps: steps),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _TutorialTour extends StatefulWidget {
  const _TutorialTour({required this.steps});
  final List<TutorialStep> steps;

  @override
  State<_TutorialTour> createState() => _TutorialTourState();
}

class _TutorialTourState extends State<_TutorialTour> {
  int _index = 0;
  Rect? _hole;

  TutorialStep get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  /// Rola até o elemento do passo (se preciso) e mede onde ele está.
  Future<void> _locate() async {
    final id = _step.target;
    final target = id == null ? null : TutorialTarget.contextOf(id);
    if (target == null) {
      if (mounted) setState(() => _hole = null);
      return;
    }
    if (Scrollable.maybeOf(target) != null) {
      await Scrollable.ensureVisible(
        target,
        alignment: 0.3,
        duration:  AppDurations.normal,
        curve:     Curves.easeOutCubic,
      );
    }
    if (!mounted || !target.mounted) return;
    final box = target.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    // Elemento sem tamanho (seção vazia): cartão no centro, sem destaque.
    if (box.size.isEmpty) {
      setState(() => _hole = null);
      return;
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _hole = rect.inflate(6));
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0) return;
    if (next >= widget.steps.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index = next);
    _locate();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final hole = _hole;

    // Cartão abaixo do destaque quando há espaço, senão acima; se o destaque
    // ocupa quase a tela toda, o cartão fica no rodapé, por cima dele.
    const cardSpace = 240.0;
    final spaceBelow = hole == null ? 0.0 : size.height - padding.bottom - hole.bottom;
    final spaceAbove = hole == null ? 0.0 : hole.top - padding.top;
    final double? top;
    final double? bottom;
    if (hole == null) {
      top = null;
      bottom = null;
    } else if (spaceBelow >= cardSpace) {
      top = hole.bottom + AppSpacing.md;
      bottom = null;
    } else if (spaceAbove >= cardSpace) {
      top = null;
      bottom = size.height - hole.top + AppSpacing.md;
    } else {
      top = null;
      bottom = padding.bottom + AppSpacing.base;
    }
    final card = _StepCard(
      key:     ValueKey(_index),
      step:    _step,
      index:   _index,
      total:   widget.steps.length,
      isLast:  _isLast,
      onNext:  () => _go(1),
      onBack:  _index > 0 ? () => _go(-1) : null,
      onSkip:  () => Navigator.of(context).pop(),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Toque no fundo avança, como num app de apresentação.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap:    () => _go(1),
              // Sem destaque, fundo inteiro escuro; com destaque, o "buraco"
              // desliza de um elemento para o outro.
              child: hole == null
                  ? const CustomPaint(painter: _SpotlightPainter(null))
                  : TweenAnimationBuilder<Rect?>(
                      tween:    RectTween(end: hole),
                      duration: AppDurations.normal,
                      curve:    Curves.easeOutCubic,
                      builder:  (_, rect, __) =>
                          CustomPaint(painter: _SpotlightPainter(rect)),
                    ),
            ),
          ),
          if (hole == null)
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: _constrained(card),
                ),
              ),
            )
          else
            Positioned(
              left:   AppSpacing.base,
              right:  AppSpacing.base,
              top:    top,
              bottom: bottom,
              child:  _constrained(card),
            ),
        ],
      ),
    );
  }

  Widget _constrained(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AnimatedSwitcher(duration: AppDurations.fast, child: child),
        ),
      );
}

/// Fundo escuro com um "buraco" arredondado sobre o elemento destacado.
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.hole);
  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final rect = hole;
    if (rect == null) {
      canvas.drawPath(screen, Paint()..color = Colors.black.withValues(alpha: 0.72));
      return;
    }
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.lg));
    canvas
      ..drawPath(
        Path.combine(PathOperation.difference, screen, Path()..addRRect(rrect)),
        Paint()..color = Colors.black.withValues(alpha: 0.72),
      )
      ..drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.brandLight,
      );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
    this.onBack,
    super.key,
  });

  final TutorialStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color:        cs.surface,
      borderRadius: AppRadius.lgAll,
      elevation:    8,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.brandLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(step.icon, color: AppColors.brandGreen, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    step.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(step.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                _Dots(index: index, total: total),
                const Spacer(),
                if (!isLast)
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(foregroundColor: AppColors.mutedGreen),
                    child: const Text('Pular'),
                  ),
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    tooltip:   'Voltar',
                    icon:      const Icon(Icons.arrow_back_rounded),
                    color:     AppColors.brandGreen,
                  ),
                const SizedBox(width: AppSpacing.xs),
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(48, 44),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                    elevation: 0,
                  ),
                  child: Text(isLast ? 'Entendi' : 'Próximo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Progresso do tutorial: um ponto por passo, o atual alongado.
class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.total});
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Passo ${index + 1} de $total',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < math.min(total, 8); i++)
              AnimatedContainer(
                duration: AppDurations.fast,
                margin:   const EdgeInsets.only(right: 4),
                width:    i == index ? 16 : 6,
                height:   6,
                decoration: BoxDecoration(
                  color: i == index ? AppColors.brandGreen : AppColors.ghostGreen,
                  borderRadius: AppRadius.fullAll,
                ),
              ),
          ],
        ),
      );
}
