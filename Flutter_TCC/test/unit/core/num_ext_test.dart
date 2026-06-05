import 'package:bovicare/core/extensions/num_ext.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  // O intl separa simbolo e valor com espaco nao-quebravel (U+00A0);
  // normaliza para espaco comum nas assercoes.
  String brl(num n) => n.toBrl.replaceAll('\u{00A0}', ' ');

  group('NumX.toBrl', () {
    test('formata milhares com separador e duas casas', () {
      expect(brl(1234.5), r'R$ 1.234,50');
    });

    test('formata zero', () {
      expect(brl(0), r'R$ 0,00');
    });

    test('formata inteiro', () {
      expect(brl(9000), r'R$ 9.000,00');
    });
  });
}
