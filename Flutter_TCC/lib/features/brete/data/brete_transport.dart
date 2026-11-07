import '../domain/brete_models.dart';
import 'mqtt_brete_gateway.dart';

/// Escolhe o meio de comunicação a partir do `.env` (`BRETE_CONEXAO`):
/// `ble` (padrão), `mqtt` ou `simulacao`. Cai na simulação quando o meio
/// escolhido não está disponível — BLE fora do Android/iOS ou MQTT sem
/// broker configurado.
BreteTransport resolveBreteTransport(
  Map<String, String> env, {
  required bool bleSupported,
  required bool mqttSupported,
}) {
  final mode = env['BRETE_CONEXAO']?.trim().toLowerCase() ?? '';
  return switch (mode) {
    'simulacao' || 'simulação' => BreteTransport.simulation,
    'mqtt' => mqttSupported && BreteMqttConfig.fromEnv(env) != null
        ? BreteTransport.mqtt
        : BreteTransport.simulation,
    _ => bleSupported ? BreteTransport.ble : BreteTransport.simulation,
  };
}
