import 'package:bovicare/features/health/domain/entities/health_event.dart';
import 'package:bovicare/features/health/domain/repositories/health_event_repository.dart';
import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/herd/domain/repositories/animal_repository.dart';
import 'package:bovicare/features/herd/domain/repositories/sale_repository.dart';
import 'package:bovicare/features/reports/domain/entities/report_data.dart';
import 'package:bovicare/features/reports/domain/usecases/generate_report_use_case.dart';
import 'package:bovicare/features/vaccination/domain/repositories/vaccination_repository.dart';
import 'package:bovicare/features/weighing/domain/repositories/weighing_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _Animals extends Mock implements AnimalRepository {}

class _Vaccinations extends Mock implements VaccinationRepository {}

class _Sales extends Mock implements SaleRepository {}

class _Weighings extends Mock implements WeighingRepository {}

class _Health extends Mock implements HealthEventRepository {}

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  test('relatório sanitário inclui vermifugação/medicação, não observações', () async {
    final now = DateTime.now();
    final animals = _Animals();
    final vaccinations = _Vaccinations();
    final health = _Health();

    when(animals.getAll).thenAnswer((_) async => [
          AnimalEntity(
            id: 'a1', earTag: '047', name: 'Mimosa', breed: 'Nelore',
            sex: AnimalSex.female, birthDate: DateTime(2022), status: AnimalStatus.healthy,
          ),
        ]);
    when(vaccinations.getAll).thenAnswer((_) async => []);
    when(health.getAll).thenAnswer((_) async => [
          HealthEvent(
            id: 'h1', animalId: 'a1', type: HealthEventType.deworming,
            date: now, title: 'Ivermectina 1%', dose: '10 mL', withdrawalDays: 35,
          ),
          HealthEvent(
            id: 'h2', animalId: 'a1', type: HealthEventType.observation,
            date: now, title: 'Mancando',
          ),
        ]);

    final report = await GenerateReportUseCase(
      animals, vaccinations, _Sales(), _Weighings(),
      healthEvents: health,
    ).call(ReportType.sanitary, const ReportFilter());

    expect(report.rows, hasLength(1));
    final row = report.rows.single;
    expect(row[0], 'Mimosa — #047');
    expect(row[1], 'Ivermectina 1%');
    expect(row[2], '10 mL');
    expect(row[4], isNot('—'));
    expect(row[6], 'Vermifugação');
  });
}
