import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardStatsUseCase {
  const GetDashboardStatsUseCase(this._repository);
  final DashboardRepository _repository;

  Future<DashboardStats> call() => _repository.getStats();
}
