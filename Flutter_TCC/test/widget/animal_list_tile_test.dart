import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/herd/domain/repositories/animal_repository.dart';
import 'package:bovicare/features/herd/presentation/providers/animals_provider.dart';
import 'package:bovicare/features/herd/presentation/widgets/animal_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAnimalRepository extends Mock implements AnimalRepository {}

AnimalEntity _animal(String id, String earTag) => AnimalEntity(
      id:        id,
      earTag:    earTag,
      name:      'Vaca',
      breed:     'Nelore',
      sex:       AnimalSex.female,
      birthDate: DateTime(2022, 3, 12),
      status:    AnimalStatus.healthy,
    );

/// Lista mínima equivalente à do rebanho, ligada ao [animalsProvider] real.
class _HerdHost extends ConsumerWidget {
  const _HerdHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(animalsProvider).valueOrNull ?? const [];
    return Scaffold(
      body: ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) => AnimalListTile(
          key:      ValueKey(list[i].id),
          animal:   list[i],
          onTap:    () {},
          onDelete: () =>
              ref.read(animalsProvider.notifier).delete(list[i].id),
        ),
      ),
    );
  }
}

void main() {
  late MockAnimalRepository repo;

  setUp(() {
    repo = MockAnimalRepository();
    when(() => repo.getAll()).thenAnswer(
      (_) async => [_animal('a1', '047'), _animal('a2', '048')],
    );
  });

  /// Reproduz a navegação real do app: a tela do rebanho vive dentro de um
  /// ShellRoute (Navigator aninhado) e o diálogo abre no Navigator raiz.
  Future<void> pumpHerd(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/herd',
      routes: [
        ShellRoute(
          builder: (_, __, child) => child,
          routes: [
            GoRoute(path: '/herd', builder: (_, __) => const _HerdHost()),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [animalRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipe(WidgetTester tester, String name) async {
    await tester.drag(find.text(name), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Remover animal'), findsOneWidget);
  }

  testWidgets('cancelar a remoção fecha só o diálogo e mantém a lista',
      (tester) async {
    await pumpHerd(tester);
    await swipe(tester, 'Vaca — #047');

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Remover animal'), findsNothing);
    expect(find.text('Vaca — #047'), findsOneWidget);
    expect(find.text('Vaca — #048'), findsOneWidget);
    verifyNever(() => repo.delete(any()));
  });

  testWidgets('tocar fora do diálogo também cancela', (tester) async {
    await pumpHerd(tester);
    await swipe(tester, 'Vaca — #047');

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Vaca — #047'), findsOneWidget);
    verifyNever(() => repo.delete(any()));
  });

  testWidgets('confirmar remove o animal sem quebrar a tela', (tester) async {
    when(() => repo.delete('a1')).thenAnswer((_) async {});
    await pumpHerd(tester);
    await swipe(tester, 'Vaca — #047');

    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();
    // Deixa terminar a animação de entrada dos tiles reconstruídos.
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Vaca — #047'), findsNothing);
    expect(find.text('Vaca — #048'), findsOneWidget);
    verify(() => repo.delete('a1')).called(1);
  });

  testWidgets('falha ao remover devolve o animal à lista', (tester) async {
    when(() => repo.delete('a1')).thenThrow(Exception('offline'));
    await pumpHerd(tester);
    await swipe(tester, 'Vaca — #047');

    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();
    // Deixa terminar a animação de entrada dos tiles reconstruídos.
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Vaca — #047'), findsOneWidget);
  });
}
