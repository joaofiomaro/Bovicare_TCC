import 'dart:async';
import 'dart:math';

import '../domain/brete_gateway.dart';
import '../domain/brete_models.dart';

/// Brete simulado — usado quando não há broker MQTT configurado (TCC sem o
/// hardware). Reproduz os tempos e regras do firmware: a porteira leva ~1,5 s
/// para abrir/fechar, não fecha com obstáculo e a emergência trava tudo até o
/// rearme.
class SimulatedBreteGateway implements BreteGateway {
  SimulatedBreteGateway({Random? random, List<String> Function()? knownTags})
      : _random = random ?? Random(),
        _knownTags = knownTags ?? (() => const []);

  final Random _random;

  /// Tags RFID do rebanho — a simulação lê uma delas para demonstrar o
  /// reconhecimento do animal (ou gera uma nova, como uma tag desconhecida).
  final List<String> Function() _knownTags;

  static const Duration _moveTime = Duration(milliseconds: 1500);

  final _controller = StreamController<BreteStatus>.broadcast();
  BreteStatus _current = const BreteStatus();
  Timer? _moveTimer;

  @override
  bool get isSimulation => true;

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
    _emit(_current.copyWith(
      connection: BreteConnection.simulated,
      door:       _current.door == DoorState.unknown
          ? DoorState.closed
          : _current.door,
      lastUpdate: DateTime.now(),
      clearError: true,
    ));
  }

  @override
  Future<void> disconnect() async {
    _moveTimer?.cancel();
    _emit(_current.copyWith(connection: BreteConnection.disconnected));
  }

  @override
  Future<void> send(BreteCommand command) async {
    if (!_current.isOnline) throw const BreteException('Brete desconectado.');
    final emergency = _current.door == DoorState.emergency;

    switch (command) {
      case BreteCommand.emergencyStop:
        _moveTimer?.cancel();
        _emit(_current.copyWith(door: DoorState.emergency, lastUpdate: DateTime.now()));
      case BreteCommand.reset:
        if (emergency) _move(DoorState.closed);
      case BreteCommand.open:
        if (emergency) throw const BreteException('Brete em emergência — faça o rearme.');
        _move(DoorState.open);
      case BreteCommand.close:
        if (emergency) throw const BreteException('Brete em emergência — faça o rearme.');
        if (_current.sensors.obstructed) {
          throw const BreteException('Passagem obstruída — porteira não fecha.');
        }
        _move(DoorState.closed);
      case BreteCommand.readRfid:
        _simulateRead();
    }
  }

  void _move(DoorState target) {
    _moveTimer?.cancel();
    _emit(_current.copyWith(door: DoorState.moving, lastUpdate: DateTime.now()));
    _moveTimer = Timer(_moveTime, () {
      _emit(_current.copyWith(door: target, lastUpdate: DateTime.now()));
    });
  }

  String _simulateRead() {
    final knownTags = _knownTags();
    final tag = knownTags.isNotEmpty && _random.nextDouble() < 0.8
        ? knownTags[_random.nextInt(knownTags.length)]
        : '900115${List.generate(9, (_) => _random.nextInt(10)).join()}';
    final now = DateTime.now();
    _emit(_current.copyWith(lastRfid: tag, lastRfidAt: now, lastUpdate: now));
    return tag;
  }

  @override
  Future<String?> readNextRfid({Duration timeout = const Duration(seconds: 20)}) async {
    if (!_current.isOnline) await connect();
    // Tempo de aproximação da tag ao leitor.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return _simulateRead();
  }

  @override
  Future<void> dispose() async {
    _moveTimer?.cancel();
    await _controller.close();
  }
}
