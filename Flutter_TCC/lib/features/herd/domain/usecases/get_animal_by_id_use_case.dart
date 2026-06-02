import '../entities/animal_entity.dart';
import '../repositories/animal_repository.dart';

class GetAnimalByIdUseCase {
  const GetAnimalByIdUseCase(this._repository);
  final AnimalRepository _repository;

  Future<AnimalEntity?> call(String id) => _repository.getById(id);
}
