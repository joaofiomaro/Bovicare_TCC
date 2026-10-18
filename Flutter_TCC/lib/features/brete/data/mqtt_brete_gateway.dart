import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../domain/brete_gateway.dart';
import '../domain/brete_models.dart';

/// Configuração do broker lida do `.env` (MQTT_BROKER_URL etc.).
class BreteMqttConfig {
  const BreteMqttConfig({
    required this.uri,
    required this.clientId,
    required this.deviceId,
    this.username,
    this.password,
  });

  /// `ws://host:9001` (WebSocket) ou `mqtt://host:1883` (TCP).
  final Uri uri;
  final String clientId;
  final String deviceId;
  final String? username;
  final String? password;

  bool get useWebSocket => uri.scheme == 'ws' || uri.scheme == 'wss';

  /// Interpreta a URL do `.env`. Retorna null para valores ausentes ou de
  /// exemplo (`SEU_IP...`) — nesse caso o app usa a simulação.
  static BreteMqttConfig? fromEnv(Map<String, String> env) {
    final raw = env['MQTT_BROKER_URL']?.trim() ?? '';
    if (raw.isEmpty || raw.toUpperCase().contains('SEU_IP')) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.host.isEmpty ||
        !const ['ws', 'wss', 'mqtt', 'mqtts'].contains(uri.scheme)) {
      return null;
    }
    String? opt(String key) {
      final v = env[key]?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    final base = opt('MQTT_CLIENT_ID') ?? 'bovicare_app';
    return BreteMqttConfig(
      uri:      uri,
      // Sufixo aleatório: dois aparelhos com o mesmo id derrubariam um ao
      // outro no broker.
      clientId: '${base}_${DateTime.now().millisecondsSinceEpoch % 100000}',
      deviceId: opt('BRETE_DEVICE_ID') ?? 'brete-01',
      username: opt('MQTT_USERNAME'),
      password: opt('MQTT_PASSWORD'),
    );
  }
}

/// Brete real via MQTT (ESP32). O estado exibido vem SEMPRE do dispositivo
/// (tópico `state`, retido); comandos apenas pedem a ação.
class MqttBreteGateway implements BreteGateway {
  MqttBreteGateway(this.config);

  final BreteMqttConfig config;

  final _controller = StreamController<BreteStatus>.broadcast();
  final _rfidReads  = StreamController<String>.broadcast();
  BreteStatus _current = const BreteStatus();
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _sub;

  @override
  bool get isSimulation => false;

  @override
  BreteStatus get current => _current;

  @override
  Stream<BreteStatus> get status => _controller.stream;

  void _emit(BreteStatus s) {
    _current = s;
    if (!_controller.isClosed) _controller.add(s);
  }

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

    final uri  = config.uri;
    final host = config.useWebSocket ? '${uri.scheme}://${uri.host}' : uri.host;
    final port = uri.hasPort
        ? uri.port
        : (config.useWebSocket ? 9001 : 1883);

    final client = MqttServerClient.withPort(host, config.clientId, port)
      ..useWebSocket          = config.useWebSocket
      ..secure                = uri.scheme == 'mqtts'
      ..keepAlivePeriod       = 20
      ..autoReconnect         = true
      ..connectTimeoutPeriod  = 5000
      ..logging(on: false)
      ..onConnected = _onConnected
      ..onDisconnected = () {
        _emit(_current.copyWith(connection: BreteConnection.disconnected));
      }
      ..onAutoReconnect = () {
        _emit(_current.copyWith(connection: BreteConnection.connecting));
      }
      ..onAutoReconnected = _onConnected;
    if (config.useWebSocket) {
      client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    }
    _client = client;

    try {
      await client.connect(config.username, config.password);
    } on Exception catch (e) {
      client.disconnect();
      _emit(_current.copyWith(
        connection:   BreteConnection.error,
        errorMessage: 'Não foi possível conectar ao brete ($e).',
      ));
      return;
    }
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      _emit(_current.copyWith(
        connection:   BreteConnection.error,
        errorMessage: 'Broker recusou a conexão '
            '(${client.connectionStatus?.returnCode?.name ?? 'sem resposta'}).',
      ));
      return;
    }

    _sub = client.updates?.listen(_onMessages);
  }

  void _onConnected() {
    final client = _client;
    if (client == null) return;
    client
      ..subscribe(BreteProtocol.stateTopic(config.deviceId), MqttQos.atLeastOnce)
      ..subscribe(BreteProtocol.rfidTopic(config.deviceId), MqttQos.atLeastOnce);
    _emit(_current.copyWith(
      connection: BreteConnection.connected,
      clearError: true,
    ));
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final m in messages) {
      final msg = m.payload;
      if (msg is! MqttPublishMessage) continue;
      final payload = utf8.decode(msg.payload.message.toList(), allowMalformed: true);
      final now = DateTime.now();

      if (m.topic == BreteProtocol.stateTopic(config.deviceId)) {
        _emit(BreteProtocol.applyState(_current, payload, now));
      } else if (m.topic == BreteProtocol.rfidTopic(config.deviceId)) {
        final tag = BreteProtocol.parseRfid(payload);
        if (tag == null) continue;
        _emit(_current.copyWith(lastRfid: tag, lastRfidAt: now));
        _rfidReads.add(tag);
      }
    }
  }

  @override
  Future<void> send(BreteCommand command) async {
    final client = _client;
    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      throw const BreteException('Brete desconectado.');
    }
    final builder = MqttClientPayloadBuilder()
      ..addUTF8String(BreteProtocol.encodeCommand(command, DateTime.now()));
    client.publishMessage(
      BreteProtocol.commandTopic(config.deviceId),
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  @override
  Future<String?> readNextRfid({Duration timeout = const Duration(seconds: 20)}) async {
    if (_current.connection != BreteConnection.connected) await connect();
    if (_current.connection != BreteConnection.connected) return null;
    final next = _rfidReads.stream.first.timeout(timeout);
    await send(BreteCommand.readRfid);
    try {
      return await next;
    } on TimeoutException {
      return null;
    }
  }

  @override
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    _client?.disconnect();
    _client = null;
    _emit(_current.copyWith(connection: BreteConnection.disconnected));
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
    await _rfidReads.close();
  }
}
