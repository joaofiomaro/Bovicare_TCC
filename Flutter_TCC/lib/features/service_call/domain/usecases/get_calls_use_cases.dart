import '../entities/service_call.dart';
import '../repositories/service_call_repository.dart';

/// Pool de chamados abertos (visão do veterinário).
class GetOpenCallsUseCase {
  const GetOpenCallsUseCase(this._repository);
  final ServiceCallRepository _repository;

  Future<List<ServiceCall>> call() => _repository.getOpen();
}

/// Chamados atribuídos a um veterinário.
class GetVetCallsUseCase {
  const GetVetCallsUseCase(this._repository);
  final ServiceCallRepository _repository;

  Future<List<ServiceCall>> call(String vetId) =>
      _repository.getForVet(vetId);
}

/// Chamados abertos por um produtor.
class GetProducerCallsUseCase {
  const GetProducerCallsUseCase(this._repository);
  final ServiceCallRepository _repository;

  Future<List<ServiceCall>> call(String producerId) =>
      _repository.getForProducer(producerId);
}
