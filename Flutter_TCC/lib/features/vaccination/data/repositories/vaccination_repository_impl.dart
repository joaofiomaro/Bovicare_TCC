import '../../domain/entities/vaccination_record.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../datasources/vaccination_local_data_source.dart';
import '../models/vaccination_model.dart';

class VaccinationRepositoryImpl implements VaccinationRepository {
  const VaccinationRepositoryImpl(this._dataSource);
  final VaccinationLocalDataSource _dataSource;

  @override
  Future<List<VaccinationRecord>> getAll() async {
    final models = await _dataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<VaccinationRecord>> getByAnimal(String animalId) async {
    final models = await _dataSource.getByAnimal(animalId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> save(VaccinationRecord record) =>
      _dataSource.save(VaccinationModel.fromEntity(record));

  @override
  Future<void> delete(String id) => _dataSource.delete(id);
}
