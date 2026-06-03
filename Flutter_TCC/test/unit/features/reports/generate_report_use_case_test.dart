import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/herd/domain/repositories/animal_repository.dart';
import 'package:bovicare/features/reports/domain/entities/report_data.dart';
import 'package:bovicare/features/reports/domain/usecases/generate_report_use_case.dart';
import 'package:bovicare/features/vaccination/domain/entities/vaccination_record.dart';
import 'package:bovicare/features/vaccination/domain/repositories/vaccination_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class MockAnimalRepository extends Mock implements AnimalRepository {}

class MockVaccinationRepository extends Mock
    implements VaccinationRepository {}

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  late MockAnimalRepository animals;
  late MockVaccinationRepository vaccinations;
  late GenerateReportUseCase useCase;

  // Dentro do intervalo padrão (últimos 30 dias).
  final now = DateTime.now();

  final pregnant = AnimalEntity(
    id: '1',
    earTag: '047',
    name: 'Mimosa',
    breed: 'Nelore',
    sex: AnimalSex.female,
    birthDate: DateTime(2022, 3, 12),
    status: AnimalStatus.pregnant,
    weightKg: 384,
    pregnancyDate: now.subtract(const Duration(days: 100)),
  );

  final healthy = AnimalEntity(
    id: '2',
    earTag: '031',
    breed: 'Gir',
    sex: AnimalSex.male,
    birthDate: DateTime(2020, 1, 20),
    status: AnimalStatus.healthy,
  );

  final vaccination = VaccinationRecord(
    id: 'v1',
    animalId: '1',
    vaccineName: 'Aftosa',
    dose: '1ª dose',
    date: now,
    quarantineDays: 21,
    lot: '22B-2025',
  );

  setUp(() {
    animals = MockAnimalRepository();
    vaccinations = MockVaccinationRepository();
    useCase = GenerateReportUseCase(animals, vaccinations);
  });

  group('GenerateReportUseCase — sanitário', () {
    test('monta linhas das vacinações no período com nome do animal', () async {
      when(() => animals.getAll())
          .thenAnswer((_) async => [pregnant, healthy]);
      when(() => vaccinations.getAll())
          .thenAnswer((_) async => [vaccination]);

      final report = await useCase.call(
        ReportType.sanitary,
        const ReportFilter(),
      );

      expect(report.type, ReportType.sanitary);
      expect(report.rows, hasLength(1));
      expect(report.rows.first[0], 'Mimosa — #047');
      expect(report.rows.first[1], 'Aftosa');
      expect(report.rows.first[5], '22B-2025');
      // Carência = data + 21 dias, formatada.
      expect(report.rows.first[4], isNot('—'));
    });

    test('ignora vacinações fora do período', () async {
      final old = vaccination.copyWith(
        date: now.subtract(const Duration(days: 400)),
      );
      when(() => animals.getAll()).thenAnswer((_) async => [pregnant]);
      when(() => vaccinations.getAll()).thenAnswer((_) async => [old]);

      final report = await useCase.call(
        ReportType.sanitary,
        const ReportFilter(),
      );

      expect(report.rows, isEmpty);
    });
  });

  group('GenerateReportUseCase — reprodutivo', () {
    test('inclui apenas animais prenhes ou com data de cobertura', () async {
      when(() => animals.getAll())
          .thenAnswer((_) async => [pregnant, healthy]);

      final report = await useCase.call(
        ReportType.reproductive,
        const ReportFilter(),
      );

      expect(report.rows, hasLength(1));
      expect(report.rows.first[1], 'Prenha');
    });
  });

  group('GenerateReportUseCase — financeiro', () {
    test('inclui apenas animais com peso registrado', () async {
      when(() => animals.getAll())
          .thenAnswer((_) async => [pregnant, healthy]);

      final report = await useCase.call(
        ReportType.financial,
        const ReportFilter(),
      );

      expect(report.rows, hasLength(1));
      expect(report.rows.first[0], '#047');
      expect(report.rows.first[4], '384 kg');
    });
  });

  group('GenerateReportUseCase — inventário', () {
    test('inclui todos os animais do rebanho', () async {
      when(() => animals.getAll())
          .thenAnswer((_) async => [pregnant, healthy]);

      final report = await useCase.call(
        ReportType.inventory,
        const ReportFilter(),
      );

      expect(report.rows, hasLength(2));
      expect(report.headers, contains('Status'));
    });
  });
}
