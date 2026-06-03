import 'package:bovicare/features/weighing/domain/entities/weighing.dart';
import 'package:flutter_test/flutter_test.dart';

Weighing _w(String id, double kg, DateTime date) =>
    Weighing(id: id, animalId: 'a1', weightKg: kg, date: date);

void main() {
  group('WeighingsX', () {
    test('lista vazia: métricas neutras', () {
      const list = <Weighing>[];
      expect(list.lastWeight, isNull);
      expect(list.totalGain, 0);
      expect(list.periodDays, 0);
      expect(list.gmd, isNull);
    });

    test('uma pesagem: sem ganho nem GMD', () {
      final list = [_w('1', 300, DateTime(2026, 1, 10))];
      expect(list.lastWeight, 300);
      expect(list.totalGain, 0);
      expect(list.gmd, isNull); // < 2 pesagens
    });

    test('lastWeight usa a pesagem mais recente, independente da ordem', () {
      final list = [
        _w('1', 320, DateTime(2026, 3)),
        _w('2', 300, DateTime(2026)),
      ];
      expect(list.lastWeight, 320);
    });

    test('totalGain = última - primeira por data', () {
      final list = [
        _w('2', 360, DateTime(2026, 4)),
        _w('1', 300, DateTime(2026)),
      ];
      expect(list.totalGain, 60);
    });

    test('periodDays entre primeira e última pesagem', () {
      final list = [
        _w('1', 300, DateTime(2026)),
        _w('2', 330, DateTime(2026, 1, 31)),
      ];
      expect(list.periodDays, 30);
    });

    test('gmd = ganho total / dias', () {
      final list = [
        _w('1', 300, DateTime(2026)),
        _w('2', 330, DateTime(2026, 1, 31)),
      ];
      // 30 kg em 30 dias = 1.0 kg/dia
      expect(list.gmd, 1.0);
    });

    test('gmd é null quando todas as pesagens são no mesmo dia (sem dividir por zero)', () {
      final list = [
        _w('1', 300, DateTime(2026, 1, 10)),
        _w('2', 305, DateTime(2026, 1, 10)),
      ];
      expect(list.periodDays, 0);
      expect(list.gmd, isNull);
    });

    test('aceita ganho negativo (perda de peso)', () {
      final list = [
        _w('1', 400, DateTime(2026)),
        _w('2', 380, DateTime(2026, 1, 11)),
      ];
      expect(list.totalGain, -20);
      expect(list.gmd, -2.0);
    });
  });
}
