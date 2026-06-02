import '../repositories/animal_repository.dart';

class DeleteAnimalUseCase {
  const DeleteAnimalUseCase(this._repository);
  final AnimalRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
