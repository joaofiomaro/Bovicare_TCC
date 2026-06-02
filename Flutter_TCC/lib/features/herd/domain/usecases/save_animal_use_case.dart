import '../entities/animal_entity.dart';
import '../repositories/animal_repository.dart';

/// Handles both add and update — repository uses upsert semantics.
class SaveAnimalUseCase {
  const SaveAnimalUseCase(this._repository);
  final AnimalRepository _repository;

  Future<void> call(AnimalEntity animal) => _repository.save(animal);
}
