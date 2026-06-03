import '../../domain/entities/weighing.dart';
import '../../domain/repositories/weighing_repository.dart';
import '../datasources/weighing_firestore_data_source.dart';
import '../models/weighing_model.dart';

class WeighingRepositoryImpl implements WeighingRepository {
  const WeighingRepositoryImpl(this._dataSource);
  final WeighingFirestoreDataSource _dataSource;

  @override
  Future<List<Weighing>> getByAnimal(String animalId) async {
    final models = await _dataSource.getByAnimal(animalId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> add(Weighing weighing) =>
      _dataSource.add(WeighingModel.fromEntity(weighing));
}
