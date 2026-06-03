import '../entities/vaccination_record.dart';
import '../repositories/vaccination_repository.dart';

class GetAnimalVaccinationsUseCase {
  const GetAnimalVaccinationsUseCase(this._repository);
  final VaccinationRepository _repository;

  Future<List<VaccinationRecord>> call(String animalId) =>
      _repository.getByAnimal(animalId);
}
