import '../../../herd/domain/entities/animal_entity.dart';
import '../entities/health_event.dart';

abstract interface class HealthEventRepository {
  /// Eventos de um animal, do mais recente para o mais antigo.
  Future<List<HealthEvent>> getByAnimal(String animalId);

  /// Todos os eventos do usuário, do mais recente para o mais antigo.
  Future<List<HealthEvent>> getAll();

  /// Registra um tratamento ou observação.
  Future<void> add(HealthEvent event);

  /// Registra a prenhez e marca o animal como prenhe (atômico).
  Future<void> registerPregnancy({
    required HealthEvent event,
    required DateTime coverageDate,
  });

  /// Registra o parto: encerra a gestação e, opcionalmente, cadastra o
  /// bezerro — tudo no mesmo batch.
  Future<void> registerBirth({required HealthEvent event, AnimalEntity? calf});

  /// Registra perda gestacional e encerra a gestação (atômico).
  Future<void> registerPregnancyLoss(HealthEvent event);
}
