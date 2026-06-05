import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/extensions/num_ext.dart';
import '../../../herd/domain/entities/animal_entity.dart';
import '../../../herd/domain/entities/sale_record.dart';
import '../../../herd/domain/repositories/animal_repository.dart';
import '../../../herd/domain/repositories/sale_repository.dart';
import '../../../vaccination/domain/repositories/vaccination_repository.dart';
import '../../../weighing/domain/entities/weighing.dart';
import '../../../weighing/domain/repositories/weighing_repository.dart';
import '../entities/report_data.dart';

/// Arroba em quilos (padrão da pecuária de corte).
const double _kgPerArroba = 15;

/// Agrega dados do Firestore (animais, vacinações, vendas, pesagens) e
/// devolve um [ReportData].
class GenerateReportUseCase {
  const GenerateReportUseCase(
    this._animals,
    this._vaccinations,
    this._sales,
    this._weighings,
  );

  final AnimalRepository      _animals;
  final VaccinationRepository _vaccinations;
  final SaleRepository        _sales;
  final WeighingRepository    _weighings;

  Future<ReportData> call(ReportType type, ReportFilter filter) async {
    final (start, end) = filter.dateRange;
    return switch (type) {
      ReportType.sanitary     => _sanitary(filter, start, end),
      ReportType.reproductive => _reproductive(start, end),
      ReportType.financial    => _financial(start, end),
      ReportType.sales        => _salesReport(start, end),
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

  // ── Financeiro (com ganho de peso / GMD) ────────────────────────────────────

  Future<ReportData> _financial(DateTime start, DateTime end) async {
    final animals =
        (await _animals.getAll()).where((a) => a.weightKg != null).toList();

    // Ganho médio diário por cabeça — uma consulta de pesagens por animal,
    // resolvidas em paralelo. Fonte: coleção `weighings` (M3).
    final gmds = await Future.wait(
      animals.map((a) async => (await _weighings.getByAnimal(a.id)).gmd),
    );

    final rows = [
      for (var i = 0; i < animals.length; i++)
        () {
          final a   = animals[i];
          final gmd = gmds[i];
          return [
            '#${a.earTag}',
            a.name ?? '—',
            a.breed,
            if (a.sex == AnimalSex.female) 'F' else 'M',
            '${a.weightKg!.toStringAsFixed(0)} kg',
            if (gmd != null) '${gmd.toStringAsFixed(3)} kg/dia' else '—',
            a.status.label,
          ];
        }(),
    ];

    return ReportData(
      type:        ReportType.financial,
      headers:     ['Brinco', 'Nome', 'Raça', 'Sexo', 'Peso', 'GMD', 'Status'],
      rows:        rows,
      generatedAt: DateTime.now(),
      periodStart: start,
      periodEnd:   end,
    );
  }

  // ── Vendas ──────────────────────────────────────────────────────────────────

  Future<ReportData> _salesReport(DateTime start, DateTime end) async {
    final sales = (await _sales.getAll())
        .where((s) => !s.date.isBefore(start) && !s.date.isAfter(end))
        .toList();

    final rows = sales.map((s) {
      final pricePerArroba = _pricePerArroba(s);
      return [
        s.date.toBrDate,
        s.buyer ?? '—',
        '${s.headCount}',
        if (s.totalWeightKg != null)
          '${s.totalWeightKg!.toStringAsFixed(0)} kg'
        else
          '—',
        s.totalValue.toBrl,
        s.valuePerHead.toBrl,
        if (pricePerArroba != null) pricePerArroba.toBrl else '—',
      ];
    }).toList();

    // Totais do período (cálculo no domínio, não na UI).
    final totalValue  = sales.fold<double>(0, (sum, s) => sum + s.totalValue);
    final totalHeads  = sales.fold<int>(0, (sum, s) => sum + s.headCount);
    final totalWeight =
        sales.fold<double>(0, (sum, s) => sum + (s.totalWeightKg ?? 0));
    // Média ponderada de R$/@ = valor total ÷ arrobas totais.
    final totalArrobas        = totalWeight / _kgPerArroba;
    final avgPricePerArroba   = totalArrobas > 0 ? totalValue / totalArrobas : null;

    final footer = sales.isEmpty
        ? null
        : [
            'TOTAL',
            '',
            '$totalHeads',
            if (totalWeight > 0) '${totalWeight.toStringAsFixed(0)} kg' else '—',
            totalValue.toBrl,
            '',
            if (avgPricePerArroba != null) avgPricePerArroba.toBrl else '—',
          ];

    return ReportData(
      type:    ReportType.sales,
      headers: [
        'Data',
        'Comprador',
        'Cabeças',
        'Peso',
        'Valor total',
        r'R$/cab.',
        r'R$/@',
      ],
      rows:        rows,
      footer:      footer,
      generatedAt: DateTime.now(),
      periodStart: start,
      periodEnd:   end,
    );
  }

  /// R$/@ efetivo da venda: usa o informado ou deriva de valor ÷ arrobas.
  double? _pricePerArroba(SaleRecord s) {
    if (s.pricePerArroba != null) return s.pricePerArroba;
    final weight = s.totalWeightKg;
    if (weight == null || weight <= 0) return null;
    return s.totalValue / (weight / _kgPerArroba);
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
