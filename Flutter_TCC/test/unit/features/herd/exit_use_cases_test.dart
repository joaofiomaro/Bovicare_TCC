import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/herd/domain/entities/sale_record.dart';
import 'package:bovicare/features/herd/domain/repositories/animal_repository.dart';
import 'package:bovicare/features/herd/domain/repositories/sale_repository.dart';
import 'package:bovicare/features/herd/domain/usecases/record_animal_death_use_case.dart';
import 'package:bovicare/features/herd/domain/usecases/record_animal_sale_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSaleRepository extends Mock implements SaleRepository {}

class MockAnimalRepository extends Mock implements AnimalRepository {}

SaleRecord _sale({
  List<String> ids = const ['1', '2'],
  int? headCount,
  double totalValue = 8000,
}) =>
    SaleRecord(
      id:         's1',
      date:       DateTime(2026, 6, 3),
      type:       SaleType.lote,
      animalIds:  ids,
      headCount:  headCount ?? ids.length,
      totalValue: totalValue,
    );

void main() {
  setUpAll(() => registerFallbackValue(_sale()));

  group('RecordAnimalSaleUseCase', () {
    late MockSaleRepository repo;
    late RecordAnimalSaleUseCase useCase;

    setUp(() {
      repo = MockSaleRepository();
      useCase = RecordAnimalSaleUseCase(repo);
    });

    test('delega ao repositório quando válida', () async {
      when(() => repo.recordSale(any())).thenAnswer((_) async {});
      final sale = _sale();

      await useCase.call(sale);

      verify(() => repo.recordSale(sale)).called(1);
    });

    test('rejeita lista de animais vazia', () {
      expect(
        () => useCase.call(_sale(ids: [], headCount: 0)),
        throwsArgumentError,
      );
    });

    test('rejeita animais duplicados', () {
      expect(
        () => useCase.call(_sale(ids: ['1', '1'])),
        throwsArgumentError,
      );
    });

    test('rejeita headCount divergente', () {
      expect(
        () => useCase.call(_sale(ids: ['1', '2'], headCount: 5)),
        throwsArgumentError,
      );
    });

    test('rejeita valor total negativo', () {
      expect(
        () => useCase.call(_sale(totalValue: -1)),
        throwsArgumentError,
      );
    });
  });

  group('RecordAnimalDeathUseCase', () {
    late MockAnimalRepository repo;
    late RecordAnimalDeathUseCase useCase;
    final date = DateTime(2026, 6, 3);

    setUp(() {
      repo = MockAnimalRepository();
      useCase = RecordAnimalDeathUseCase(repo);
    });

    test('delega ao repositório quando válido', () async {
      when(() => repo.recordDeath(
            animalIds: ['1'],
            date: date,
            cause: 'doença',
          )).thenAnswer((_) async {});

      await useCase.call(animalIds: ['1'], date: date, cause: 'doença');

      verify(() => repo.recordDeath(
            animalIds: ['1'],
            date: date,
            cause: 'doença',
          )).called(1);
    });

    test('rejeita lista vazia', () {
      expect(
        () => useCase.call(animalIds: [], date: date),
        throwsArgumentError,
      );
    });

    test('rejeita duplicados', () {
      expect(
        () => useCase.call(animalIds: ['1', '1'], date: date),
        throwsArgumentError,
      );
    });
  });

  group('SaleRecordX.valuePerHead', () {
    test('divide o valor total pelo número de cabeças', () {
      expect(_sale(ids: ['1', '2', '3', '4']).valuePerHead, 2000);
    });

    test('retorna 0 quando não há cabeças (sem divisão por zero)', () {
      expect(_sale(ids: [], headCount: 0, totalValue: 100).valuePerHead, 0);
    });
  });

  group('AnimalEntityX.isArchived', () {
    AnimalEntity animal(AnimalExitType exit) => AnimalEntity(
          id:        '1',
          earTag:    '001',
          breed:     'Nelore',
          sex:       AnimalSex.female,
          birthDate: DateTime(2022),
          status:    AnimalStatus.healthy,
          exitType:  exit,
        );

    test('ativo por padrão não é arquivado', () {
      expect(animal(AnimalExitType.active).isArchived, isFalse);
    });

    test('vendido é arquivado', () {
      expect(animal(AnimalExitType.sold).isArchived, isTrue);
    });

    test('óbito é arquivado', () {
      expect(animal(AnimalExitType.deceased).isArchived, isTrue);
    });
  });
}
