import 'brete_models.dart';

/// Comunicação com o brete — MQTT real ou simulação.
abstract interface class BreteGateway {
  /// `true` quando não há dispositivo real (modo demonstração).
  bool get isSimulation;

  BreteStatus get current;
  Stream<BreteStatus> get status;

  Future<void> connect();
  Future<void> disconnect();

  /// Envia o comando. No modo real o estado só muda quando o dispositivo
  /// confirmar pelo tópico `state` (fonte da verdade é o ESP32).
  Future<void> send(BreteCommand command);

  /// Pede uma leitura e aguarda o próximo RFID (null se esgotar o tempo).
  Future<String?> readNextRfid({Duration timeout});

  Future<void> dispose();
}

/// Erro operacional do brete (desconectado, emergência, obstrução) com
/// mensagem pronta para o usuário.
class BreteException implements Exception {
  const BreteException(this.message);
  final String message;

  @override
  String toString() => message;
}
