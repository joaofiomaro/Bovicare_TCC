import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/herd/domain/repositories/animal_repository.dart';
import 'package:bovicare/features/herd/presentation/providers/animals_provider.dart';
import 'package:bovicare/features/herd/presentation/screens/animal_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnimalRepository extends Mock implements AnimalRepository {}

AnimalEntity _makeAnimal() => AnimalEntity(
      id:        '1',
      earTag:    '047',
      name:      'Mimosa',
      breed:     'Nelore',
      sex:       AnimalSex.female,
      birthDate: DateTime(2022, 3, 12),
      status:    AnimalStatus.pregnant,
      weightKg:  384,
    );

void main() {
  setUpAll(() => registerFallbackValue(_makeAnimal()));

  late MockAnimalRepository repo;

  setUp(() {
    repo = MockAnimalRepository();
    when(() => repo.getAll()).thenAnswer((_) async => [_makeAnimal()]);
    when(() => repo.save(any())).thenAnswer((_) async {});
  });

  Widget buildScope(Widget child) => ProviderScope(
        overrides: [animalRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: child),
      );

  testWidgets('modo edição pré-preenche os campos do animal', (tester) async {
    await tester.pumpWidget(buildScope(AnimalFormScreen(initial: _makeAnimal())));

    expect(find.text('Editar animal'), findsOneWidget);
    expect(find.text('Salvar alterações'), findsOneWidget);
    expect(find.text('047'), findsOneWidget);
    expect(find.text('Mimosa'), findsOneWidget);
    expect(find.text('384'), findsOneWidget);
  });

  testWidgets('modo cadastro mostra título e botão de novo', (tester) async {
    await tester.pumpWidget(buildScope(const AnimalFormScreen()));

    expect(find.text('Novo animal'), findsOneWidget);
    expect(find.text('Cadastrar animal'), findsOneWidget);
  });

  testWidgets('salvar edição preserva o id e chama o repositório',
      (tester) async {
    // Empurra o form sobre uma rota base para que o pop pós-salvar funcione.
    await tester.pumpWidget(
      buildScope(
        Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) => AnimalFormScreen(initial: _makeAnimal()),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // O botão fica abaixo da dobra no form longo — garante visibilidade.
    final saveButton = find.text('Salvar alterações');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final captured = verify(() => repo.save(captureAny())).captured;
    expect(captured, hasLength(1));
    expect((captured.single as AnimalEntity).id, '1');
    expect((captured.single as AnimalEntity).earTag, '047');
  });
}
