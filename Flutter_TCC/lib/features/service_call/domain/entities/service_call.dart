import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_call.freezed.dart';

/// Urgência de um chamado.
enum ServiceUrgency { low, normal, high }

/// Ciclo de vida de um chamado, do pool à conclusão.
enum ServiceStatus { open, accepted, inProgress, completed, cancelled }

/// Chamado de atendimento veterinário — coleção **compartilhada**
/// `serviceCalls/{id}` entre produtor (autor) e veterinário (atribuído).
@freezed
class ServiceCall with _$ServiceCall {
  const factory ServiceCall({
    required String id,
    // Produtor (autor):
    required String producerId,
    required String producerName,
    required String city,
    required String state,
    // Conteúdo:
    required String title,
    required String description,
    required ServiceUrgency urgency,
    required ServiceStatus status,
    required DateTime createdAt,
    String? farmName,
    double? lat,
    double? lng,
    String? animalEarTag,
    // Veterinário (atribuído ao aceitar):
    String? vetId,
    String? vetName,
    // Evolução:
    DateTime? scheduledDate,
    DateTime? completedAt,
    String? resolution,
  }) = _ServiceCall;
}

/// Transições de status válidas e consultas de estado — funções puras,
/// base para use cases e UI (testáveis isoladamente).
extension ServiceCallX on ServiceCall {
  bool get isOpen   => status == ServiceStatus.open;
  bool get isActive =>
      status == ServiceStatus.accepted || status == ServiceStatus.inProgress;
  bool get isClosed =>
      status == ServiceStatus.completed || status == ServiceStatus.cancelled;

  /// Pode ser cancelado pelo produtor apenas enquanto aberto.
  bool get canCancel => isOpen;

  /// Pode ser aceito por um vet apenas enquanto aberto (sem vet atribuído).
  bool get canAccept => isOpen;
}

/// Próximo status natural a partir do atual (avanço do atendimento pelo vet).
/// Null quando não há avanço possível (fim do fluxo).
ServiceStatus? nextServiceStatus(ServiceStatus current) => switch (current) {
      ServiceStatus.open        => ServiceStatus.accepted,
      ServiceStatus.accepted    => ServiceStatus.inProgress,
      ServiceStatus.inProgress  => ServiceStatus.completed,
      ServiceStatus.completed   => null,
      ServiceStatus.cancelled   => null,
    };

extension ServiceStatusX on ServiceStatus {
  String get label => switch (this) {
        ServiceStatus.open        => 'Aberto',
        ServiceStatus.accepted    => 'Aceito',
        ServiceStatus.inProgress  => 'Em atendimento',
        ServiceStatus.completed   => 'Concluído',
        ServiceStatus.cancelled   => 'Cancelado',
      };
}

extension ServiceUrgencyX on ServiceUrgency {
  String get label => switch (this) {
        ServiceUrgency.low    => 'Baixa',
        ServiceUrgency.normal => 'Normal',
        ServiceUrgency.high   => 'Urgente',
      };
}
