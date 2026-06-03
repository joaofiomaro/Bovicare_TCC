import '../repositories/animal_repository.dart';

class RecordAnimalDeathUseCase {
  const RecordAnimalDeathUseCase(this._repository);
  final AnimalRepository _repository;

  Future<void> call({
    required List<String> animalIds,
    required DateTime date,
    String? cause,
    String? notes,
  }) {
    if (animalIds.isEmpty) {
      throw ArgumentError('Informe ao menos um animal.');
    }
    if (animalIds.toSet().length != animalIds.length) {
      throw ArgumentError('Lista de animais com duplicatas.');
    }
    return _repository.recordDeath(
      animalIds: animalIds,
      date: date,
      cause: cause,
      notes: notes,
    );
  }
}
