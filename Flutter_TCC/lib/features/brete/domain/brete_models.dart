import 'dart:convert';

/// Situação de uma porta guilhotina do brete reportada pelo ESP32.
enum DoorState {
  open,
  closed,
  moving,

  /// Parada no meio do curso (botão, comando PARAR ou emergência).
  stopped,

  /// Bloqueada por falha (fim de curso ou tempo-limite) até o RESET.
  fault,
  unknown,
}

/// Portas do brete: 1 = entrada, 2 = saída (numeração do firmware).
enum BreteDoor { entry, exit }

/// Situação da conexão do app com o brete.
enum BreteConnection { disconnected, connecting, connected, simulated, error }

/// Meio de comunicação com o brete.
enum BreteTransport { simulation, ble, mqtt }

/// Comandos aceitos pelo firmware.
enum BreteCommand {
  open,
  close,

  /// Para a porta no ponto em que estiver.
  stop,
  emergencyStop,

  /// Sai do estado de emergência (rearme).
  reset,

  /// Pede ao leitor RFID que faça uma leitura imediata.
  readRfid,
}

extension BreteCommandX on BreteCommand {
  /// Valor do campo `cmd` no JSON enviado pelo MQTT.
  String get wire => switch (this) {
        BreteCommand.open          => 'open',
        BreteCommand.close         => 'close',
        BreteCommand.stop          => 'stop',
        BreteCommand.emergencyStop => 'emergency_stop',
        BreteCommand.reset         => 'reset',
        BreteCommand.readRfid      => 'read_rfid',
      };

  /// Comandos que agem sobre uma porta específica.
  bool get targetsDoor =>
      this == BreteCommand.open ||
      this == BreteCommand.close ||
      this == BreteCommand.stop;
}

/// Sensores e botões do brete. `true` = obstruído (infravermelho) ou
/// apertado (botão).
class BreteSensors {
  const BreteSensors({
    this.irEntry = false,
    this.irExit = false,
    this.button1 = false,
    this.button2 = false,
    this.stopButton = false,
  });

  /// Sensor IR da porta de entrada (porta 1).
  final bool irEntry;

  /// Sensor IR da porta de saída (porta 2).
  final bool irExit;

  /// Botão físico que alterna a porta 1.
  final bool button1;

  /// Botão físico que alterna a porta 2.
  final bool button2;

  /// Botão de parada de emergência apertado.
  final bool stopButton;

  /// Há um animal/obstáculo em alguma passagem.
  bool get obstructed => irEntry || irExit;

  bool obstructedAt(BreteDoor door) =>
      door == BreteDoor.entry ? irEntry : irExit;
}

/// Estado completo do brete exibido no painel.
class BreteStatus {
  const BreteStatus({
    this.connection = BreteConnection.disconnected,
    this.door = DoorState.unknown,
    this.exitDoor,
    this.emergency = false,
    this.sensors = const BreteSensors(),
    this.lastRfid,
    this.lastRfidAt,
    this.lastUpdate,
    this.errorMessage,
    this.firmwareVersion,
    this.rfidAvailable = true,
    this.entryFault = '',
    this.exitFault = '',
  });

  final BreteConnection connection;

  /// Porta de entrada (porta 1) — ou a única porta, no protocolo MQTT.
  final DoorState door;

  /// Porta de saída (porta 2). `null` quando o brete tem uma porta só.
  final DoorState? exitDoor;

  /// Parada de emergência ativa: comandos de porta bloqueados até o rearme.
  final bool emergency;
  final BreteSensors sensors;
  final String? lastRfid;
  final DateTime? lastRfidAt;

  /// Momento do último estado recebido do dispositivo.
  final DateTime? lastUpdate;
  final String? errorMessage;
  final String? firmwareVersion;

  /// O brete tem leitor RFID funcionando.
  final bool rfidAvailable;

  /// Código da falha de cada porta (`TIMEOUT_ABRIR`...); vazio = sem falha.
  final String entryFault;
  final String exitFault;

  /// Falha da porta, ou null se ela estiver normal.
  String? faultOf(BreteDoor d) {
    final f = d == BreteDoor.entry ? entryFault : exitFault;
    return f.isEmpty ? null : f;
  }

  bool get hasFault =>
      entryFault.isNotEmpty ||
      exitFault.isNotEmpty ||
      door == DoorState.fault ||
      exitDoor == DoorState.fault;

  bool get isOnline =>
      connection == BreteConnection.connected ||
      connection == BreteConnection.simulated;

  bool get hasExitDoor => exitDoor != null;

  DoorState doorOf(BreteDoor d) =>
      d == BreteDoor.entry ? door : (exitDoor ?? DoorState.unknown);

  BreteStatus copyWith({
    BreteConnection? connection,
    DoorState? door,
    DoorState? exitDoor,
    bool? emergency,
    BreteSensors? sensors,
    String? lastRfid,
    DateTime? lastRfidAt,
    DateTime? lastUpdate,
    String? errorMessage,
    bool clearError = false,
    String? firmwareVersion,
    bool? rfidAvailable,
    String? entryFault,
    String? exitFault,
  }) =>
      BreteStatus(
        connection:      connection ?? this.connection,
        door:            door ?? this.door,
        exitDoor:        exitDoor ?? this.exitDoor,
        emergency:       emergency ?? this.emergency,
        sensors:         sensors ?? this.sensors,
        lastRfid:        lastRfid ?? this.lastRfid,
        lastRfidAt:      lastRfidAt ?? this.lastRfidAt,
        lastUpdate:      lastUpdate ?? this.lastUpdate,
        errorMessage:    clearError ? null : (errorMessage ?? this.errorMessage),
        firmwareVersion: firmwareVersion ?? this.firmwareVersion,
        rfidAvailable:   rfidAvailable ?? this.rfidAvailable,
        entryFault:      entryFault ?? this.entryFault,
        exitFault:       exitFault ?? this.exitFault,
      );

  /// Atualiza uma das portas.
  BreteStatus withDoor(BreteDoor d, DoorState state, {DateTime? at}) =>
      d == BreteDoor.entry
          ? copyWith(door: state, lastUpdate: at)
          : copyWith(exitDoor: state, lastUpdate: at);
}

/// Validação de tag RFID compartilhada pelos protocolos: só dígitos/letras,
/// 4–32 caracteres (ISO 11784/11785 tem 15 dígitos; UID do RC522 em hex tem
/// 8–20).
String? normalizeRfidTag(String raw) {
  final tag = raw.trim();
  return RegExp(r'^[A-Za-z0-9]{4,32}$').hasMatch(tag) ? tag : null;
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
        'emergency' || 'stopped' => DoorState.stopped,
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
    final hasDoor = decoded.containsKey('door');
    return current.copyWith(
      door:      hasDoor ? parseDoor(decoded['door']) : current.door,
      emergency: hasDoor ? decoded['door'] == 'emergency' : current.emergency,
      sensors: sensors is Map<String, dynamic>
          ? BreteSensors(
              irEntry: sensors['irTop'] == true,
              irExit:  sensors['irBottom'] == true,
              button1: sensors['pedalOpen'] == true,
              button2: sensors['pedalClose'] == true,
            )
          : current.sensors,
      lastUpdate: now,
    );
  }

  /// Extrai o código RFID do tópico `rfid` — aceita `{"tag":"..."}` ou o
  /// código puro.
  static String? parseRfid(String payload) {
    var tag = payload.trim();
    try {
      final decoded = jsonDecode(tag);
      if (decoded is Map<String, dynamic>) tag = '${decoded['tag'] ?? ''}';
    } on FormatException {
      // payload em texto puro
    }
    return normalizeRfidTag(tag);
  }
}
