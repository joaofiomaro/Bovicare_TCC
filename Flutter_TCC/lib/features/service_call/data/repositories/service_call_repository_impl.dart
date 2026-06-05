import '../../domain/entities/service_call.dart';
import '../../domain/repositories/service_call_repository.dart';
import '../datasources/service_call_firestore_data_source.dart';
import '../models/service_call_model.dart';

class ServiceCallRepositoryImpl implements ServiceCallRepository {
  const ServiceCallRepositoryImpl(this._dataSource);
  final ServiceCallFirestoreDataSource _dataSource;

  @override
  Future<ServiceCall> create(ServiceCall call) async {
    final model =
        await _dataSource.create(ServiceCallModel.fromEntity(call));
    return model.toEntity();
  }

  @override
  Future<List<ServiceCall>> getOpen() async =>
      (await _dataSource.getOpen()).map((m) => m.toEntity()).toList();

  @override
  Future<List<ServiceCall>> getForVet(String vetId) async =>
      (await _dataSource.getForVet(vetId)).map((m) => m.toEntity()).toList();

  @override
  Future<List<ServiceCall>> getForProducer(String producerId) async =>
      (await _dataSource.getForProducer(producerId))
          .map((m) => m.toEntity())
          .toList();

  @override
  Future<void> accept({
    required String callId,
    required String vetId,
    required String vetName,
  }) =>
      _dataSource.accept(callId: callId, vetId: vetId, vetName: vetName);

  @override
  Future<void> updateStatus({
    required String callId,
    required ServiceStatus status,
    DateTime? scheduledDate,
    String? resolution,
  }) =>
      _dataSource.updateStatus(
        callId: callId,
        status: status,
        scheduledDate: scheduledDate,
        resolution: resolution,
      );

  @override
  Future<void> cancel(String callId) => _dataSource.cancel(callId);
}
