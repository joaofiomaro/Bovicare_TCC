import '../entities/animal_entity.dart';

abstract interface class AnimalRepository {
  Future<List<AnimalEntity>> getAll();
  Future<AnimalEntity?>      getById(String id);
  Future<void>               save(AnimalEntity animal);
  Future<void>               delete(String id);
}
