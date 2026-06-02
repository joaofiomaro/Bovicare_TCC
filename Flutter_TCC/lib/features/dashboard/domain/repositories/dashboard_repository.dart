import '../entities/activity_item.dart';
import '../entities/dashboard_stats.dart';

abstract interface class DashboardRepository {
  Future<DashboardStats> getStats();
  Future<List<ActivityItem>> getRecentActivities();
}
