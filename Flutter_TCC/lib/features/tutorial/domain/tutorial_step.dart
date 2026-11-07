import 'package:flutter/widgets.dart';

/// Um passo do tutorial de uma tela: destaca o elemento marcado com
/// `TutorialTarget(id: target)` e explica para que ele serve. Sem [target]
/// (ou se o elemento não estiver na tela), o cartão aparece centralizado.
class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.body,
    required this.icon,
    this.target,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? target;
}

/// Tutorial completo de uma tela.
class ScreenGuide {
  const ScreenGuide({
    required this.id,
    required this.title,
    required this.steps,
  });

  /// Chave salva no aparelho para lembrar que a tela já foi apresentada.
  final String id;

  /// Nome da tela como o usuário a conhece ("Rebanho", "Brete"...).
  final String title;
  final List<TutorialStep> steps;
}
