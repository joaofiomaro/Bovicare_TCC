import 'package:bovicare/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await container.read(tutorialProvider.notifier).ready;
  return container;
}

void main() {
  test('primeira abertura: mostra as boas-vindas e ainda não oferece dicas', () async {
    final c = await _container();
    final prefs = c.read(tutorialProvider);

    expect(prefs.loaded, isTrue);
    expect(prefs.introSeen, isFalse);
    expect(prefs.shouldOffer('herd'), isFalse);
  });

  test('ver as boas-vindas com dicas: cada tela oferece o passo a passo uma vez', () async {
    final c = await _container();
    final notifier = c.read(tutorialProvider.notifier);

    await notifier.finishIntro(tips: true);
    expect(c.read(tutorialProvider).shouldOffer('herd'), isTrue);

    await notifier.markSeen('herd');
    expect(c.read(tutorialProvider).shouldOffer('herd'), isFalse);
    expect(c.read(tutorialProvider).shouldOffer('brete'), isTrue);
  });

  test('pular as boas-vindas desliga as dicas', () async {
    final c = await _container();
    await c.read(tutorialProvider.notifier).finishIntro(tips: false);

    expect(c.read(tutorialProvider).shouldOffer('herd'), isFalse);
  });

  test('preferências persistem entre aberturas do app', () async {
    final c = await _container();
    final notifier = c.read(tutorialProvider.notifier);
    await notifier.finishIntro(tips: true);
    await notifier.markSeen('herd');

    // Nova "abertura" lendo o que ficou salvo no aparelho.
    final saved = await SharedPreferences.getInstance();
    final reopened = await _container({
      for (final k in saved.getKeys()) k: saved.get(k)!,
    });
    final prefs = reopened.read(tutorialProvider);

    expect(prefs.introSeen, isTrue);
    expect(prefs.seenScreens, {'herd'});
  });

  test('mostrar as dicas de novo: religa e esquece as telas vistas', () async {
    final c = await _container();
    final notifier = c.read(tutorialProvider.notifier);
    await notifier.finishIntro(tips: false);
    await notifier.markSeen('herd');

    await notifier.resetScreens();

    final prefs = c.read(tutorialProvider);
    expect(prefs.tipsEnabled, isTrue);
    expect(prefs.shouldOffer('herd'), isTrue);
  });
}
