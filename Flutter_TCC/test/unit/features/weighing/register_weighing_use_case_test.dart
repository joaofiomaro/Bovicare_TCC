import 'package:bovicare/features/weighing/domain/entities/weighing.dart';
import 'package:bovicare/features/weighing/domain/repositories/weighing_repository.dart';
import 'package:bovicare/features/weighing/domain/usecases/get_animal_weighings_use_case.dart';
import 'package:bovicare/features/weighing/domain/usecases/register_weighing_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWeighingRepository extends Mock implements WeighingRepository {}

Weighing _makeWeighing() => Weighing(
      id:       'w1',
      animalId: 'a1',
      weightKg: 350,
      date:     DateTime(2026, 6, 3),
    );

void main() {
  setUpAll(() => registerFallbackValue(_makeWeighing()));

  late MockWeighingRepository repo;

  setUp(() => repo = MockWeighingRepository());

  group('RegisterWeighingUseCase', () {
    test('delega ao repositório', () async {
      when(() => repo.add(any())).thenAnswer((_) async {});

      await RegisterWeighingUseCase(repo).call(_makeWeighing());

      verify(() => repo.add(_makeWeighing())).called(1);
    });
  });

  group('GetAnimalWeighingsUseCase', () {
    test('retorna as pesagens do repositório', () async {
      final weighings = [_makeWeighing()];
      when(() => repo.getByAnimal('a1')).thenAnswer((_) async => weighings);

      final result = await GetAnimalWeighingsUseCase(repo).call('a1');

      expect(result, weighings);
      verify(() => repo.getByAnimal('a1')).called(1);
    });
  });
}
