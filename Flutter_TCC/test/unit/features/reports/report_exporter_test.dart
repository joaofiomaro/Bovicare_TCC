import 'dart:convert';

import 'package:bovicare/features/reports/data/report_exporter.dart';
import 'package:bovicare/features/reports/domain/entities/report_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

ReportData _report({List<String>? footer}) => ReportData(
      type:        ReportType.sales,
      headers:     const ['Data', 'Comprador', 'Valor'],
      rows:        const [
        ['01/03/2026', 'Frigorífico; Ltda', r'R$ 24.000,00'],
        ['02/03/2026', 'José "Zé"', '—'],
      ],
      footer:      footer,
      generatedAt: DateTime(2026, 3, 5, 10),
      periodStart: DateTime(2026, 2),
      periodEnd:   DateTime(2026, 3, 5),
    );

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  group('ReportExporter.toCsv', () {
    test('usa ; como separador e escapa aspas e separadores', () {
      final lines = ReportExporter.toCsv(_report()).split('\r\n');
      expect(lines.first, 'Data;Comprador;Valor');
      expect(lines[1], r'01/03/2026;"Frigorífico; Ltda";R$ 24.000,00');
      expect(lines[2], '02/03/2026;"José ""Zé""";—');
    });

    test('inclui a linha de totais quando existe', () {
      final csv = ReportExporter.toCsv(_report(footer: const ['TOTAL', '', 'x']));
      expect(csv.split('\r\n').last, 'TOTAL;;x');
    });

    test('bytes começam com BOM UTF-8 (Excel pt-BR)', () {
      final bytes = ReportExporter.toCsvBytes(_report());
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(bytes.sublist(3)), contains('Frigorífico'));
    });
  });

  test('fileName segue o padrão bovicare_<tipo>_<data>.<ext>', () {
    expect(
      ReportExporter.fileName(_report(), ReportFormat.pdf),
      'bovicare_sales_20260305.pdf',
    );
  });

  test('pdfSafe mantém acentos e troca símbolos fora do Latin-1', () {
    expect(ReportExporter.pdfSafe('Vacinação — Aftosa'), 'Vacinação - Aftosa');
  });

  test('toPdf gera um PDF válido', () async {
    final bytes = await ReportExporter.toPdf(_report());
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
