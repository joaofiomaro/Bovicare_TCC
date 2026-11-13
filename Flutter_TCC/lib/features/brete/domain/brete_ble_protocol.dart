import 'dart:convert';

import 'brete_models.dart';

/// Evento recebido na characteristic de eventos do firmware.
class BreteBleEvent {
  const BreteBleEvent({
    required this.type,
    this.command,
    this.id = 0,
    this.result,
    this.version,
    this.tag,
    this.door,
    this.on,
    this.origin,
    this.fault,
  });

  /// `INICIO`, `RESP`, `PORTA`, `OBSTACULO`, `FALHA`, `EMERGENCIA`, `REARME`,
  /// `RFID`, `RFID_SAIU`, `RFID_OK`, `RFID_ERRO`.
  final String type;

  /// Comando respondido (só em `RESP`).
  final String? command;

  /// Identificador enviado no comando (`#id`), 0 quando não houver.
  final int id;

  /// Resultado do comando (`OK`, `EMERGENCIA`, `INTERTRAVAMENTO`...).
  final String? result;

  /// Versão do firmware (só em `INICIO`).
  final String? version;

  /// Tag lida (`RFID` e `RFID_SAIU`; o firmware 1.3 manda no campo `uid`).
  final String? tag;

  /// Porta do evento (`p`): 1 = entrada, 2 = saída, 0 = não é de porta.
  final int? door;

  /// Emergência ligada/desligada (só em `EMERGENCIA`).
  final bool? on;

  /// Quem originou: `APP`, `SERIAL`, `BOTAO` ou `SISTEMA`.
  final String? origin;

  /// Código da falha (só em `FALHA`), ex.: `TIMEOUT_ABRIR`.
  final String? fault;
}

/// Protocolo BLE do firmware 1.5.1 `BoviCare_Firmware/BoviCare_Brete_Final` (detalhes em
/// docs/PROTOCOLO_BLE.md). Funções puras — testáveis sem hardware.
abstract final class BreteBleProtocol {
  static const deviceName  = 'BoviCare-Brete';
  static const serviceUuid = 'b0c1ca5e-0001-4b8e-9d3a-6f2e1c7a9d10';
  static const commandUuid = 'b0c1ca5e-0002-4b8e-9d3a-6f2e1c7a9d10';
  static const stateUuid   = 'b0c1ca5e-0003-4b8e-9d3a-6f2e1c7a9d10';
  static const eventUuid   = 'b0c1ca5e-0004-4b8e-9d3a-6f2e1c7a9d10';
  static const mtu = 247;

  /// Pedido de estado imediato, enviado logo após conectar.
  static String statusCommand(int id) => '#$id STATUS';

  /// Para as duas portas de uma vez.
  static String stopAllCommand(int id) => '#$id PARAR';

  /// Texto do comando, ex.: `#5 ABRIR 1`. O `#id` volta na resposta (RESP).
  static String encodeCommand(BreteCommand command, BreteDoor door, int id) {
    final verb = switch (command) {
      BreteCommand.open          => 'ABRIR',
      BreteCommand.close         => 'FECHAR',
      BreteCommand.stop          => 'PARAR',
      BreteCommand.emergencyStop => 'EMERGENCIA',
      BreteCommand.reset         => 'RESET',
      BreteCommand.readRfid      => 'LER_RFID',
    };
    return command.targetsDoor
        ? '#$id $verb ${door.index + 1}'
        : '#$id $verb';
  }

  static DoorState parseDoor(Object? raw) => switch (raw) {
        'FECHADA' => DoorState.closed,
        'ABERTA'  => DoorState.open,
        'ABRINDO' || 'FECHANDO' || 'RECUANDO' || 'AJUSTE' => DoorState.moving,
        'PARADA'  => DoorState.stopped,
        'FALHA'   => DoorState.fault,
        _         => DoorState.unknown,
      };

  /// Aplica o JSON da characteristic de estado sobre [current], ex.:
  /// `{"p1":"FECHADA","p2":"ABERTA","ir":"01","em":0,"bot":"000","rfid":"","rok":0}`.
  /// Payload inválido é ignorado (retorna [current]).
  static BreteStatus applyState(BreteStatus current, String payload, DateTime now) {
    final Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return current;
    }
    if (decoded is! Map<String, dynamic> || !decoded.containsKey('p1')) {
      return current;
    }

    bool bit(Object? field, int i) =>
        field is String && field.length > i && field[i] == '1';

    final ir  = decoded['ir'];
    final bot = decoded['bot'];
    final rawTag = decoded['rfid'];
    final tag = rawTag is String && rawTag.isNotEmpty ? normalizeRfidTag(rawTag) : null;
    final newTag = tag != null && tag != current.lastRfid;

    return current.copyWith(
      door:      parseDoor(decoded['p1']),
      exitDoor:  parseDoor(decoded['p2']),
      emergency: decoded['em'] == 1,
      sensors: BreteSensors(
        irEntry:    bit(ir, 0),
        irExit:     bit(ir, 1),
        button1:    bit(bot, 0),
        button2:    bit(bot, 1),
        stopButton: bit(bot, 2),
      ),
      rfidAvailable: decoded['rok'] == 1,
      entryFault:    decoded['f1'] is String ? decoded['f1'] as String : '',
      exitFault:     decoded['f2'] is String ? decoded['f2'] as String : '',
      lastRfid:      newTag ? tag : null,
      lastRfidAt:    newTag ? now : null,
      lastUpdate:    now,
    );
  }

  /// Interpreta a characteristic de eventos. Retorna null para lixo.
  static BreteBleEvent? parseEvent(String payload) {
    final Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final type = decoded['ev'];
    if (type is! String) return null;
    // Campos com tipo inesperado viram null em vez de derrubar o app.
    final map = decoded;
    String? str(String k) => switch (map[k]) { final String v => v, _ => null };
    int? integer(String k) => switch (map[k]) { final int v => v, _ => null };
    final tag = str('uid') ?? str('tag');
    final on  = integer('on');
    return BreteBleEvent(
      type:    type,
      command: str('cmd'),
      id:      integer('id') ?? 0,
      result:  str('res'),
      version: str('ver'),
      tag:     tag != null ? normalizeRfidTag(tag) : null,
      door:    integer('p'),
      on:      on == null ? null : on == 1,
      origin:  str('orig'),
      fault:   str('f'),
    );
  }

  /// Mensagem para o usuário quando o resultado não é `OK`; null quando o
  /// comando foi aceito. `PORTA_INVALIDA`/`INVALIDO` indicam erro do app.
  static String? errorFor(String result, BreteCommand command) => switch (result) {
        'OK'         => null,
        'JA_ABERTA'  => 'A porta já está aberta.',
        'JA_FECHADA' => 'A porta já está fechada.',
        'EMERGENCIA' => command == BreteCommand.reset
            ? 'Solte o botão de parada primeiro.'
            : 'Emergência ativa, faça o rearme.',
        'INTERTRAVAMENTO' => 'Feche a outra porta antes de abrir esta.',
        'OBSTACULO'       => 'Há algo embaixo da porta, não é possível fechar.',
        'NAO_PERMITIDO'   => 'Comando não permitido agora.',
        'FALHA'           => 'Porta em falha — toque em Reiniciar sistema.',
        'INVALIDO' when command == BreteCommand.readRfid =>
            'Este brete não tem leitor RFID.',
        'PORTA_INVALIDA' || 'INVALIDO' => 'Erro interno do app ($result).',
        _                 => 'O brete recusou o comando ($result).',
      };

  /// Alerta a mostrar para eventos espontâneos do brete (null = nenhum).
  static String? alertFor(BreteBleEvent ev) => switch (ev.type) {
        'OBSTACULO' => ev.door == 2
            ? 'Obstáculo na porta de saída — ela vai reabrir.'
            : 'Obstáculo na porta de entrada — ela vai reabrir.',
        'FALHA' => 'Falha na porta de ${ev.door == 2 ? 'saída' : 'entrada'}: '
            '${faultLabel(ev.fault ?? '')}.',
        'EMERGENCIA' when (ev.on ?? false) && ev.origin != 'APP' =>
            'Emergência acionada pelo botão do brete.',
        _ => null,
      };

  /// Explicação curta do código de falha da porta (`f1`/`f2`).
  static String faultLabel(String code) => switch (code) {
        'TIMEOUT_ABRIR'  => 'não chegou ao fim de curso ao abrir',
        'TIMEOUT_FECHAR' => 'não chegou ao fim de curso ao fechar',
        'FIM_DUPLO'      => 'as duas chaves de fim de curso estão acionadas',
        'FIM_PRESO'      => 'a chave de fim de curso não soltou',
        _                => code.isEmpty ? 'falha desconhecida' : code,
      };
}
