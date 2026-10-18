import 'package:bovicare/features/alerts/domain/farm_alerts.dart';
import 'package:bovicare/features/health/domain/entities/health_event.dart';
import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/settings/domain/entities/user_settings.dart';
import 'package:bovicare/features/vaccination/domain/entities/vaccination_record.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 3, 10, 9);

AnimalEntity _animal(
  String id, {
  AnimalStatus status = AnimalStatus.healthy,
  DateTime? pregnancyDate,
  AnimalExitType exit = AnimalExitType.active,
}) =>
    AnimalEntity(
      id:            id,
      earTag:        id,
      breed:         'Nelore',
      sex:           AnimalSex.female,
      birthDate:     DateTime(2022),
      status:        status,
      pregnancyDate: pregnancyDate,
      exitType:      exit,
    );

VaccinationRecord _vac(
  String animalId,
  DateTime date, {
  DateTime? next,
  int quarantine = 0,
  String name = 'Febre Aftosa',
}) =>
    VaccinationRecord(
      id:             '$animalId-$name-${date.millisecondsSinceEpoch}',
      animalId:       animalId,
      vaccineName:    name,
      dose:           '1ª dose',
      date:           date,
      quarantineDays: quarantine,
      nextDoseDate:   next,
    );

List<FarmAlert> _build({
  List<AnimalEntity> animals = const [],
  List<VaccinationRecord> vaccinations = const [],
  List<HealthEvent> events = const [],
  AlertSettings settings = const AlertSettings(),
}) =>
    buildFarmAlerts(
      animals:      animals,
      vaccinations: vaccinations,
      healthEvents: events,
      settings:     settings,
      now:          _now,
    );

void main() {
  group('vacinas', () {
    test('próxima dose dentro da antecedência gera alerta', () {
      final alerts = _build(
        animals:      [_animal('a')],
        vaccinations: [_vac('a', DateTime(2026, 2, 20), next: DateTime(2026, 3, 20))],
      );
      expect(alerts.single.type, FarmAlertType.vaccineDue);
      expect(alerts.single.subtitle, 'Próxima dose em 10 dia(s)');
    });

    test('dose fora da antecedência não gera alerta', () {
      final alerts = _build(
        animals:      [_animal('a')],
        vaccinations: [_vac('a', DateTime(2026, 2, 20), next: DateTime(2026, 3, 20))],
        settings:     const AlertSettings(leadDays: 7),
      );
      expect(alerts, isEmpty);
    });

    test('dose atrasada é alta prioridade', () {
      final alerts = _build(
        animals:      [_animal('a')],
        vaccinations: [_vac('a', DateTime(2026, 2), next: DateTime(2026, 3, 5))],
      );
      expect(alerts.single.type, FarmAlertType.vaccineOverdue);
      expect(alerts.single.severity, FarmAlertSeverity.high);
    });

    test('dose já reaplicada (registro mais novo) não alerta a antiga', () {
      final alerts = _build(
        animals: [_animal('a')],
        vaccinations: [
          _vac('a', DateTime(2026), next: DateTime(2026, 2)),
          _vac('a', DateTime(2026, 2), next: DateTime(2027, 2)),
        ],
      );
      expect(alerts, isEmpty);
    });

    test('animal vendido/óbito não gera alertas', () {
      final alerts = _build(
        animals:      [_animal('a', exit: AnimalExitType.sold)],
        vaccinations: [_vac('a', DateTime(2026, 2, 20), next: DateTime(2026, 3, 12))],
      );
      expect(alerts, isEmpty);
    });

    test('categoria desativada não gera alertas', () {
      final alerts = _build(
        animals:      [_animal('a')],
        vaccinations: [_vac('a', DateTime(2026, 2, 20), next: DateTime(2026, 3, 12))],
        settings:     const AlertSettings(vaccines: false),
      );
      expect(alerts, isEmpty);
    });
  });

  test('parto previsto dentro da antecedência', () {
    // 283 dias de gestação → previsto para 30/03/2026.
    final cover = DateTime(2026, 3, 30).subtract(const Duration(days: 283));
    final alerts = _build(
      animals: [_animal('a', status: AnimalStatus.pregnant, pregnancyDate: cover)],
    );
    expect(alerts.single.type, FarmAlertType.birthDue);
  });

  test('carência ativa usa o fim mais tardio entre vacina e tratamento', () {
    final alerts = _build(
      animals:      [_animal('a')],
      vaccinations: [_vac('a', DateTime(2026, 3), quarantine: 21)],
      events: [
        HealthEvent(
          id:             'h',
          animalId:       'a',
          type:           HealthEventType.medication,
          date:           DateTime(2026, 3, 5),
          title:          'Oxitetraciclina',
          withdrawalDays: 28,
        ),
      ],
    );
    final withdrawal = alerts.singleWhere((a) => a.type == FarmAlertType.withdrawal);
    expect(withdrawal.subtitle, contains('02/04/2026'));
    expect(withdrawal.subtitle, contains('Oxitetraciclina'));
  });

  test('carência encerrada não gera alerta', () {
    final alerts = _build(
      animals:      [_animal('a')],
      vaccinations: [_vac('a', DateTime(2026), quarantine: 21)],
    );
    expect(alerts, isEmpty);
  });

  test('ordena por severidade e depois por data', () {
    final alerts = _build(
      animals: [_animal('a'), _animal('b')],
      vaccinations: [
        _vac('a', DateTime(2026, 2, 20), next: DateTime(2026, 3, 20)),
        _vac('b', DateTime(2026, 2), next: DateTime(2026, 3)),
      ],
    );
    expect(alerts.first.type, FarmAlertType.vaccineOverdue);
  });
}
