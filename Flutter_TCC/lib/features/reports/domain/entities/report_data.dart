/// Período de abrangência do relatório.
enum ReportPeriod {
  lastMonth,
  quarter,
  year,
  custom;

  String get label => switch (this) {
    ReportPeriod.lastMonth => 'Último mês',
    ReportPeriod.quarter   => 'Trimestre',
    ReportPeriod.year      => 'Ano',
    ReportPeriod.custom    => 'Livre',
  };
}

/// Tipo de relatório gerado.
enum ReportType {
  sanitary,
  reproductive,
  financial,
  inventory;

  String get label => switch (this) {
    ReportType.sanitary     => 'Relatório sanitário',
    ReportType.reproductive => 'Relatório reprodutivo',
    ReportType.financial    => 'Relatório financeiro',
    ReportType.inventory    => 'Inventário completo',
  };

  String get subtitle => switch (this) {
    ReportType.sanitary     => 'Vacinações, vermifugações, medicações',
    ReportType.reproductive => 'Prenhezes, partos, natalidade',
    ReportType.financial    => 'Peso de abate, valores estimados',
    ReportType.inventory    => 'Lista do rebanho com status',
  };
}

/// Filtros aplicados ao relatório.
class ReportFilter {
  const ReportFilter({
    this.period      = ReportPeriod.lastMonth,
    this.customStart,
    this.customEnd,
  });

  final ReportPeriod period;
  final DateTime?    customStart;
  final DateTime?    customEnd;

  ReportFilter copyWith({
    ReportPeriod? period,
    DateTime?     customStart,
    DateTime?     customEnd,
    bool          clearCustom = false,
  }) =>
      ReportFilter(
        period:      period      ?? this.period,
        customStart: clearCustom ? null : (customStart ?? this.customStart),
        customEnd:   clearCustom ? null : (customEnd   ?? this.customEnd),
      );

  /// Intervalo efetivo de datas com base no período selecionado.
  (DateTime start, DateTime end) get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return switch (period) {
      ReportPeriod.lastMonth => (today.subtract(const Duration(days: 30)),  today),
      ReportPeriod.quarter   => (today.subtract(const Duration(days: 90)),  today),
      ReportPeriod.year      => (today.subtract(const Duration(days: 365)), today),
      ReportPeriod.custom    => (
          customStart ?? today.subtract(const Duration(days: 30)),
          customEnd   ?? today,
        ),
    };
  }
}

/// Relatório gerado — tipo, cabeçalhos, linhas e metadados.
class ReportData {
  const ReportData({
    required this.type,
    required this.headers,
    required this.rows,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
  });

  final ReportType       type;
  final List<String>     headers;
  final List<List<String>> rows;
  final DateTime         generatedAt;
  final DateTime         periodStart;
  final DateTime         periodEnd;

  int get totalRecords => rows.length;
}
