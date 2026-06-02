import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats.freezed.dart';

@freezed
class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    required int totalAnimals,
    required int pregnantCount,
    required int alertCount,
    required int upcomingVaccinations,
    /// Título do banner de alerta (ex: "3 vacinas vencem em 7 dias").
    String? alertMessage,
    /// Detalhe adicional do alerta.
    String? alertDetail,
  }) = _DashboardStats;
}
