import '../entities/service_call.dart';
import '../repositories/service_call_repository.dart';

class CancelCallUseCase {
  const CancelCallUseCase(this._repository);
  final ServiceCallRepository _repository;

  /// Produtor cancela o próprio chamado — só permitido enquanto aberto.
  Future<void> call(ServiceCall call) {
    if (!call.canCancel) {
      throw ArgumentError('Só é possível cancelar um chamado em aberto.');
    }
    return _repository.cancel(call.id);
  }
}
