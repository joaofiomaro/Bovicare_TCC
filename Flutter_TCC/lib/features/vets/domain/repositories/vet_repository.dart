import '../entities/vet_entity.dart';

abstract interface class VetRepository {
  /// Veterinários com perfil público publicado.
  Future<List<VetEntity>> getAll();
  Future<VetEntity?>      getById(String id);

  /// Perfil profissional do veterinário logado (null se não publicado).
  Future<VetEntity?> getMyProfile(String uid);

  /// Publica/atualiza o perfil profissional (id = uid do veterinário).
  Future<void> saveMyProfile(VetEntity profile);

  /// Remove o perfil do diretório público.
  Future<void> deleteMyProfile(String uid);
}
