import 'package:bovicare/features/tutorial/domain/tutorial_step.dart';
import 'package:bovicare/features/tutorial/presentation/widgets/screen_tutorial.dart';
import 'package:bovicare/features/tutorial/presentation/widgets/tutorial_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _guide = ScreenGuide(
  id:    'teste',
  title: 'Tela de teste',
  steps: [
    TutorialStep(
      icon:   Icons.search_rounded,
      title:  'Passo da busca',
      body:   'Explica a busca.',
      target: 'teste.busca',
    ),
    TutorialStep(
      icon:  Icons.info_outline,
      title: 'Passo final',
      body:  'Sem elemento destacado.',
    ),
  ],
);

Future<void> _pump(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: ScreenTutorial(
          guide: _guide,
          child: Scaffold(
            appBar: _Bar(),
            body: Center(
              child: TutorialTarget(id: 'teste.busca', child: Text('Busca')),
            ),
          ),
        ),
      ),
    ),
  );
  // Leitura das preferências + espera antes do convite.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

class _Bar extends StatelessWidget implements PreferredSizeWidget {
  const _Bar();

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) =>
      AppBar(actions: const [TutorialHelpButton()]);
}

void main() {
  testWidgets('primeira visita oferece o passo a passo e percorre os passos',
      (tester) async {
    await _pump(tester, {'tutorial_intro_seen': true});

    expect(find.text('Primeira vez em Tela de teste?'), findsOneWidget);
    await tester.tap(find.text('Ver passo a passo'));
    await tester.pumpAndSettle();

    expect(find.text('Passo da busca'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Passo final'), findsOneWidget);
    expect(find.text('Pular'), findsNothing);
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();

    expect(find.text('Passo final'), findsNothing);
    expect(find.text('Busca'), findsOneWidget);
  });

  testWidgets('pular fecha o convite e não volta a perguntar', (tester) async {
    await _pump(tester, {'tutorial_intro_seen': true});

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();
    expect(find.text('Primeira vez em Tela de teste?'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('tutorial_seen_screens'), contains('teste'));
  });

  testWidgets('com as dicas desligadas não pergunta, mas o ? mostra o tutorial',
      (tester) async {
    await _pump(tester, {
      'tutorial_intro_seen':   true,
      'tutorial_tips_enabled': false,
    });
    expect(find.text('Primeira vez em Tela de teste?'), findsNothing);

    await tester.tap(find.byTooltip('Como usar esta tela'));
    await tester.pumpAndSettle();
    expect(find.text('Passo da busca'), findsOneWidget);

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();
    expect(find.text('Passo da busca'), findsNothing);
  });
}
