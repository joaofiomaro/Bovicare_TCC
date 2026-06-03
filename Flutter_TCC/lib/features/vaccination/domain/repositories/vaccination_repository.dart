import '../entities/vaccination_record.dart';

abstract interface class VaccinationRepository {
  Future<List<VaccinationRecord>> getAll();
  Future<List<VaccinationRecord>> getByAnimal(String animalId);
  Future<void>                    save(VaccinationRecord record);
  Future<void>                    delete(String id);
}
