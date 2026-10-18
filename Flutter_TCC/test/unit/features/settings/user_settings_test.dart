import 'package:bovicare/features/settings/domain/entities/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlertSettings', () {
    test('padrão: 30 dias e todas as categorias', () {
      final s = AlertSettings.fromMap(null);
      expect(s.leadDays, 30);
      expect(s.vaccines && s.withdrawal && s.births, isTrue);
    });

    test('ida e volta pelo mapa', () {
      const s = AlertSettings(leadDays: 7, births: false);
      final back = AlertSettings.fromMap(s.toMap());
      expect(back.leadDays, 7);
      expect(back.births, isFalse);
      expect(back.vaccines, isTrue);
    });

    test('antecedência inválida volta ao padrão', () {
      expect(AlertSettings.fromMap({'leadDays': 999}).leadDays, 30);
    });
  });

  group('ConsentSettings', () {
    test('sem decisão, a localização é permitida (permissão do SO decide)', () {
      expect(
        const ConsentSettings().isGranted(ConsentPurpose.location),
        isTrue,
      );
    });

    test('revogação registra data e persiste no mapa', () {
      final s = const ConsentSettings()
          .withDecision(ConsentPurpose.location, granted: false);
      final back = ConsentSettings.fromMap(s.toMap());
      expect(back.isGranted(ConsentPurpose.location), isFalse);
      expect(back.decisions[ConsentPurpose.location]!.at, isNotNull);
    });
  });
}
