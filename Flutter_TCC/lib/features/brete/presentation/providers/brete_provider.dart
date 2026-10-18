import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../herd/domain/entities/animal_entity.dart';
import '../../../herd/presentation/providers/animals_provider.dart';
import '../../data/mqtt_brete_gateway.dart';
import '../../data/simulated_brete_gateway.dart';
import '../../domain/brete_gateway.dart';
import '../../domain/brete_models.dart';

/// Gateway do brete: MQTT real quando `MQTT_BROKER_URL` está configurado no
/// `.env`; caso contrário (ou na web, onde o cliente TCP/WS nativo não roda),
/// simulação para demonstrar o fluxo sem o hardware.
final breteGatewayProvider = Provider<BreteGateway>((ref) {
  final env = dotenv.isInitialized ? dotenv.env : const <String, String>{};
  final config = kIsWeb ? null : BreteMqttConfig.fromEnv(env);

  final gateway = config == null
      ? SimulatedBreteGateway(
          // Lido na hora da leitura: o rebanho pode carregar depois.
          knownTags: () =>
              ref.read(animalsProvider).valueOrNull
                  ?.where((a) => a.rfid != null && !a.isArchived)
                  .map((a) => a.rfid!)
                  .toList() ??
              const <String>[],
        ) as BreteGateway
      : MqttBreteGateway(config);
  ref.onDispose(gateway.dispose);
  return gateway;
});

/// Estado do brete em tempo real (inicia já com o estado atual).
final breteStatusProvider = StreamProvider<BreteStatus>((ref) async* {
  final gateway = ref.watch(breteGatewayProvider);
  yield gateway.current;
  yield* gateway.status;
});
