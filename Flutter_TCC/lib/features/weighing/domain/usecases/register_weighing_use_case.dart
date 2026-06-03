import '../entities/weighing.dart';
import '../repositories/weighing_repository.dart';

class RegisterWeighingUseCase {
  const RegisterWeighingUseCase(this._repository);
  final WeighingRepository _repository;

  Future<void> call(Weighing weighing) => _repository.add(weighing);
}
