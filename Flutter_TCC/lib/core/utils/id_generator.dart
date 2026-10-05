import 'dart:math';

const String _alphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

final Random _random = Random.secure();

/// Gera um ID de documento no mesmo formato dos auto-IDs do Firestore:
/// 20 caracteres alfanuméricos, aleatórios (`Random.secure`).
///
/// Substitui `DateTime.now().millisecondsSinceEpoch.toString()`, que era
/// previsível (enumerável por terceiros) e colidia quando dois registros eram
/// criados no mesmo milissegundo (ex.: baixa em lote + venda).
String generateId([int length = 20]) => String.fromCharCodes(
      List<int>.generate(
        length,
        (_) => _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
      ),
    );
