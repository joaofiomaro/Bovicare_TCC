import 'dart:convert';
import 'dart:math';

import 'package:bovicare/features/brete/data/mqtt_brete_gateway.dart';
import 'package:bovicare/features/brete/data/simulated_brete_gateway.dart';
import 'package:bovicare/features/brete/domain/brete_gateway.dart';
import 'package:bovicare/features/brete/domain/brete_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 3, 10, 12);

  group('BreteProtocol', () {
    test('tópicos por dispositivo', () {
      expect(BreteProtocol.commandTopic('b1'), 'bovicare/brete/b1/cmd');
      expect(BreteProtocol.stateTopic('b1'), 'bovicare/brete/b1/state');
      expect(BreteProtocol.rfidTopic('b1'), 'bovicare/brete/b1/rfid');
    });

    test('codifica comando em JSON', () {
      final json = jsonDecode(BreteProtocol.encodeCommand(BreteCommand.emergencyStop, now))
          as Map<String, dynamic>;
      expect(json['cmd'], 'emergency_stop');
      expect(json['ts'], '2026-03-10T12:00:00.000Z');
    });

    test('aplica estado da porteira e sensores', () {
      final s = BreteProtocol.applyState(
        const BreteStatus(),
        '{"door":"open","sensors":{"irTop":true,"pedalOpen":true}}',
        now,
      );
      expect(s.door, DoorState.open);
      expect(s.sensors.irTop, isTrue);
      expect(s.sensors.obstructed, isTrue);
      expect(s.sensors.pedalOpen, isTrue);
      expect(s.lastUpdate, now);
    });

    test('estados de movimento viram moving', () {
      expect(BreteProtocol.parseDoor('opening'), DoorState.moving);
      expect(BreteProtocol.parseDoor('xpto'), DoorState.unknown);
    });

    test('payload inválido é ignorado', () {
      const current = BreteStatus(door: DoorState.closed);
      expect(BreteProtocol.applyState(current, 'lixo{', now).door, DoorState.closed);
      expect(BreteProtocol.applyState(current, '[1,2]', now).door, DoorState.closed);
    });

    test('RFID em JSON ou texto puro; rejeita lixo', () {
      expect(BreteProtocol.parseRfid('{"tag":"900115000123456"}'), '900115000123456');
      expect(BreteProtocol.parseRfid(' 900115000123456 '), '900115000123456');
      expect(BreteProtocol.parseRfid('<script>'), isNull);
      expect(BreteProtocol.parseRfid('12'), isNull);
    });
  });

  group('BreteMqttConfig.fromEnv', () {
    test('sem URL ou com valor de exemplo → simulação (null)', () {
      expect(BreteMqttConfig.fromEnv({}), isNull);
      expect(
        BreteMqttConfig.fromEnv({'MQTT_BROKER_URL': 'ws://SEU_IP_DO_ESP32:9001'}),
        isNull,
      );
      expect(BreteMqttConfig.fromEnv({'MQTT_BROKER_URL': 'http://x:1'}), isNull);
    });

    test('URL WebSocket válida', () {
      final c = BreteMqttConfig.fromEnv({
        'MQTT_BROKER_URL': 'ws://192.168.0.50:9001',
        'BRETE_DEVICE_ID': 'brete-02',
      })!;
      expect(c.useWebSocket, isTrue);
      expect(c.uri.host, '192.168.0.50');
      expect(c.deviceId, 'brete-02');
      expect(c.clientId, startsWith('bovicare_app_'));
    });
  });

  group('SimulatedBreteGateway', () {
    late SimulatedBreteGateway gw;

    setUp(() async {
      gw = SimulatedBreteGateway(random: Random(1), knownTags: () => ['900115000000001']);
      await gw.connect();
    });

    tearDown(() => gw.dispose());

    test('conecta em modo simulação com porteira fechada', () {
      expect(gw.current.connection, BreteConnection.simulated);
      expect(gw.current.door, DoorState.closed);
    });

    test('abrir passa por movimento e termina aberta', () async {
      await gw.send(BreteCommand.open);
      expect(gw.current.door, DoorState.moving);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      expect(gw.current.door, DoorState.open);
    });

    test('emergência bloqueia comandos até o rearme', () async {
      await gw.send(BreteCommand.emergencyStop);
      expect(gw.current.door, DoorState.emergency);
      expect(() => gw.send(BreteCommand.open), throwsA(isA<BreteException>()));
      await gw.send(BreteCommand.reset);
      expect(gw.current.door, DoorState.moving);
    });

    test('leitura RFID devolve tag e atualiza o estado', () async {
      final tag = await gw.readNextRfid();
      expect(tag, isNotNull);
      expect(gw.current.lastRfid, tag);
    });
  });
}
