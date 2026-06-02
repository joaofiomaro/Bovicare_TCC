import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dashboard_local_data_source.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_dashboard_stats_use_case.dart';
import '../../domain/usecases/get_recent_activities_use_case.dart';

// --- DI ---

final _dashboardDataSourceProvider = Provider<DashboardLocalDataSource>(
  (_) => DashboardLocalDataSource(),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(ref.watch(_dashboardDataSourceProvider)),
);

// --- Estado ---

/// Estado combinado do dashboard — stats + atividades em uma única leitura.
class DashboardState {
  const DashboardState({required this.stats, required this.activities});
  final DashboardStats stats;
  final List<ActivityItem> activities;
}

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() => _load();

  Future<DashboardState> _load() async {
    final repo = ref.read(dashboardRepositoryProvider);

    // Busca stats e atividades em paralelo.
    final (stats, activities) = await (
      GetDashboardStatsUseCase(repo).call(),
      GetRecentActivitiesUseCase(repo).call(),
    ).wait;

    return DashboardState(stats: stats, activities: activities);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
