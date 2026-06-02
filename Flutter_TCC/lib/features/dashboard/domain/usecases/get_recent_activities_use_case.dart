import '../entities/activity_item.dart';
import '../repositories/dashboard_repository.dart';

class GetRecentActivitiesUseCase {
  const GetRecentActivitiesUseCase(this._repository);
  final DashboardRepository _repository;

  Future<List<ActivityItem>> call() => _repository.getRecentActivities();
}
