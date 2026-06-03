import '../entities/animal_entity.dart';

abstract interface class AnimalRepository {
  Future<List<AnimalEntity>> getAll();
  Future<AnimalEntity?>      getById(String id);
  Future<void>               save(AnimalEntity animal);
  Future<void>               delete(String id);

  /// Registra óbito de um ou mais animais (baixa por morte), atomicamente.
  Future<void> recordDeath({
    required List<String> animalIds,
    required DateTime date,
    String? cause,
    String? notes,
  });
}
