import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../herd/domain/entities/animal_entity.dart';
import '../../../herd/presentation/providers/animals_provider.dart';
import '../../data/ble_brete_gateway.dart';
import '../../data/brete_transport.dart';
import '../../data/mqtt_brete_gateway.dart';
import '../../data/simulated_brete_gateway.dart';
import '../../domain/brete_gateway.dart';
import '../../domain/brete_models.dart';

/// Gateway do brete conforme `BRETE_CONEXAO` no `.env`: Bluetooth (padrão,
/// Android/iOS), MQTT ou simulação — esta também é usada na web/desktop, onde
/// o BLE do celular não está disponível, para demonstrar o fluxo sem hardware.
final breteGatewayProvider = Provider<BreteGateway>((ref) {
  final env = dotenv.isInitialized ? dotenv.env : const <String, String>{};
  final mobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  final transport = resolveBreteTransport(
    env,
    bleSupported:  mobile,
    mqttSupported: !kIsWeb,
  );

  final gateway = switch (transport) {
    BreteTransport.ble  => BleBreteGateway(),
    BreteTransport.mqtt => MqttBreteGateway(BreteMqttConfig.fromEnv(env)!),
    BreteTransport.simulation => SimulatedBreteGateway(
        // Lido na hora da leitura: o rebanho pode carregar depois.
        knownTags: () =>
            ref.read(animalsProvider).valueOrNull
                ?.where((a) => a.rfid != null && !a.isArchived)
                .map((a) => a.rfid!)
                .toList() ??
            const <String>[],
      ),
  };
  ref.onDispose(gateway.dispose);
  return gateway;
});

/// Estado do brete em tempo real (inicia já com o estado atual).
final breteStatusProvider = StreamProvider<BreteStatus>((ref) async* {
  final gateway = ref.watch(breteGatewayProvider);
  yield gateway.current;
  yield* gateway.status;
});
