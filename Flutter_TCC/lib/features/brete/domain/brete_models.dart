import 'dart:convert';

/// Situação da porteira do brete reportada pelo ESP32.
enum DoorState { open, closed, moving, emergency, unknown }

/// Situação da conexão do app com o brete.
enum BreteConnection { disconnected, connecting, connected, simulated, error }

/// Comandos aceitos pelo firmware (tópico `.../cmd`).
enum BreteCommand {
  open,
  close,
  emergencyStop,

  /// Sai do estado de emergência (rearme), deixando a porteira fechada.
  reset,

  /// Pede ao leitor RFID que faça uma leitura imediata.
  readRfid,
}

extension BreteCommandX on BreteCommand {
  /// Valor do campo `cmd` no JSON enviado ao firmware.
  String get wire => switch (this) {
        BreteCommand.open          => 'open',
        BreteCommand.close         => 'close',
        BreteCommand.emergencyStop => 'emergency_stop',
        BreteCommand.reset         => 'reset',
        BreteCommand.readRfid      => 'read_rfid',
      };
}

/// Sensores do brete. `true` = obstruído (infravermelho) ou acionado (pedal).
class BreteSensors {
  const BreteSensors({
    this.irTop = false,
    this.irBottom = false,
    this.pedalOpen = false,
    this.pedalClose = false,
  });

  final bool irTop;
  final bool irBottom;
  final bool pedalOpen;
  final bool pedalClose;

  /// Há um animal/obstáculo na passagem.
  bool get obstructed => irTop || irBottom;
}

/// Estado completo do brete exibido no painel.
class BreteStatus {
  const BreteStatus({
    this.connection = BreteConnection.disconnected,
    this.door = DoorState.unknown,
    this.sensors = const BreteSensors(),
    this.lastRfid,
    this.lastRfidAt,
    this.lastUpdate,
    this.errorMessage,
  });

  final BreteConnection connection;
  final DoorState door;
  final BreteSensors sensors;
  final String? lastRfid;
  final DateTime? lastRfidAt;

  /// Momento do último estado recebido do dispositivo.
  final DateTime? lastUpdate;
  final String? errorMessage;

  bool get isOnline =>
      connection == BreteConnection.connected ||
      connection == BreteConnection.simulated;

  BreteStatus copyWith({
    BreteConnection? connection,
    DoorState? door,
    BreteSensors? sensors,
    String? lastRfid,
    DateTime? lastRfidAt,
    DateTime? lastUpdate,
    String? errorMessage,
    bool clearError = false,
  }) =>
      BreteStatus(
        connection:   connection ?? this.connection,
        door:         door ?? this.door,
        sensors:      sensors ?? this.sensors,
        lastRfid:     lastRfid ?? this.lastRfid,
        lastRfidAt:   lastRfidAt ?? this.lastRfidAt,
        lastUpdate:   lastUpdate ?? this.lastUpdate,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

/// Protocolo MQTT do brete (ver docs/BRETE_MQTT_PROTOCOLO.md).
/// Funções puras — testáveis sem broker.
abstract final class BreteProtocol {
  static String commandTopic(String deviceId) => 'bovicare/brete/$deviceId/cmd';
  static String stateTopic(String deviceId) => 'bovicare/brete/$deviceId/state';
  static String rfidTopic(String deviceId) => 'bovicare/brete/$deviceId/rfid';

  /// `{"cmd":"open","ts":"2026-...Z"}`
  static String encodeCommand(BreteCommand command, DateTime now) =>
      jsonEncode({'cmd': command.wire, 'ts': now.toUtc().toIso8601String()});

  static DoorState parseDoor(Object? raw) => switch (raw) {
        'open'      => DoorState.open,
        'closed'    => DoorState.closed,
        'opening' || 'closing' || 'moving' => DoorState.moving,
        'emergency' => DoorState.emergency,
        _           => DoorState.unknown,
      };

  /// Aplica o JSON do tópico `state` sobre [current]. Payload inválido é
  /// ignorado (retorna [current]) — o firmware nunca derruba o app.
  static BreteStatus applyState(BreteStatus current, String payload, DateTime now) {
    final Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return current;
    }
    if (decoded is! Map<String, dynamic>) return current;

    final sensors = decoded['sensors'];
    return current.copyWith(
      door: decoded.containsKey('door')
          ? parseDoor(decoded['door'])
          : current.door,
      sensors: sensors is Map<String, dynamic>
          ? BreteSensors(
              irTop:      sensors['irTop'] == true,
              irBottom:   sensors['irBottom'] == true,
              pedalOpen:  sensors['pedalOpen'] == true,
              pedalClose: sensors['pedalClose'] == true,
            )
          : current.sensors,
      lastUpdate: now,
    );
  }

  /// Extrai o código RFID do tópico `rfid` — aceita `{"tag":"..."}` ou o
  /// código puro. Só dígitos/letras (ISO 11784/11785 tem 15 dígitos).
  static String? parseRfid(String payload) {
    var tag = payload.trim();
    try {
      final decoded = jsonDecode(tag);
      if (decoded is Map<String, dynamic>) tag = '${decoded['tag'] ?? ''}';
    } on FormatException {
      // payload em texto puro
    }
    tag = tag.trim();
    return RegExp(r'^[A-Za-z0-9]{4,32}$').hasMatch(tag) ? tag : null;
  }
}
