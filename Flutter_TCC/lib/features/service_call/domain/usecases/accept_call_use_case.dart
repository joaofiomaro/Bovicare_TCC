import '../entities/service_call.dart';
import '../repositories/service_call_repository.dart';

class AcceptCallUseCase {
  const AcceptCallUseCase(this._repository);
  final ServiceCallRepository _repository;

  /// Vet assume um chamado do pool. Rejeita se o chamado não estiver aberto
  /// (já aceito por outro vet) — a checagem final atômica é no data source.
  Future<void> call(
    ServiceCall call, {
    required String vetId,
    required String vetName,
  }) {
    if (!call.canAccept) {
      throw ArgumentError('Este chamado já foi aceito por outro veterinário.');
    }
    return _repository.accept(
      callId: call.id,
      vetId: vetId,
      vetName: vetName,
    );
  }
}
