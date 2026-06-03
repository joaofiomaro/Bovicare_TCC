import '../entities/vet_entity.dart';

abstract interface class VetRepository {
  Future<List<VetEntity>> getAll();
  Future<VetEntity?>      getById(String id);
}
