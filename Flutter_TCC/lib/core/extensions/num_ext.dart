import 'package:intl/intl.dart';

/// Extensões utilitárias para valores numéricos.
extension NumX on num {
  /// Formatação monetária brasileira: 1234.5 → "R$ 1.234,50".
  String get toBrl =>
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(this);
}
