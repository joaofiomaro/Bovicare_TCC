import 'brete_models.dart';

/// Comunicação com o brete — Bluetooth (BLE), MQTT ou simulação.
abstract interface class BreteGateway {
  BreteTransport get transport;

  /// `true` quando não há dispositivo real (modo demonstração).
  bool get isSimulation;

  BreteStatus get current;
  Stream<BreteStatus> get status;

  /// Avisos espontâneos do dispositivo para mostrar ao usuário (ex.:
  /// obstáculo sob a porta), já com o texto pronto.
  Stream<String> get alerts;

  Future<void> connect();
  Future<void> disconnect();

  /// Reinicia o sistema quando algo travou: para as portas, rearma se estiver
  /// em emergência e refaz a conexão. Funciona também desconectado. Lança
  /// [BreteException] se o rearme for recusado (botão de parada apertado).
  Future<void> restart();

  /// Envia o comando. [door] só vale para abrir/fechar/parar. No modo real o
  /// estado só muda quando o dispositivo confirmar (fonte da verdade é o
  /// ESP32). Lança [BreteException] se o brete recusar.
  Future<void> send(BreteCommand command, {BreteDoor door});

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
