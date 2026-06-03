import '../entities/vet_entity.dart';
import '../repositories/vet_repository.dart';

class GetVetsUseCase {
  const GetVetsUseCase(this._repository);
  final VetRepository _repository;

  Future<List<VetEntity>> call() => _repository.getAll();
}
