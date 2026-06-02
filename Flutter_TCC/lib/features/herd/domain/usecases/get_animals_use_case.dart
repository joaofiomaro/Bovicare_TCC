import '../entities/animal_entity.dart';
import '../repositories/animal_repository.dart';

class GetAnimalsUseCase {
  const GetAnimalsUseCase(this._repository);
  final AnimalRepository _repository;

  Future<List<AnimalEntity>> call() => _repository.getAll();
}
