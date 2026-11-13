import '../entities/service_call.dart';
import '../repositories/service_call_repository.dart';
import '../resolution_privacy.dart';

class AdvanceCallUseCase {
  const AdvanceCallUseCase(this._repository);
  final ServiceCallRepository _repository;

  /// Evolui um chamado atribuído (accepted → inProgress → completed),
  /// opcionalmente agendando ou registrando o laudo de conclusão.
  /// Exige laudo ao concluir, sem dados pessoais (ver [ResolutionPrivacy]).
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
    if (resolution != null) {
      final privacy = ResolutionPrivacy.message(resolution, call);
      if (privacy != null) throw ArgumentError(privacy);
    }
    return _repository.updateStatus(
      callId: call.id,
      status: to,
      scheduledDate: scheduledDate,
      resolution: resolution,
    );
  }
}
