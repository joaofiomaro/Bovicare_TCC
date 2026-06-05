import '../entities/service_call.dart';
import '../repositories/service_call_repository.dart';

class OpenServiceCallUseCase {
  const OpenServiceCallUseCase(this._repository);
  final ServiceCallRepository _repository;

  /// Abre um chamado novo. Valida campos obrigatórios e força `status = open`
  /// (defesa em profundidade — a UI já restringe).
  Future<ServiceCall> call(ServiceCall call) {
    if (call.title.trim().isEmpty) {
      throw ArgumentError('O chamado precisa de um título.');
    }
    if (call.description.trim().isEmpty) {
      throw ArgumentError('O chamado precisa de uma descrição.');
    }
    if (call.city.trim().isEmpty) {
      throw ArgumentError('Informe a cidade do atendimento.');
    }
    return _repository.create(
      call.copyWith(status: ServiceStatus.open, vetId: null, vetName: null),
    );
  }
}
