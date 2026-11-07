import 'dart:async';
import 'dart:math';

import '../domain/brete_gateway.dart';
import '../domain/brete_models.dart';

/// Brete simulado — usado quando não há hardware (TCC sem o ESP32).
/// Reproduz as regras do firmware: duas portas, cada uma leva ~1,5 s para
/// abrir/fechar, uma só abre com a outra fechada (intertravamento), não fecha
/// com obstáculo e a emergência trava tudo até o rearme.
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
  final _moveTimers = <BreteDoor, Timer>{};

  @override
  BreteTransport get transport => BreteTransport.simulation;

  @override
  bool get isSimulation => true;

  @override
  BreteStatus get current => _current;

  @override
  Stream<BreteStatus> get status => _controller.stream;

  @override
  Stream<String> get alerts => const Stream.empty();

  void _emit(BreteStatus s) {
    _current = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  @override
  Future<void> connect() async {
    DoorState settled(DoorState? d) =>
        d == null || d == DoorState.unknown ? DoorState.closed : d;
    _emit(_current.copyWith(
      connection: BreteConnection.simulated,
      door:       settled(_current.door),
      exitDoor:   settled(_current.exitDoor),
      lastUpdate: DateTime.now(),
      clearError: true,
    ));
  }

  void _cancelTimers() {
    for (final t in _moveTimers.values) {
      t.cancel();
    }
    _moveTimers.clear();
  }

  @override
  Future<void> disconnect() async {
    _cancelTimers();
    _emit(_current.copyWith(connection: BreteConnection.disconnected));
  }

  @override
  Future<void> send(BreteCommand command, {BreteDoor door = BreteDoor.entry}) async {
    if (!_current.isOnline) throw const BreteException('Brete desconectado.');
    const blocked = BreteException('Brete em emergência — faça o rearme.');

    switch (command) {
      case BreteCommand.emergencyStop:
        _cancelTimers();
        var s = _current.copyWith(emergency: true, lastUpdate: DateTime.now());
        for (final d in BreteDoor.values) {
          if (s.doorOf(d) == DoorState.moving) s = s.withDoor(d, DoorState.stopped);
        }
        _emit(s);
      case BreteCommand.reset:
        _emit(_current.copyWith(emergency: false, lastUpdate: DateTime.now()));
      case BreteCommand.open:
        if (_current.emergency) throw blocked;
        if (_current.doorOf(door) == DoorState.open) return;
        final other = door == BreteDoor.entry ? BreteDoor.exit : BreteDoor.entry;
        if (_current.doorOf(other) != DoorState.closed) {
          throw const BreteException('Feche a outra porta antes de abrir esta.');
        }
        _move(door, DoorState.open);
      case BreteCommand.close:
        if (_current.emergency) throw blocked;
        if (_current.doorOf(door) == DoorState.closed) return;
        if (_current.sensors.obstructedAt(door)) {
          throw const BreteException('Passagem obstruída — a porta não fecha.');
        }
        _move(door, DoorState.closed);
      case BreteCommand.stop:
        _moveTimers.remove(door)?.cancel();
        if (_current.doorOf(door) == DoorState.moving) {
          _emit(_current.withDoor(door, DoorState.stopped, at: DateTime.now()));
        }
      case BreteCommand.readRfid:
        _simulateRead();
    }
  }

  void _move(BreteDoor door, DoorState target) {
    _moveTimers.remove(door)?.cancel();
    _emit(_current.withDoor(door, DoorState.moving, at: DateTime.now()));
    _moveTimers[door] = Timer(_moveTime, () {
      _moveTimers.remove(door);
      _emit(_current.withDoor(door, target, at: DateTime.now()));
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
  Future<void> restart() async {
    _cancelTimers();
    var s = _current.copyWith(emergency: false);
    for (final d in BreteDoor.values) {
      if (s.doorOf(d) == DoorState.moving) s = s.withDoor(d, DoorState.stopped);
    }
    _emit(s.copyWith(connection: BreteConnection.connecting));
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await connect();
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
    _cancelTimers();
    await _controller.close();
  }
}
