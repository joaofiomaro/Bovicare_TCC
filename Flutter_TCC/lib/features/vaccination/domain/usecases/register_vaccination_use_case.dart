import '../entities/vaccination_record.dart';
import '../repositories/vaccination_repository.dart';

class RegisterVaccinationUseCase {
  const RegisterVaccinationUseCase(this._repository);
  final VaccinationRepository _repository;

  Future<void> call(VaccinationRecord record) => _repository.save(record);
}
