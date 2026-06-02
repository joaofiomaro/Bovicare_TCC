import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_stats.dart';

/// Fonte de dados local do dashboard.
/// TODO(fase-5): substituir dados mock por leitura real do Hive (`Box<AnimalModel>`).
class DashboardLocalDataSource {
  Future<DashboardStats> getStats() async {
    return const DashboardStats(
      totalAnimals:         127,
      pregnantCount:        18,
      alertCount:           3,
      upcomingVaccinations: 12,
      alertMessage: '3 vacinas vencem em 7 dias',
      alertDetail:  'Estrela #031, Bela #058 e mais 1',
    );
  }

  Future<List<ActivityItem>> getRecentActivities() async {
    final now = DateTime.now();
    return [
      ActivityItem(
        type:     ActivityType.vaccination,
        title:    'Vacinação em lote — Aftosa',
        subtitle: '12 animais',
        date:     DateTime(now.year, now.month, now.day, 8, 14),
      ),
      ActivityItem(
        type:  ActivityType.birth,
        title: 'Parto — Mimosa #047',
        date:  DateTime(now.year, now.month, now.day - 1, 16, 32),
      ),
      ActivityItem(
        type:  ActivityType.brete,
        title: 'Brete · Ciclo abrir/fechar',
        date:  DateTime(now.year, now.month, now.day - 1, 14, 10),
      ),
    ];
  }
}
