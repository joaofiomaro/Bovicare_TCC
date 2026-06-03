import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call(UserEntity updated) => _repository.updateProfile(updated);
}
