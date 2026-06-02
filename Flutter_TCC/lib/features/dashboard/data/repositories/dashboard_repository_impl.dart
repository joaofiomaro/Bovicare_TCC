import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._dataSource);
  final DashboardLocalDataSource _dataSource;

  @override
  Future<DashboardStats> getStats() => _dataSource.getStats();

  @override
  Future<List<ActivityItem>> getRecentActivities() =>
      _dataSource.getRecentActivities();
}
