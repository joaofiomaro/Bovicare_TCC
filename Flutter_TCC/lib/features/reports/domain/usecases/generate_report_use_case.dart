import '../../../../core/extensions/datetime_ext.dart';
import '../../../herd/domain/entities/animal_entity.dart';
import '../../../herd/domain/repositories/animal_repository.dart';
import '../../../vaccination/domain/repositories/vaccination_repository.dart';
import '../entities/report_data.dart';

/// Agrega dados do Firestore (animais + vacinações) e devolve um [ReportData].
class GenerateReportUseCase {
  const GenerateReportUseCase(this._animals, this._vaccinations);

  final AnimalRepository      _animals;
  final VaccinationRepository _vaccinations;

  Future<ReportData> call(ReportType type, ReportFilter filter) async {
    final (start, end) = filter.dateRange;
    return switch (type) {
      ReportType.sanitary     => _sanitary(filter, start, end),
      ReportType.reproductive => _reproductive(start, end),
      ReportType.financial    => _financial(start, end),
      ReportType.inventory    => _inventory(start, end),
    };
  }

  // ── Sanitário ──────────────────────────────────────────────────────────────

  Future<ReportData> _sanitary(
    ReportFilter filter,
    DateTime start,
    DateTime end,
  ) async {
    final animals  = await _animals.getAll();
    final animalMap = {for (final a in animals) a.id: a};
    final allVacs  = await _vaccinations.getAll();

    final rows = allVacs
        .where((v) =>
            !v.date.isBefore(start) && !v.date.isAfter(end))
        .map((v) {
          final a        = animalMap[v.animalId];
          final carencia = v.quarantineDays > 0
              ? v.date.add(Duration(days: v.quarantineDays)).toBrDate
              : '—';
          return [
            a?.displayName ?? v.animalId,
            v.vaccineName,
            v.dose,
            v.date.toBrDate,
            carencia,
            v.lot ?? '—',
          ];
        })
        .toList();

    return ReportData(
      type:         ReportType.sanitary,
      headers:      ['Animal', 'Vacina', 'Dose', 'Data', 'Carência', 'Lote'],
      rows:         rows,
      generatedAt:  DateTime.now(),
      periodStart:  start,
      periodEnd:    end,
    );
  }

  // ── Reprodutivo ────────────────────────────────────────────────────────────

  Future<ReportData> _reproductive(DateTime start, DateTime end) async {
    final animals = await _animals.getAll();

    final rows = animals
        .where((a) =>
            a.status == AnimalStatus.pregnant ||
            a.pregnancyDate != null)
        .map((a) {
          final days     = a.pregnancyDays;
          final expected = a.expectedBirthDate;
          return [
            a.displayName,
            a.status.label,
            if (a.pregnancyDate != null) a.pregnancyDate!.toBrDate else '—',
            if (expected != null) expected.toBrDate else '—',
            if (days > 0) '$days dias' else '—',
          ];
        })
        .toList();

    return ReportData(
      type:        ReportType.reproductive,
      headers:     ['Animal', 'Status', 'Cobertura', 'Parto previsto', 'Gestação'],
      rows:        rows,
      generatedAt: DateTime.now(),
      periodStart: start,
      periodEnd:   end,
    );
  }

  // ── Financeiro ─────────────────────────────────────────────────────────────

  Future<ReportData> _financial(DateTime start, DateTime end) async {
    final animals = await _animals.getAll();

    final rows = animals
        .where((a) => a.weightKg != null)
        .map((a) => [
              '#${a.earTag}',
              a.name ?? '—',
              a.breed,
              if (a.sex == AnimalSex.female) 'F' else 'M',
              '${a.weightKg!.toStringAsFixed(0)} kg',
              a.status.label,
            ])
        .toList();

    return ReportData(
      type:        ReportType.financial,
      headers:     ['Brinco', 'Nome', 'Raça', 'Sexo', 'Peso', 'Status'],
      rows:        rows,
      generatedAt: DateTime.now(),
      periodStart: start,
      periodEnd:   end,
    );
  }

  // ── Inventário ─────────────────────────────────────────────────────────────

  Future<ReportData> _inventory(DateTime start, DateTime end) async {
    final animals = await _animals.getAll();

    final rows = animals
        .map((a) => [
              '#${a.earTag}',
              a.name ?? '—',
              a.breed,
              if (a.sex == AnimalSex.female) 'F' else 'M',
              if (a.ageInYears > 0)
                '${a.ageInYears} ${a.ageInYears == 1 ? 'ano' : 'anos'}'
              else
                '${a.ageInMonths} meses',
              if (a.weightKg != null) '${a.weightKg!.toStringAsFixed(0)} kg' else '—',
              a.status.label,
            ])
        .toList();

    return ReportData(
      type:        ReportType.inventory,
      headers:     ['Brinco', 'Nome', 'Raça', 'Sexo', 'Idade', 'Peso', 'Status'],
      rows:        rows,
      generatedAt: DateTime.now(),
      periodStart: start,
      periodEnd:   end,
    );
  }
}
