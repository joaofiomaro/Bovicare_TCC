import 'package:intl/intl.dart';

/// Extensões utilitárias para DateTime.
extension DateTimeX on DateTime {
  /// Formato brasileiro: 01/06/2026
  String get toBrDate => DateFormat('dd/MM/yyyy', 'pt_BR').format(this);

  /// Formato com hora: 01/06/2026 às 14:30
  String get toBrDateTime => DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(this);

  /// "há X dias" / "ontem" / "hoje"
  String get toRelative {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays == 0) return 'hoje';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    if (diff.inDays < 30) return 'há ${(diff.inDays / 7).floor()} semana(s)';
    if (diff.inDays < 365) return 'há ${(diff.inDays / 30).floor()} mês(es)';
    return 'há ${(diff.inDays / 365).floor()} ano(s)';
  }

  /// Idade em anos (ex: para animais).
  int get ageInYears {
    final now = DateTime.now();
    var years = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) years--;
    return years;
  }

  /// Idade em meses.
  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - year) * 12 + now.month - month;
  }

  /// "Hoje, 08:14" / "Ontem, 16:32" / "01/06, 10:00" — usado na timeline do dashboard.
  String get toTimelineLabel {
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(year, month, day))
        .inDays;
    final time = DateFormat('HH:mm').format(this);
    if (diff == 0) return 'Hoje, $time';
    if (diff == 1) return 'Ontem, $time';
    return DateFormat('dd/MM, HH:mm', 'pt_BR').format(this);
  }
}
