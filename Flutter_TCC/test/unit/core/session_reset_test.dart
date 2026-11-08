import 'package:bovicare/core/session/session_reset.dart';
import 'package:bovicare/features/auth/domain/entities/user_entity.dart';
import 'package:bovicare/features/auth/presentation/providers/auth_provider.dart';
import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/herd/domain/repositories/animal_repository.dart';
import 'package:bovicare/features/herd/presentation/providers/animals_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnimalRepository extends Mock implements AnimalRepository {}

/// Auth controlável pelo teste (sem Firebase).
class _FakeAuth extends AuthNotifier {
  @override
  Future<UserEntity?> build() async => null;

  // Método (não setter) para ler como ação no teste.
  // ignore: use_setters_to_change_properties
  void signIn(UserEntity? user) => state = AsyncData(user);
}

UserEntity _user(String id) =>
    UserEntity(id: id, name: id, email: '$id@x.com', role: UserRole.producer);

AnimalEntity _animal(String id) => AnimalEntity(
      id:        id,
      earTag:    id,
      breed:     'Nelore',
      sex:       AnimalSex.female,
      birthDate: DateTime(2022),
      status:    AnimalStatus.healthy,
    );

void main() {
  test('trocar de conta descarta o rebanho e a busca da conta anterior',
      () async {
    final repo = MockAnimalRepository();
    var owner = 'A';
    when(repo.getAll).thenAnswer((_) async => [_animal('boi-de-$owner')]);

    final c = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_FakeAuth.new),
        animalRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    c
      ..read(sessionResetProvider)
      ..listen(animalsProvider, (_, __) {});
    await c.read(authProvider.future);

    (c.read(authProvider.notifier) as _FakeAuth).signIn(_user('A'));
    expect((await c.read(animalsProvider.future)).single.id, 'boi-de-A');
    c.read(herdSearchProvider.notifier).state = 'mimosa';

    // Logout e login com outra conta, sem reiniciar o app.
    owner = 'B';
    (c.read(authProvider.notifier) as _FakeAuth)
      ..signIn(null)
      ..signIn(_user('B'));

    expect((await c.read(animalsProvider.future)).single.id, 'boi-de-B');
    expect(c.read(herdSearchProvider), isEmpty);
  });

  test('atualizar o perfil (mesmo uid) não recarrega os dados', () async {
    final repo = MockAnimalRepository();
    when(repo.getAll).thenAnswer((_) async => [_animal('x')]);

    final c = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_FakeAuth.new),
        animalRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    c
      ..read(sessionResetProvider)
      ..listen(animalsProvider, (_, __) {});
    await c.read(authProvider.future);

    final auth = c.read(authProvider.notifier) as _FakeAuth
      ..signIn(_user('A'));
    await c.read(animalsProvider.future);
    clearInteractions(repo);

    auth.signIn(_user('A').copyWith(name: 'Novo nome'));
    await c.read(animalsProvider.future);
    verifyNever(repo.getAll);
  });
}
