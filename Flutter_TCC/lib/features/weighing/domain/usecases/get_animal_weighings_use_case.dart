import '../entities/weighing.dart';
import '../repositories/weighing_repository.dart';

class GetAnimalWeighingsUseCase {
  const GetAnimalWeighingsUseCase(this._repository);
  final WeighingRepository _repository;

  Future<List<Weighing>> call(String animalId) =>
      _repository.getByAnimal(animalId);
}
