import '../../domain/entities/vet_entity.dart';
import '../../domain/repositories/vet_repository.dart';
import '../datasources/vet_local_data_source.dart';

class VetRepositoryImpl implements VetRepository {
  const VetRepositoryImpl(this._dataSource);
  final VetLocalDataSource _dataSource;

  @override
  Future<List<VetEntity>> getAll() async {
    final models = await _dataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<VetEntity?> getById(String id) async {
    final model = await _dataSource.getById(id);
    return model?.toEntity();
  }
}
