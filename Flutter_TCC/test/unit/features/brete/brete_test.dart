import 'dart:convert';
import 'dart:math';

import 'package:bovicare/features/brete/data/brete_transport.dart';
import 'package:bovicare/features/brete/data/mqtt_brete_gateway.dart';
import 'package:bovicare/features/brete/data/simulated_brete_gateway.dart';
import 'package:bovicare/features/brete/domain/brete_ble_protocol.dart';
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
      expect(s.sensors.irEntry, isTrue);
      expect(s.sensors.obstructed, isTrue);
      expect(s.sensors.button1, isTrue);
      expect(s.lastUpdate, now);
      expect(s.hasExitDoor, isFalse);
    });

    test('estados de movimento viram moving; emergency liga a emergência', () {
      expect(BreteProtocol.parseDoor('opening'), DoorState.moving);
      expect(BreteProtocol.parseDoor('xpto'), DoorState.unknown);
      final s = BreteProtocol.applyState(const BreteStatus(), '{"door":"emergency"}', now);
      expect(s.emergency, isTrue);
      expect(s.door, DoorState.stopped);
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
        'MQTT_BROKER_URL': 'ws://192.0.2.10:9001',
        'BRETE_DEVICE_ID': 'brete-02',
      })!;
      expect(c.useWebSocket, isTrue);
      expect(c.uri.host, '192.0.2.10');
      expect(c.deviceId, 'brete-02');
      expect(c.clientId, startsWith('bovicare_app_'));
    });
  });

  group('BreteBleProtocol', () {
    test('codifica comandos no texto do firmware com #id', () {
      expect(BreteBleProtocol.encodeCommand(BreteCommand.open, BreteDoor.entry, 5), '#5 ABRIR 1');
      expect(BreteBleProtocol.encodeCommand(BreteCommand.close, BreteDoor.exit, 6), '#6 FECHAR 2');
      expect(BreteBleProtocol.encodeCommand(BreteCommand.stop, BreteDoor.exit, 7), '#7 PARAR 2');
      expect(BreteBleProtocol.encodeCommand(BreteCommand.emergencyStop, BreteDoor.exit, 8), '#8 EMERGENCIA');
      expect(BreteBleProtocol.encodeCommand(BreteCommand.reset, BreteDoor.entry, 9), '#9 RESET');
    });

    test('estados do firmware viram DoorState', () {
      expect(BreteBleProtocol.parseDoor('FECHADA'), DoorState.closed);
      expect(BreteBleProtocol.parseDoor('ABERTA'), DoorState.open);
      for (final e in ['ABRINDO', 'FECHANDO', 'RECUANDO', 'AJUSTE']) {
        expect(BreteBleProtocol.parseDoor(e), DoorState.moving);
      }
      expect(BreteBleProtocol.parseDoor('PARADA'), DoorState.stopped);
      expect(BreteBleProtocol.parseDoor('?'), DoorState.unknown);
    });

    // Mesmo formato de montarEstado() no firmware.
    const state =
        '{"p1":"ABERTA","p2":"FECHADA","f1":"","f2":"","ir":"01","fa":"00",'
        '"ff":"00","em":1,"bot":"101","rfid":"","rok":0,"up":42}';

    test('aplica o estado das duas portas, sensores e emergência', () {
      final s = BreteBleProtocol.applyState(const BreteStatus(), state, now);
      expect(s.door, DoorState.open);
      expect(s.exitDoor, DoorState.closed);
      expect(s.emergency, isTrue);
      expect(s.sensors.irEntry, isFalse);
      expect(s.sensors.irExit, isTrue);
      expect(s.sensors.button1, isTrue);
      expect(s.sensors.button2, isFalse);
      expect(s.sensors.stopButton, isTrue);
      expect(s.rfidAvailable, isFalse);
      expect(s.lastRfid, isNull);
      expect(s.lastUpdate, now);
    });

    test('tag no estado só conta quando muda', () {
      final withTag = state.replaceFirst('"rfid":""', '"rfid":"A1B2C3D4"');
      final s1 = BreteBleProtocol.applyState(const BreteStatus(), withTag, now);
      expect(s1.lastRfid, 'A1B2C3D4');
      expect(s1.lastRfidAt, now);
      final s2 = BreteBleProtocol.applyState(s1, withTag, now.add(const Duration(seconds: 2)));
      expect(s2.lastRfidAt, now);
    });

    test('payload inválido é ignorado', () {
      const current = BreteStatus(door: DoorState.closed);
      expect(BreteBleProtocol.applyState(current, 'lixo{', now), same(current));
      expect(BreteBleProtocol.applyState(current, '{"ev":"PING"}', now), same(current));
    });

    test('interpreta eventos RESP, INICIO e RFID', () {
      final resp = BreteBleProtocol.parseEvent(
        '{"ev":"RESP","cmd":"ABRIR","p":1,"id":5,"res":"INTERTRAVAMENTO","orig":"APP"}',
      )!;
      expect(resp.type, 'RESP');
      expect(resp.id, 5);
      expect(resp.result, 'INTERTRAVAMENTO');
      expect(BreteBleProtocol.parseEvent('{"ev":"INICIO","ver":"1.1.1"}')!.version, '1.1.1');
      expect(BreteBleProtocol.parseEvent('{"ev":"RFID","tag":"A1B2C3D4"}')!.tag, 'A1B2C3D4');
      expect(BreteBleProtocol.parseEvent('nada'), isNull);
      // Campo com tipo inesperado não derruba o parser.
      expect(BreteBleProtocol.parseEvent('{"ev":"RESP","id":"x","res":3}')!.id, 0);
    });

    test('OBSTACULO e emergência pelo botão viram alerta', () {
      final obst = BreteBleProtocol.parseEvent('{"ev":"OBSTACULO","p":2}')!;
      expect(BreteBleProtocol.alertFor(obst), contains('saída'));
      final botao = BreteBleProtocol.parseEvent('{"ev":"EMERGENCIA","on":1,"orig":"BOTAO"}')!;
      expect(BreteBleProtocol.alertFor(botao), isNotNull);
      final app = BreteBleProtocol.parseEvent('{"ev":"EMERGENCIA","on":1,"orig":"APP"}')!;
      expect(BreteBleProtocol.alertFor(app), isNull);
      final porta = BreteBleProtocol.parseEvent('{"ev":"PORTA","p":1,"e":"ABRINDO"}')!;
      expect(BreteBleProtocol.alertFor(porta), isNull);
    });

    test('firmware 1.3: porta em FALHA, código da falha e tag no campo uid', () {
      final falha = state.replaceFirst('"p2":"FECHADA"', '"p2":"FALHA"').replaceFirst('"f2":""', '"f2":"TIMEOUT_ABRIR"');
      final s = BreteBleProtocol.applyState(const BreteStatus(), falha, now);
      expect(s.exitDoor, DoorState.fault);
      expect(s.faultOf(BreteDoor.exit), 'TIMEOUT_ABRIR');
      expect(s.faultOf(BreteDoor.entry), isNull);
      expect(s.hasFault, isTrue);
      expect(BreteBleProtocol.parseEvent('{"ev":"RFID","uid":"04A1B2C3"}')!.tag, '04A1B2C3');
      final ev = BreteBleProtocol.parseEvent('{"ev":"FALHA","p":2,"f":"FIM_PRESO"}')!;
      expect(BreteBleProtocol.alertFor(ev), contains('não soltou'));
      expect(BreteBleProtocol.errorFor('FALHA', BreteCommand.open), contains('Reiniciar'));
    });

    test('resultados do firmware viram mensagens', () {
      expect(BreteBleProtocol.errorFor('OK', BreteCommand.open), isNull);
      expect(BreteBleProtocol.errorFor('JA_ABERTA', BreteCommand.open), contains('já está aberta'));
      expect(BreteBleProtocol.errorFor('NAO_PERMITIDO', BreteCommand.open), 'Comando não permitido agora.');
      expect(BreteBleProtocol.errorFor('PORTA_INVALIDA', BreteCommand.open), contains('Erro interno'));
      expect(BreteBleProtocol.errorFor('INTERTRAVAMENTO', BreteCommand.open), contains('outra porta'));
      expect(BreteBleProtocol.errorFor('OBSTACULO', BreteCommand.close), contains('embaixo da porta'));
      expect(BreteBleProtocol.errorFor('EMERGENCIA', BreteCommand.reset), contains('Solte'));
      expect(BreteBleProtocol.errorFor('INVALIDO', BreteCommand.readRfid), contains('RFID'));
    });
  });

  group('resolveBreteTransport', () {
    BreteTransport resolve(Map<String, String> env, {bool ble = true}) =>
        resolveBreteTransport(env, bleSupported: ble, mqttSupported: true);

    test('padrão é Bluetooth; sem BLE cai na simulação', () {
      expect(resolve({}), BreteTransport.ble);
      expect(resolve({'BRETE_CONEXAO': 'BLE'}), BreteTransport.ble);
      expect(resolve({}, ble: false), BreteTransport.simulation);
    });

    test('simulação explícita', () {
      expect(resolve({'BRETE_CONEXAO': 'simulacao'}), BreteTransport.simulation);
    });

    test('MQTT exige broker válido', () {
      expect(resolve({'BRETE_CONEXAO': 'mqtt'}), BreteTransport.simulation);
      expect(
        resolve({
          'BRETE_CONEXAO': 'mqtt',
          'MQTT_BROKER_URL': 'ws://192.0.2.10:9001',
        }),
        BreteTransport.mqtt,
      );
    });
  });

  group('SimulatedBreteGateway', () {
    late SimulatedBreteGateway gw;

    setUp(() async {
      gw = SimulatedBreteGateway(random: Random(1), knownTags: () => ['900115000000001']);
      await gw.connect();
    });

    tearDown(() => gw.dispose());

    test('conecta em modo simulação com as duas portas fechadas', () {
      expect(gw.current.connection, BreteConnection.simulated);
      expect(gw.current.door, DoorState.closed);
      expect(gw.current.exitDoor, DoorState.closed);
    });

    test('abrir passa por movimento e termina aberta', () async {
      await gw.send(BreteCommand.open);
      expect(gw.current.door, DoorState.moving);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      expect(gw.current.door, DoorState.open);
    });

    test('intertravamento: uma porta só abre com a outra fechada', () async {
      await gw.send(BreteCommand.open);
      expect(
        () => gw.send(BreteCommand.open, door: BreteDoor.exit),
        throwsA(isA<BreteException>()),
      );
    });

    test('parar deixa a porta parada no meio', () async {
      await gw.send(BreteCommand.open, door: BreteDoor.exit);
      await gw.send(BreteCommand.stop, door: BreteDoor.exit);
      expect(gw.current.exitDoor, DoorState.stopped);
    });

    test('reiniciar para as portas, sai da emergência e reconecta', () async {
      await gw.send(BreteCommand.open);
      await gw.send(BreteCommand.emergencyStop);
      await gw.disconnect();
      await gw.restart();
      expect(gw.current.isOnline, isTrue);
      expect(gw.current.emergency, isFalse);
      expect(gw.current.door, DoorState.stopped);
    });

    test('emergência para as portas e bloqueia comandos até o rearme', () async {
      await gw.send(BreteCommand.open);
      await gw.send(BreteCommand.emergencyStop);
      expect(gw.current.emergency, isTrue);
      expect(gw.current.door, DoorState.stopped);
      expect(() => gw.send(BreteCommand.close), throwsA(isA<BreteException>()));
      await gw.send(BreteCommand.reset);
      expect(gw.current.emergency, isFalse);
      await gw.send(BreteCommand.close);
      expect(gw.current.door, DoorState.moving);
    });

    test('leitura RFID devolve tag e atualiza o estado', () async {
      final tag = await gw.readNextRfid();
      expect(tag, isNotNull);
      expect(gw.current.lastRfid, tag);
    });
  });
}
