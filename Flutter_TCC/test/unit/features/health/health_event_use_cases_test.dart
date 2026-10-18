import 'package:bovicare/features/health/domain/entities/health_event.dart';
import 'package:bovicare/features/health/domain/repositories/health_event_repository.dart';
import 'package:bovicare/features/health/domain/usecases/health_event_use_cases.dart';
import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthEventRepository extends Mock implements HealthEventRepository {}

final _now = DateTime(2026, 3, 10, 9);

HealthEvent _event({
  HealthEventType type = HealthEventType.deworming,
  String title = 'Ivermectina 1%',
  int withdrawal = 35,
  DateTime? date,
}) =>
    HealthEvent(
      id:             'e1',
      animalId:       'a1',
      type:           type,
      date:           date ?? DateTime(2026, 3, 9),
      title:          title,
      withdrawalDays: withdrawal,
    );

AnimalEntity _female({AnimalStatus status = AnimalStatus.healthy}) => AnimalEntity(
      id:        'a1',
      earTag:    '047',
      breed:     'Nelore',
      sex:       AnimalSex.female,
      birthDate: DateTime(2022),
      status:    status,
    );

void main() {
  late MockHealthEventRepository repo;

  setUpAll(() {
    registerFallbackValue(_event());
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repo = MockHealthEventRepository();
    when(() => repo.add(any())).thenAnswer((_) async {});
    when(() => repo.registerPregnancy(
          event:        any(named: 'event'),
          coverageDate: any(named: 'coverageDate'),
        )).thenAnswer((_) async {});
    when(() => repo.registerBirth(event: any(named: 'event')))
        .thenAnswer((_) async {});
  });

  group('HealthEvent', () {
    test('fim da carência = data + dias', () {
      expect(_event().withdrawalEnd, DateTime(2026, 4, 13));
      expect(_event(withdrawal: 0).withdrawalEnd, isNull);
    });

    test('isInWithdrawal respeita o último dia', () {
      final e = _event(withdrawal: 1);
      expect(e.isInWithdrawal(DateTime(2026, 3, 10)), isTrue);
      expect(e.isInWithdrawal(DateTime(2026, 3, 10, 0, 0, 1)), isFalse);
    });
  });

  group('RegisterHealthEventUseCase', () {
    test('registra tratamento válido', () async {
      await RegisterHealthEventUseCase(repo).call(_event(), now: _now);
      verify(() => repo.add(any())).called(1);
    });

    test('exige produto', () {
      expect(
        () => RegisterHealthEventUseCase(repo).call(_event(title: ' '), now: _now),
        throwsArgumentError,
      );
    });

    test('rejeita carência fora de 0–365', () {
      expect(
        () => RegisterHealthEventUseCase(repo).call(_event(withdrawal: 400), now: _now),
        throwsArgumentError,
      );
    });

    test('rejeita data futura', () {
      expect(
        () => RegisterHealthEventUseCase(repo)
            .call(_event(date: DateTime(2026, 3, 11)), now: _now),
        throwsArgumentError,
      );
    });

    test('não aceita evento reprodutivo', () {
      expect(
        () => RegisterHealthEventUseCase(repo)
            .call(_event(type: HealthEventType.birth), now: _now),
        throwsArgumentError,
      );
    });
  });

  group('RegisterPregnancyUseCase', () {
    test('fêmea ativa não prenhe → registra', () async {
      await RegisterPregnancyUseCase(repo).call(
        animal:       _female(),
        event:        _event(type: HealthEventType.pregnancyDiagnosis),
        coverageDate: DateTime(2026, 1, 10),
        now:          _now,
      );
      verify(() => repo.registerPregnancy(
            event:        any(named: 'event'),
            coverageDate: DateTime(2026, 1, 10),
          )).called(1);
    });

    test('macho não pode', () {
      final male = _female().copyWith(sex: AnimalSex.male);
      expect(
        () => RegisterPregnancyUseCase(repo).call(
          animal: male, event: _event(), coverageDate: DateTime(2026, 1, 10), now: _now,
        ),
        throwsArgumentError,
      );
    });

    test('já prenhe não pode', () {
      expect(
        () => RegisterPregnancyUseCase(repo).call(
          animal:       _female(status: AnimalStatus.pregnant),
          event:        _event(),
          coverageDate: DateTime(2026, 1, 10),
          now:          _now,
        ),
        throwsArgumentError,
      );
    });

    test('cobertura há mais de 283 dias não pode', () {
      expect(
        () => RegisterPregnancyUseCase(repo).call(
          animal: _female(), event: _event(), coverageDate: DateTime(2025, 3), now: _now,
        ),
        throwsArgumentError,
      );
    });
  });

  group('RegisterBirthUseCase', () {
    test('exige animal prenhe', () {
      expect(
        () => RegisterBirthUseCase(repo).call(
          mother: _female(), event: _event(type: HealthEventType.birth), now: _now,
        ),
        throwsArgumentError,
      );
    });

    test('bezerro precisa de brinco', () {
      final calf = _female().copyWith(id: 'c', earTag: '');
      expect(
        () => RegisterBirthUseCase(repo).call(
          mother: _female(status: AnimalStatus.pregnant),
          event:  _event(type: HealthEventType.birth),
          calf:   calf,
          now:    _now,
        ),
        throwsArgumentError,
      );
    });

    test('parto válido sem bezerro', () async {
      await RegisterBirthUseCase(repo).call(
        mother: _female(status: AnimalStatus.pregnant),
        event:  _event(type: HealthEventType.birth),
        now:    _now,
      );
      verify(() => repo.registerBirth(event: any(named: 'event'))).called(1);
    });
  });
}
