import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/extensions/datetime_ext.dart';
import '../domain/entities/report_data.dart';

/// Formatos de exportação suportados.
enum ReportFormat {
  pdf,
  csv;

  String get label => name.toUpperCase();
  String get extension => name;
  String get mimeType => switch (this) {
        ReportFormat.pdf => 'application/pdf',
        ReportFormat.csv => 'text/csv',
      };
}

/// Converte um [ReportData] em arquivo (bytes) PDF ou CSV.
abstract final class ReportExporter {
  /// Separador `;` e BOM UTF-8: abre corretamente no Excel em pt-BR
  /// (que usa vírgula como separador decimal).
  static String toCsv(ReportData data) {
    String cell(String v) {
      final needsQuotes = v.contains(';') ||
          v.contains('"') ||
          v.contains('\n') ||
          v.contains('\r');
      final escaped = v.replaceAll('"', '""');
      return needsQuotes ? '"$escaped"' : escaped;
    }

    String line(List<String> values) => values.map(cell).join(';');

    return [
      line(data.headers),
      for (final row in data.rows) line(row),
      if (data.footer != null) line(data.footer!),
    ].join('\r\n');
  }

  static Uint8List toCsvBytes(ReportData data) => Uint8List.fromList([
        0xEF, 0xBB, 0xBF, // BOM
        ...utf8.encode(toCsv(data)),
      ]);

  /// Nome de arquivo estável: `bovicare_<tipo>_<aaaammdd>.<ext>`.
  static String fileName(ReportData data, ReportFormat format) {
    final d = data.generatedAt;
    final stamp = '${d.year}'
        '${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}';
    return 'bovicare_${data.type.name}_$stamp.${format.extension}';
  }

  /// As fontes padrão do PDF cobrem apenas Latin-1 (inclui acentos do
  /// português); troca os poucos símbolos fora disso por equivalentes.
  static String pdfSafe(String text) {
    const replacements = {
      '—': '-', '–': '-', '…': '...', '“': '"', '”': '"', '‘': "'", '’': "'",
      '•': '·', ' ': ' ',
    };
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (replacements.containsKey(char)) {
        buffer.write(replacements[char]);
      } else if (rune <= 0xFF) {
        buffer.write(char);
      } else {
        buffer.write('?');
      }
    }
    return buffer.toString();
  }

  static Future<Uint8List> toPdf(ReportData data) async {
    final doc = pw.Document(
      title:   pdfSafe(data.type.label),
      author:  'BoviCare',
      creator: 'BoviCare',
    );
    const brand = PdfColor.fromInt(0xFF1C6B3A);
    const pale  = PdfColor.fromInt(0xFFF2FAF5);

    doc.addPage(
      pw.MultiPage(
        pageFormat:  PdfPageFormat.a4.landscape,
        margin:      const pw.EdgeInsets.all(28),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              pdfSafe('BoviCare - ${data.type.label}'),
              style: const pw.TextStyle(
                fontSize:   18,
                fontWeight: pw.FontWeight.bold,
                color:      brand,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              pdfSafe(
                'Período: ${data.periodStart.toBrDate} a ${data.periodEnd.toBrDate}'
                '  ·  Gerado em ${data.generatedAt.toBrDateTime}'
                '  ·  ${data.totalRecords} registro(s)',
              ),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            pdfSafe('Página ${ctx.pageNumber} de ${ctx.pagesCount}'),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          if (data.rows.isEmpty)
            pw.Text(pdfSafe('Nenhum dado no período selecionado.'))
          else
            pw.TableHelper.fromTextArray(
              headers: data.headers.map(pdfSafe).toList(),
              data: [
                for (final row in data.rows) row.map(pdfSafe).toList(),
                if (data.footer != null) data.footer!.map(pdfSafe).toList(),
              ],
              headerStyle: const pw.TextStyle(
                fontSize:   9,
                fontWeight: pw.FontWeight.bold,
                color:      PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: brand),
              cellStyle:        const pw.TextStyle(fontSize: 8.5),
              oddRowDecoration: const pw.BoxDecoration(color: pale),
              cellAlignment:    pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
        ],
      ),
    );
    return doc.save();
  }
}
