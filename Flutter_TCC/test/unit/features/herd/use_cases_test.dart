import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/herd/domain/repositories/animal_repository.dart';
import 'package:bovicare/features/herd/domain/usecases/delete_animal_use_case.dart';
import 'package:bovicare/features/herd/domain/usecases/get_animal_by_id_use_case.dart';
import 'package:bovicare/features/herd/domain/usecases/get_animals_use_case.dart';
import 'package:bovicare/features/herd/domain/usecases/save_animal_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnimalRepository extends Mock implements AnimalRepository {}

AnimalEntity _makeAnimal({
  String id = '1',
  String earTag = '001',
  AnimalStatus status = AnimalStatus.healthy,
}) =>
    AnimalEntity(
      id:        id,
      earTag:    earTag,
      breed:     'Nelore',
      sex:       AnimalSex.female,
      birthDate: DateTime(2022, 1, 15),
      status:    status,
      name:      'Mimosa',
    );

void main() {
  late MockAnimalRepository repo;

  setUp(() {
    repo = MockAnimalRepository();
    registerFallbackValue(
      _makeAnimal(),
    );
  });

  // ---------------------------------------------------------------------------
  // GetAnimalsUseCase
  // ---------------------------------------------------------------------------
  group('GetAnimalsUseCase', () {
    late GetAnimalsUseCase useCase;

    setUp(() => useCase = GetAnimalsUseCase(repo));

    test('returns list from repository', () async {
      final animals = [_makeAnimal(), _makeAnimal(id: '2')];
      when(() => repo.getAll()).thenAnswer((_) async => animals);

      final result = await useCase.call();

      expect(result, animals);
      verify(() => repo.getAll()).called(1);
    });

    test('returns empty list when no animals', () async {
      when(() => repo.getAll()).thenAnswer((_) async => []);

      final result = await useCase.call();

      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // GetAnimalByIdUseCase
  // ---------------------------------------------------------------------------
  group('GetAnimalByIdUseCase', () {
    late GetAnimalByIdUseCase useCase;

    setUp(() => useCase = GetAnimalByIdUseCase(repo));

    test('returns animal when found', () async {
      final animal = _makeAnimal(id: 'abc');
      when(() => repo.getById('abc')).thenAnswer((_) async => animal);

      final result = await useCase.call('abc');

      expect(result, animal);
    });

    test('returns null when not found', () async {
      when(() => repo.getById(any())).thenAnswer((_) async => null);

      final result = await useCase.call('nonexistent');

      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // SaveAnimalUseCase
  // ---------------------------------------------------------------------------
  group('SaveAnimalUseCase', () {
    late SaveAnimalUseCase useCase;

    setUp(() => useCase = SaveAnimalUseCase(repo));

    test('calls repository save', () async {
      final animal = _makeAnimal();
      when(() => repo.save(any())).thenAnswer((_) async {});

      await useCase.call(animal);

      verify(() => repo.save(animal)).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // DeleteAnimalUseCase
  // ---------------------------------------------------------------------------
  group('DeleteAnimalUseCase', () {
    late DeleteAnimalUseCase useCase;

    setUp(() => useCase = DeleteAnimalUseCase(repo));

    test('calls repository delete with correct id', () async {
      when(() => repo.delete(any())).thenAnswer((_) async {});

      await useCase.call('123');

      verify(() => repo.delete('123')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // AnimalEntityX extensions
  // ---------------------------------------------------------------------------
  group('AnimalEntityX', () {
    test('displayName with name includes earTag', () {
      final animal = _makeAnimal(earTag: '047');
      expect(animal.displayName, 'Mimosa — #047');
    });

    test('displayName without name shows only earTag', () {
      final animal = AnimalEntity(
        id: '1', earTag: '001', breed: 'Nelore',
        sex: AnimalSex.male, birthDate: DateTime(2022), status: AnimalStatus.healthy,
      );
      expect(animal.displayName, '#001');
    });

    test('sexLabel returns F for female', () {
      expect(_makeAnimal().sexLabel, 'F');
    });

    test('sexLabel returns M for male', () {
      final animal = AnimalEntity(
        id: '1', earTag: '001', breed: 'Nelore',
        sex: AnimalSex.male, birthDate: DateTime(2022), status: AnimalStatus.healthy,
      );
      expect(animal.sexLabel, 'M');
    });

    test('pregnancyProgress is 0 when no pregnancyDate', () {
      expect(_makeAnimal().pregnancyProgress, 0.0);
    });

    test('pregnancyProgress is between 0 and 1 when pregnant', () {
      final animal = AnimalEntity(
        id: '1', earTag: '001', breed: 'Nelore',
        sex: AnimalSex.female,
        birthDate: DateTime(2020),
        status: AnimalStatus.pregnant,
        pregnancyDate: DateTime.now().subtract(const Duration(days: 140)),
      );
      expect(animal.pregnancyProgress, inInclusiveRange(0.0, 1.0));
    });

    test('expectedBirthDate is null when no pregnancyDate', () {
      expect(_makeAnimal().expectedBirthDate, isNull);
    });

    test('expectedBirthDate is 283 days after pregnancyDate', () {
      final start = DateTime(2026);
      final animal = AnimalEntity(
        id: '1', earTag: '001', breed: 'Nelore',
        sex: AnimalSex.female, birthDate: DateTime(2020),
        status: AnimalStatus.pregnant, pregnancyDate: start,
      );
      expect(animal.expectedBirthDate, DateTime(2026, 10, 11));
    });
  });
}
