import 'package:bovicare/features/service_call/domain/entities/service_call.dart';
import 'package:bovicare/features/service_call/domain/repositories/service_call_repository.dart';
import 'package:bovicare/features/service_call/domain/usecases/accept_call_use_case.dart';
import 'package:bovicare/features/service_call/domain/usecases/advance_call_use_case.dart';
import 'package:bovicare/features/service_call/domain/usecases/cancel_call_use_case.dart';
import 'package:bovicare/features/service_call/domain/usecases/open_service_call_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockServiceCallRepository extends Mock
    implements ServiceCallRepository {}

ServiceCall _call({ServiceStatus status = ServiceStatus.open, String? vetId}) =>
    ServiceCall(
      id: 'c1',
      producerId: 'p1',
      producerName: 'João',
      city: 'Bagé',
      state: 'RS',
      title: 'Vaca mancando',
      description: 'Pata dianteira inchada',
      urgency: ServiceUrgency.high,
      status: status,
      createdAt: DateTime(2026, 6),
      vetId: vetId,
    );

void main() {
  late MockServiceCallRepository repo;

  setUpAll(() {
    registerFallbackValue(_call());
    registerFallbackValue(ServiceStatus.open);
  });

  setUp(() {
    repo = MockServiceCallRepository();
    when(() => repo.create(any())).thenAnswer((i) async =>
        i.positionalArguments.first as ServiceCall);
    when(() => repo.accept(
          callId: any(named: 'callId'),
          vetId: any(named: 'vetId'),
          vetName: any(named: 'vetName'),
        )).thenAnswer((_) async {});
    when(() => repo.updateStatus(
          callId: any(named: 'callId'),
          status: any(named: 'status'),
          scheduledDate: any(named: 'scheduledDate'),
          resolution: any(named: 'resolution'),
        )).thenAnswer((_) async {});
    when(() => repo.cancel(any())).thenAnswer((_) async {});
  });

  group('nextServiceStatus (função pura)', () {
    test('avança no fluxo open → accepted → inProgress → completed', () {
      expect(nextServiceStatus(ServiceStatus.open), ServiceStatus.accepted);
      expect(
          nextServiceStatus(ServiceStatus.accepted), ServiceStatus.inProgress);
      expect(nextServiceStatus(ServiceStatus.inProgress),
          ServiceStatus.completed);
    });

    test('não há avanço a partir de estados finais', () {
      expect(nextServiceStatus(ServiceStatus.completed), isNull);
      expect(nextServiceStatus(ServiceStatus.cancelled), isNull);
    });
  });

  group('ServiceCallX (consultas puras de estado)', () {
    test('canAccept/canCancel apenas quando aberto', () {
      expect(_call().canAccept, isTrue);
      expect(_call().canCancel, isTrue);
      final accepted = _call(status: ServiceStatus.accepted, vetId: 'v1');
      expect(accepted.canAccept, isFalse);
      expect(accepted.canCancel, isFalse);
      expect(accepted.isActive, isTrue);
    });
  });

  group('OpenServiceCallUseCase', () {
    test('força status open e persiste', () async {
      final result = await OpenServiceCallUseCase(repo).call(
        _call(status: ServiceStatus.accepted, vetId: 'x'),
      );
      expect(result.status, ServiceStatus.open);
      expect(result.vetId, isNull);
      verify(() => repo.create(any())).called(1);
    });

    test('rejeita título vazio', () {
      expect(
        () => OpenServiceCallUseCase(repo).call(_call().copyWith(title: '  ')),
        throwsArgumentError,
      );
    });
  });

  group('AcceptCallUseCase', () {
    test('aceita um chamado aberto', () async {
      await AcceptCallUseCase(repo).call(_call(), vetId: 'v1', vetName: 'Dra. Ana');
      verify(() => repo.accept(callId: 'c1', vetId: 'v1', vetName: 'Dra. Ana'))
          .called(1);
    });

    test('rejeita aceitar um chamado já aceito (não-open)', () {
      expect(
        () => AcceptCallUseCase(repo).call(
          _call(status: ServiceStatus.accepted, vetId: 'outro'),
          vetId: 'v1',
          vetName: 'Dra. Ana',
        ),
        throwsArgumentError,
      );
      verifyNever(() => repo.accept(
            callId: any(named: 'callId'),
            vetId: any(named: 'vetId'),
            vetName: any(named: 'vetName'),
          ));
    });
  });

  group('AdvanceCallUseCase', () {
    test('exige laudo para concluir', () {
      expect(
        () => AdvanceCallUseCase(repo).call(
          _call(status: ServiceStatus.inProgress, vetId: 'v1'),
          to: ServiceStatus.completed,
        ),
        throwsArgumentError,
      );
    });

    test('conclui com laudo', () async {
      await AdvanceCallUseCase(repo).call(
        _call(status: ServiceStatus.inProgress, vetId: 'v1'),
        to: ServiceStatus.completed,
        resolution: 'Tratamento aplicado',
      );
      verify(() => repo.updateStatus(
            callId: 'c1',
            status: ServiceStatus.completed,
            resolution: 'Tratamento aplicado',
          )).called(1);
    });

    test('rejeita evoluir chamado não-ativo', () {
      expect(
        () => AdvanceCallUseCase(repo).call(
          _call(),
          to: ServiceStatus.inProgress,
        ),
        throwsArgumentError,
      );
    });
  });

  group('CancelCallUseCase', () {
    test('cancela chamado aberto', () async {
      await CancelCallUseCase(repo).call(_call());
      verify(() => repo.cancel('c1')).called(1);
    });

    test('rejeita cancelar chamado já aceito', () {
      expect(
        () => CancelCallUseCase(repo)
            .call(_call(status: ServiceStatus.accepted, vetId: 'v1')),
        throwsArgumentError,
      );
    });
  });
}
