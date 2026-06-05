import '../entities/service_call.dart';

abstract interface class ServiceCallRepository {
  /// Cria um novo chamado (sempre em aberto). Retorna o chamado persistido.
  Future<ServiceCall> create(ServiceCall call);

  /// Pool de chamados abertos (sem vet atribuído), mais recentes primeiro.
  Future<List<ServiceCall>> getOpen();

  /// Chamados atribuídos a um veterinário.
  Future<List<ServiceCall>> getForVet(String vetId);

  /// Chamados abertos por um produtor.
  Future<List<ServiceCall>> getForProducer(String producerId);

  /// Vet assume um chamado do pool (open → accepted), de forma atômica:
  /// só aplica se ainda estiver aberto (evita corrida entre dois vets).
  Future<void> accept({
    required String callId,
    required String vetId,
    required String vetName,
  });

  /// Evolui o status do chamado (inProgress / completed) pelo vet atribuído,
  /// opcionalmente com agendamento e laudo final.
  Future<void> updateStatus({
    required String callId,
    required ServiceStatus status,
    DateTime? scheduledDate,
    String? resolution,
  });

  /// Produtor cancela o próprio chamado (apenas enquanto aberto).
  Future<void> cancel(String callId);
}
