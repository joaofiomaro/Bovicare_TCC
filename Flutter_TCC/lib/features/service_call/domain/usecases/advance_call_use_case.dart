import '../entities/service_call.dart';
import '../repositories/service_call_repository.dart';

class AdvanceCallUseCase {
  const AdvanceCallUseCase(this._repository);
  final ServiceCallRepository _repository;

  /// Evolui um chamado atribuído (accepted → inProgress → completed),
  /// opcionalmente agendando ou registrando o laudo de conclusão.
  /// Exige laudo ao concluir.
  Future<void> call(
    ServiceCall call, {
    required ServiceStatus to,
    DateTime? scheduledDate,
    String? resolution,
  }) {
    if (!call.isActive) {
      throw ArgumentError('Apenas chamados em atendimento podem evoluir.');
    }
    if (to == ServiceStatus.completed &&
        (resolution == null || resolution.trim().isEmpty)) {
      throw ArgumentError('Informe o laudo/observação para concluir.');
    }
    return _repository.updateStatus(
      callId: call.id,
      status: to,
      scheduledDate: scheduledDate,
      resolution: resolution,
    );
  }
}
