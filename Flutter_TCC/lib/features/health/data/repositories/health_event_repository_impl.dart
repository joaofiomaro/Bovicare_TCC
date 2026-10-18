import '../../../herd/data/models/animal_model.dart';
import '../../../herd/domain/entities/animal_entity.dart';
import '../../domain/entities/health_event.dart';
import '../../domain/repositories/health_event_repository.dart';
import '../datasources/health_event_firestore_data_source.dart';

class HealthEventRepositoryImpl implements HealthEventRepository {
  const HealthEventRepositoryImpl(this._dataSource);
  final HealthEventFirestoreDataSource _dataSource;

  @override
  Future<List<HealthEvent>> getByAnimal(String animalId) =>
      _dataSource.getByAnimal(animalId);

  @override
  Future<List<HealthEvent>> getAll() => _dataSource.getAll();

  @override
  Future<void> add(HealthEvent event) => _dataSource.add(event);

  @override
  Future<void> registerPregnancy({
    required HealthEvent event,
    required DateTime coverageDate,
  }) =>
      _dataSource.registerPregnancy(event: event, coverageDate: coverageDate);

  @override
  Future<void> registerBirth({required HealthEvent event, AnimalEntity? calf}) =>
      _dataSource.registerBirth(
        event: event,
        calf: calf == null ? null : AnimalModel.fromEntity(calf),
      );

  @override
  Future<void> registerPregnancyLoss(HealthEvent event) =>
      _dataSource.registerPregnancyLoss(event);
}
