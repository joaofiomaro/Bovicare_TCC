import '../../domain/entities/animal_entity.dart';
import '../../domain/repositories/animal_repository.dart';
import '../datasources/animal_local_data_source.dart';
import '../models/animal_model.dart';

class AnimalRepositoryImpl implements AnimalRepository {
  const AnimalRepositoryImpl(this._dataSource);
  final AnimalLocalDataSource _dataSource;

  @override
  Future<List<AnimalEntity>> getAll() async {
    final models = await _dataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<AnimalEntity?> getById(String id) async {
    final model = await _dataSource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<void> save(AnimalEntity animal) =>
      _dataSource.save(AnimalModel.fromEntity(animal));

  @override
  Future<void> delete(String id) => _dataSource.delete(id);
}
