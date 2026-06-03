import '../entities/vet_entity.dart';
import '../repositories/vet_repository.dart';

class GetVetByIdUseCase {
  const GetVetByIdUseCase(this._repository);
  final VetRepository _repository;

  Future<VetEntity?> call(String id) => _repository.getById(id);
}
