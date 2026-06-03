import '../entities/weighing.dart';

abstract interface class WeighingRepository {
  /// Pesagens de um animal, da mais recente para a mais antiga.
  Future<List<Weighing>> getByAnimal(String animalId);

  /// Registra uma pesagem e atualiza o peso atual do animal (atômico).
  Future<void> add(Weighing weighing);
}
