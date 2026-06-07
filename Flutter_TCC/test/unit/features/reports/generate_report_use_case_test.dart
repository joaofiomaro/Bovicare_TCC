import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/herd/domain/entities/sale_record.dart';
import 'package:bovicare/features/herd/domain/repositories/animal_repository.dart';
import 'package:bovicare/features/herd/domain/repositories/sale_repository.dart';
import 'package:bovicare/features/reports/domain/entities/report_data.dart';
import 'package:bovicare/features/reports/domain/usecases/generate_report_use_case.dart';
import 'package:bovicare/features/vaccination/domain/entities/vaccination_record.dart';
import 'package:bovicare/features/vaccination/domain/repositories/vaccination_repository.dart';
import 'package:bovicare/features/weighing/domain/entities/weighing.dart';
import 'package:bovicare/features/weighing/domain/repositories/weighing_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class MockAnimalRepository extends Mock implements AnimalRepository {}

class MockVaccinationRepository extends Mock
    implements VaccinationRepository {}

class MockSaleRepository extends Mock implements SaleRepository {}

class MockWeighingRepository extends Mock implements WeighingRepository {}

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  late MockAnimalRepository animals;
  late MockVaccinationRepository vaccinations;
  late MockSaleRepository sales;
  late MockWeighingRepository weighings;
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
    sales = MockSaleRepository();
    weighings = MockWeighingRepository();
    useCase = GenerateReportUseCase(animals, vaccinations, sales, weighings);

    // Defaults — sobrescritos por teste quando relevante.
    when(() => weighings.getByAnimal(any())).thenAnswer((_) async => []);
    when(() => sales.getAll()).thenAnswer((_) async => []);
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
      expect(report.headers, contains('GMD'));
    });

    test('exibe GMD quando há pesagens; "—" quando não há', () async {
      when(() => animals.getAll()).thenAnswer((_) async => [pregnant]);
      // 30 kg em 30 dias ⇒ 1.000 kg/dia.
      when(() => weighings.getByAnimal('1')).thenAnswer(
        (_) async => [
          Weighing(
            id: 'w1',
            animalId: '1',
            weightKg: 354,
            date: now.subtract(const Duration(days: 30)),
          ),
          Weighing(id: 'w2', animalId: '1', weightKg: 384, date: now),
        ],
      );

      final report = await useCase.call(
        ReportType.financial,
        const ReportFilter(),
      );

      // GMD é a coluna 5 (entre Peso e Status).
      expect(report.rows.first[5], '1.000 kg/dia');
    });
  });

  group('GenerateReportUseCase — vendas', () {
    final sale = SaleRecord(
      id: 's1',
      date: now.subtract(const Duration(days: 2)),
      type: SaleType.lote,
      animalIds: const ['1', '2'],
      headCount: 2,
      totalValue: 9000,
      totalWeightKg: 600, // 40 @ ⇒ R$ 225/@
      buyer: 'Frigorífico X',
    );

    test('monta linhas e total geral do período', () async {
      when(() => sales.getAll()).thenAnswer((_) async => [sale]);

      final report = await useCase.call(
        ReportType.sales,
        const ReportFilter(),
      );

      expect(report.type, ReportType.sales);
      expect(report.rows, hasLength(1));
      expect(report.rows.first[2], '2'); // cabeças
      expect(report.footer, isNotNull);
      expect(report.footer!.first, 'TOTAL');
      expect(report.footer![2], '2'); // soma de cabeças
    });

    test(r'média ponderada de R$/@ = valor total ÷ arrobas totais', () async {
      final sale2 = sale.copyWith(
        id: 's2',
        totalValue: 3000,
        totalWeightKg: 150, // 10 @
      );
      when(() => sales.getAll()).thenAnswer((_) async => [sale, sale2]);

      final report = await useCase.call(
        ReportType.sales,
        const ReportFilter(),
      );

      // (9000 + 3000) / ((600 + 150) / 15) = 12000 / 50 = R$ 240,00/@.
      expect(report.footer!.last, contains('240'));
    });

    test('ignora vendas fora do período e lida com lista vazia', () async {
      when(() => sales.getAll()).thenAnswer(
        (_) async => [sale.copyWith(date: now.subtract(const Duration(days: 90)))],
      );

      final report = await useCase.call(
        ReportType.sales,
        const ReportFilter(),
      );

      expect(report.rows, isEmpty);
      expect(report.footer, isNull);
    });
  });

  group('GenerateReportUseCase — inventário', () {
    test('inclui os animais ativos do rebanho', () async {
      when(() => animals.getAll())
          .thenAnswer((_) async => [pregnant, healthy]);

      final report = await useCase.call(
        ReportType.inventory,
        const ReportFilter(),
      );

      expect(report.rows, hasLength(2));
      expect(report.headers, contains('Status'));
    });

    test('exclui animais arquivados (vendidos/óbito)', () async {
      final sold = healthy.copyWith(
        id: '3',
        earTag: '099',
        exitType: AnimalExitType.sold,
      );
      when(() => animals.getAll())
          .thenAnswer((_) async => [pregnant, healthy, sold]);

      final report = await useCase.call(
        ReportType.inventory,
        const ReportFilter(),
      );

      // O animal vendido não entra no inventário do rebanho ativo.
      expect(report.rows, hasLength(2));
    });
  });
}
