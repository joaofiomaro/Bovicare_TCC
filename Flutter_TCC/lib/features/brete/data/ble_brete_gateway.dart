import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/brete_ble_protocol.dart';
import '../domain/brete_gateway.dart';
import '../domain/brete_models.dart';

/// Brete real via Bluetooth Low Energy (firmware 1.5.1 `BoviCare_Brete_Final.ino`).
/// O estado exibido vem SEMPRE do ESP32 (characteristic de estado, com
/// notificação); comandos apenas pedem a ação e aguardam a resposta `RESP`.
class BleBreteGateway implements BreteGateway {
  BleBreteGateway({
    this.scanTimeout = const Duration(seconds: 8),
    this.responseTimeout = const Duration(seconds: 3),
  });

  final Duration scanTimeout;
  final Duration responseTimeout;

  final _controller = StreamController<BreteStatus>.broadcast();
  final _rfidReads  = StreamController<String>.broadcast();
  final _events     = StreamController<BreteBleEvent>.broadcast();
  final _alerts     = StreamController<String>.broadcast();
  final _subs       = <StreamSubscription<Object?>>[];
  BreteStatus _current = const BreteStatus();
  BluetoothDevice? _device;
  BluetoothCharacteristic? _command;
  bool _closing = false;
  int _nextId = 1;

  /// Tag parada no leitor agora (o firmware 1.3 lê sozinho e avisa quando
  /// ela chega e quando sai).
  String? _presentTag;

  @override
  BreteTransport get transport => BreteTransport.ble;

  @override
  bool get isSimulation => false;

  @override
  BreteStatus get current => _current;

  @override
  Stream<BreteStatus> get status => _controller.stream;

  @override
  Stream<String> get alerts => _alerts.stream;

  void _emit(BreteStatus s) {
    _current = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  void _fail(String message) => _emit(_current.copyWith(
        connection:   BreteConnection.error,
        errorMessage: message,
      ));

  @override
  Future<void> connect() async {
    if (_current.connection == BreteConnection.connecting ||
        _current.connection == BreteConnection.connected) {
      return;
    }
    _emit(_current.copyWith(
      connection: BreteConnection.connecting,
      clearError: true,
    ));

    try {
      if (!await FlutterBluePlus.isSupported) {
        _fail('Este aparelho não tem Bluetooth LE.');
        return;
      }
      if (!await _ensureAdapterOn()) {
        _fail('Ative o Bluetooth do celular para conectar ao brete.');
        return;
      }

      final device = await _scan();
      if (device == null) {
        _fail('Brete não encontrado. Confira se ele está ligado e perto do '
            'celular.');
        return;
      }

      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 10),
        mtu:     null,
      );
      _device = device;
      // Sem MTU maior o Android corta as notificações em 20 bytes e o JSON
      // chega quebrado. No iOS é negociado sozinho.
      if (defaultTargetPlatform == TargetPlatform.android) {
        await device.requestMtu(BreteBleProtocol.mtu);
      }

      final services = await device.discoverServices();
      final service  = services.where(
        (s) => s.uuid == Guid(BreteBleProtocol.serviceUuid),
      ).firstOrNull;
      BluetoothCharacteristic? find(String uuid) => service?.characteristics
          .where((c) => c.uuid == Guid(uuid))
          .firstOrNull;
      final command = find(BreteBleProtocol.commandUuid);
      final state   = find(BreteBleProtocol.stateUuid);
      final event   = find(BreteBleProtocol.eventUuid);
      if (command == null || state == null || event == null) {
        throw const BreteException('O dispositivo encontrado não é um brete '
            'BoviCare (serviço BLE ausente).');
      }

      _subs
        ..add(event.onValueReceived.listen(_onEvent))
        ..add(state.onValueReceived.listen(_onState));
      await event.setNotifyValue(true);
      await state.setNotifyValue(true);
      _command = command;

      _onState(await state.read());
      // Confirma que o firmware está respondendo antes de liberar os botões.
      await _request(BreteBleProtocol.statusCommand);
      _subs.add(device.connectionState.listen(_onConnectionState));

      _emit(_current.copyWith(
        connection: BreteConnection.connected,
        clearError: true,
      ));
    } on BreteException catch (e) {
      await _release();
      _fail(e.message);
    } on Exception catch (e) {
      await _release();
      _fail('Não foi possível conectar ao brete ($e).');
    }
  }

  Future<bool> _ensureAdapterOn() async {
    var adapter = await FlutterBluePlus.adapterState
        .where((s) => s != BluetoothAdapterState.unknown)
        .first
        .timeout(const Duration(seconds: 3), onTimeout: () => BluetoothAdapterState.unknown);
    if (adapter == BluetoothAdapterState.on) return true;
    // Android permite pedir para ligar; no iOS o usuário liga manualmente.
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      await FlutterBluePlus.turnOn();
      adapter = await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 10));
      return true;
    } on Exception {
      return false;
    }
  }

  /// Procura o brete pelo UUID do serviço anunciado; devolve o de sinal mais
  /// forte entre os encontrados.
  Future<BluetoothDevice?> _scan() async {
    ScanResult? best;
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        if (best == null || r.rssi > best!.rssi) best = r;
      }
      if (best != null) unawaited(FlutterBluePlus.stopScan());
    });
    FlutterBluePlus.cancelWhenScanComplete(sub);
    await FlutterBluePlus.startScan(
      withServices: [Guid(BreteBleProtocol.serviceUuid)],
      timeout:      scanTimeout,
    );
    await FlutterBluePlus.isScanning.where((s) => !s).first;
    return best?.device;
  }

  void _onConnectionState(BluetoothConnectionState s) {
    if (s != BluetoothConnectionState.disconnected || _closing) return;
    unawaited(_release());
    _emit(_current.copyWith(
      connection:   BreteConnection.disconnected,
      door:         DoorState.unknown,
      exitDoor:     DoorState.unknown,
      errorMessage: 'Conexão com o brete perdida. Toque em Reconectar.',
    ));
  }

  void _onState(List<int> bytes) {
    final before = _current.lastRfid;
    final payload = utf8.decode(bytes, allowMalformed: true);
    final next = BreteBleProtocol.applyState(_current, payload, DateTime.now());
    if (identical(next, _current)) {
      debugPrint('Brete BLE: estado inválido ignorado: $payload');
      return;
    }
    _emit(next);
    if (next.lastRfid != null && next.lastRfid != before) {
      _presentTag = next.lastRfid;
      _rfidReads.add(next.lastRfid!);
    }
  }

  void _onEvent(List<int> bytes) {
    final payload = utf8.decode(bytes, allowMalformed: true);
    final ev = BreteBleProtocol.parseEvent(payload);
    if (ev == null) {
      debugPrint('Brete BLE: evento inválido ignorado: $payload');
      return;
    }
    switch (ev.type) {
      case 'INICIO' when ev.version != null:
        _emit(_current.copyWith(firmwareVersion: ev.version));
      case 'RFID' when ev.tag != null:
        final now = DateTime.now();
        _presentTag = ev.tag;
        _emit(_current.copyWith(lastRfid: ev.tag, lastRfidAt: now, lastUpdate: now));
        _rfidReads.add(ev.tag!);
      case 'RFID_SAIU':
        _presentTag = null;
    }
    final alert = BreteBleProtocol.alertFor(ev);
    if (alert != null && !_alerts.isClosed) _alerts.add(alert);
    if (!_events.isClosed) _events.add(ev);
  }

  @override
  Future<void> send(BreteCommand command, {BreteDoor door = BreteDoor.entry}) async {
    if (_current.connection != BreteConnection.connected) {
      throw const BreteException('Brete desconectado.');
    }
    final resp = await _request(
      (id) => BreteBleProtocol.encodeCommand(command, door, id),
    );
    final result = resp.result ?? '';
    if (result == 'PORTA_INVALIDA' || result == 'INVALIDO') {
      debugPrint('Brete BLE: comando $command rejeitado como $result');
    }
    final error = BreteBleProtocol.errorFor(result, command);
    if (error != null) throw BreteException(error);
  }

  /// Escreve o comando com um `#id` novo e aguarda o `RESP` com o mesmo id.
  Future<BreteBleEvent> _request(String Function(int id) build) async {
    final characteristic = _command;
    if (characteristic == null) {
      throw const BreteException('Brete desconectado.');
    }
    final id = _nextId;
    _nextId = _nextId >= 65535 ? 1 : _nextId + 1;

    // Assina antes de escrever para não perder uma resposta rápida.
    final response = _events.stream
        .firstWhere((e) => e.type == 'RESP' && e.id == id)
        .timeout(responseTimeout);
    try {
      await characteristic.write(utf8.encode(build(id)));
    } on Exception {
      response.ignore();
      throw const BreteException('Falha ao enviar o comando ao brete.');
    }

    try {
      return await response;
    } on TimeoutException {
      throw const BreteException('Sem resposta do brete.');
    }
  }

  @override
  Future<void> restart() async {
    String? rearmError;
    if (_current.connection == BreteConnection.connected) {
      // Melhor esforço: se o link estiver travado, a reconexão resolve.
      try {
        await _request(BreteBleProtocol.stopAllCommand);
        // RESET também tira as portas de FALHA (firmware 1.3).
        if (_current.emergency || _current.hasFault) {
          final resp = await _request(
            (id) => BreteBleProtocol.encodeCommand(BreteCommand.reset, BreteDoor.entry, id),
          );
          rearmError = BreteBleProtocol.errorFor(resp.result ?? '', BreteCommand.reset);
        }
      } on BreteException {
        // segue para a reconexão
      }
    }
    await disconnect();
    // A ESP32 volta a anunciar ~0,5 s depois de perder a conexão.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await connect();
    if (rearmError != null) throw BreteException(rearmError);
  }

  @override
  Future<String?> readNextRfid({Duration timeout = const Duration(seconds: 20)}) async {
    if (_current.connection != BreteConnection.connected) await connect();
    if (_current.connection != BreteConnection.connected) return null;
    if (!_current.rfidAvailable) return null;
    // O leitor do firmware lê sozinho: devolve a tag que já está no brete ou
    // espera o próximo animal chegar.
    final present = _presentTag;
    if (present != null) return present;
    try {
      return await _rfidReads.stream.first.timeout(timeout);
    } on TimeoutException {
      return null;
    }
  }

  /// Cancela assinaturas e encerra o link BLE (sem emitir estado).
  Future<void> _release() async {
    _closing = true;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _command = null;
    _presentTag = null;
    final device = _device;
    _device = null;
    try {
      await device?.disconnect();
    } on Exception {
      // já desconectado
    }
    _closing = false;
  }

  @override
  Future<void> disconnect() async {
    await _release();
    _emit(_current.copyWith(connection: BreteConnection.disconnected, clearError: true));
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
    await _rfidReads.close();
    await _events.close();
    await _alerts.close();
  }
}
