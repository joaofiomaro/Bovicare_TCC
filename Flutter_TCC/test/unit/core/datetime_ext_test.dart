import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:bovicare/core/extensions/datetime_ext.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));
  group('DateTimeX.toBrDate', () {
    test('formats date in Brazilian format', () {
      final date = DateTime(2026, 6, 3);
      expect(date.toBrDate, '03/06/2026');
    });

    test('pads single-digit day and month', () {
      final date = DateTime(2025, 1, 5);
      expect(date.toBrDate, '05/01/2025');
    });
  });

  group('DateTimeX.ageInYears', () {
    test('calculates full years correctly', () {
      final birthDate = DateTime.now().subtract(const Duration(days: 365 * 3 + 2));
      expect(birthDate.ageInYears, 3);
    });

    test('does not count year before birthday in current year', () {
      final now = DateTime.now();
      final birthDate = DateTime(now.year - 2, now.month, now.day + 1);
      expect(birthDate.ageInYears, 1);
    });

    test('returns 0 for newborn', () {
      final today = DateTime.now();
      expect(today.ageInYears, 0);
    });
  });

  group('DateTimeX.ageInMonths', () {
    test('calculates months across years', () {
      final now = DateTime.now();
      final date = DateTime(now.year - 1, now.month);
      expect(date.ageInMonths, greaterThanOrEqualTo(12));
    });
  });

  group('DateTimeX.toRelative', () {
    test('returns "hoje" for today', () {
      final now = DateTime.now();
      expect(now.toRelative, 'hoje');
    });

    test('returns "ontem" for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(yesterday.toRelative, 'ontem');
    });

    test('returns days for recent dates', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      expect(threeDaysAgo.toRelative, 'há 3 dias');
    });

    test('returns weeks for dates 7-29 days ago', () {
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      expect(twoWeeksAgo.toRelative, 'há 2 semana(s)');
    });
  });

  group('DateTimeX.toTimelineLabel', () {
    test('returns "Hoje, HH:mm" for today', () {
      final now = DateTime.now();
      final label = now.toTimelineLabel;
      expect(label, startsWith('Hoje,'));
    });

    test('returns "Ontem, HH:mm" for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final label = yesterday.toTimelineLabel;
      expect(label, startsWith('Ontem,'));
    });

    test('returns date format for older dates', () {
      final older = DateTime.now().subtract(const Duration(days: 5));
      final label = older.toTimelineLabel;
      expect(label, isNot(startsWith('Hoje')));
      expect(label, isNot(startsWith('Ontem')));
    });
  });
}
