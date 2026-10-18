import '../../health/domain/entities/health_event.dart';
import '../../herd/domain/entities/animal_entity.dart';
import '../../settings/domain/entities/user_settings.dart';
import '../../vaccination/domain/entities/vaccination_record.dart';

enum FarmAlertType { vaccineOverdue, vaccineDue, birthDue, withdrawal }

enum FarmAlertSeverity { high, medium, info }

/// Alerta operacional do rebanho exibido no dashboard e na central de alertas.
class FarmAlert {
  const FarmAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.animalId,
  });

  final FarmAlertType type;
  final FarmAlertSeverity severity;
  final String title;
  final String subtitle;

  /// Data de referência (vencimento, parto previsto ou fim da carência).
  final DateTime date;
  final String animalId;
}

/// Doses atrasadas há mais que isso deixam de ser alertadas (provavelmente
/// o manejo foi abandonado ou registrado fora do app).
const int kOverdueWindowDays = 60;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monta os alertas do rebanho ativo conforme as preferências do usuário.
/// Função pura — sem I/O, testável isoladamente.
List<FarmAlert> buildFarmAlerts({
  required List<AnimalEntity> animals,
  required List<VaccinationRecord> vaccinations,
  required List<HealthEvent> healthEvents,
  required AlertSettings settings,
  required DateTime now,
}) {
  final today   = _day(now);
  final horizon = today.add(Duration(days: settings.leadDays));
  final active  = {
    for (final a in animals)
      if (!a.isArchived) a.id: a,
  };
  final alerts = <FarmAlert>[];

  // ── Vacinas: próxima dose a vencer ou atrasada ─────────────────────────────
  if (settings.vaccines) {
    // Só a aplicação mais recente de cada vacina por animal define a próxima
    // dose — doses anteriores já foram "cumpridas".
    final latest = <(String, String), VaccinationRecord>{};
    for (final v in vaccinations) {
      final key = (v.animalId, v.vaccineName);
      final current = latest[key];
      if (current == null || v.date.isAfter(current.date)) latest[key] = v;
    }
    for (final v in latest.values) {
      final animal = active[v.animalId];
      final next   = v.nextDoseDate;
      if (animal == null || next == null) continue;
      final due = _day(next);
      if (due.isAfter(horizon)) continue;
      final overdueDays = today.difference(due).inDays;
      if (overdueDays > kOverdueWindowDays) continue;

      final overdue = overdueDays > 0;
      alerts.add(FarmAlert(
        type:     overdue ? FarmAlertType.vaccineOverdue : FarmAlertType.vaccineDue,
        severity: overdue ? FarmAlertSeverity.high : FarmAlertSeverity.medium,
        title:    '${v.vaccineName} — ${animal.displayName}',
        subtitle: overdue
            ? 'Dose atrasada há $overdueDays dia${overdueDays == 1 ? '' : 's'}'
            : due == today
                ? 'Próxima dose vence hoje'
                : 'Próxima dose em ${due.difference(today).inDays} dia(s)',
        date:     due,
        animalId: animal.id,
      ));
    }
  }

  // ── Partos previstos ───────────────────────────────────────────────────────
  if (settings.births) {
    for (final animal in active.values) {
      final expected = animal.status == AnimalStatus.pregnant
          ? animal.expectedBirthDate
          : null;
      if (expected == null) continue;
      final due = _day(expected);
      if (due.isAfter(horizon)) continue;
      final late = today.difference(due).inDays;
      if (late > 30) continue;
      alerts.add(FarmAlert(
        type:     FarmAlertType.birthDue,
        severity: late > 0 ? FarmAlertSeverity.high : FarmAlertSeverity.medium,
        title:    'Parto previsto — ${animal.displayName}',
        subtitle: late > 0
            ? 'Previsão ultrapassada há $late dia(s) — registre o parto'
            : 'Previsto para daqui a ${due.difference(today).inDays} dia(s)',
        date:     due,
        animalId: animal.id,
      ));
    }
  }

  // ── Carência ativa (vacinas e tratamentos) ─────────────────────────────────
  if (settings.withdrawal) {
    // Por animal, vale a carência que termina por último.
    final ends = <String, (DateTime, String)>{};
    void consider(String animalId, DateTime? end, String source) {
      if (end == null || _day(end).isBefore(today)) return;
      final current = ends[animalId];
      if (current == null || end.isAfter(current.$1)) {
        ends[animalId] = (end, source);
      }
    }

    for (final v in vaccinations) {
      if (v.quarantineDays <= 0) continue;
      consider(
        v.animalId,
        v.date.add(Duration(days: v.quarantineDays)),
        v.vaccineName,
      );
    }
    for (final e in healthEvents) {
      if (e.type.isTreatment) consider(e.animalId, e.withdrawalEnd, e.title);
    }
    for (final entry in ends.entries) {
      final animal = active[entry.key];
      if (animal == null) continue;
      final (end, source) = entry.value;
      alerts.add(FarmAlert(
        type:     FarmAlertType.withdrawal,
        severity: FarmAlertSeverity.info,
        title:    'Em carência — ${animal.displayName}',
        subtitle: 'Não abater nem vender leite até ${_br(end)} ($source)',
        date:     _day(end),
        animalId: animal.id,
      ));
    }
  }

  int rank(FarmAlertSeverity s) => s.index;
  return alerts
    ..sort((a, b) {
      final bySeverity = rank(a.severity).compareTo(rank(b.severity));
      return bySeverity != 0 ? bySeverity : a.date.compareTo(b.date);
    });
}

String _br(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
