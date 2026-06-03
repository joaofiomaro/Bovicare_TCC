import 'package:flutter_test/flutter_test.dart';
import 'package:bovicare/features/vaccination/domain/usecases/calculate_quarantine_end_use_case.dart';

void main() {
  const useCase = CalculateQuarantineEndUseCase();

  group('CalculateQuarantineEndUseCase', () {
    test('returns null when quarantineDays is 0', () {
      final result = useCase.call(
        date: DateTime(2026, 6),
        quarantineDays: 0,
      );
      expect(result, isNull);
    });

    test('returns null when quarantineDays is negative', () {
      final result = useCase.call(
        date: DateTime(2026, 6),
        quarantineDays: -5,
      );
      expect(result, isNull);
    });

    test('adds quarantine days to vaccination date', () {
      final vaccineDate = DateTime(2026, 6);
      final result = useCase.call(date: vaccineDate, quarantineDays: 21);
      expect(result, DateTime(2026, 6, 22));
    });

    test('handles month boundary correctly', () {
      final result = useCase.call(
        date: DateTime(2026, 6, 25),
        quarantineDays: 10,
      );
      expect(result, DateTime(2026, 7, 5));
    });

    test('handles year boundary correctly', () {
      final result = useCase.call(
        date: DateTime(2025, 12, 25),
        quarantineDays: 10,
      );
      expect(result, DateTime(2026, 1, 4));
    });

    test('handles typical Aftosa quarantine (21 days)', () {
      final date = DateTime(2026);
      final result = useCase.call(date: date, quarantineDays: 21);
      expect(result, DateTime(2026, 1, 22));
    });
  });
}
