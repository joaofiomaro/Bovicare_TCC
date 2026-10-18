import '../entities/vet_entity.dart';

/// Prefixo dos veterinários demonstrativos (dados fixos do protótipo).
const String kDemoVetIdPrefix = 'demo-';

extension VetEntityDemoX on VetEntity {
  /// `true` para os perfis fictícios usados na demonstração do TCC.
  bool get isDemo => id.startsWith(kDemoVetIdPrefix);
}

abstract interface class VetRepository {
  /// Veterinários com perfil público publicado + perfis demonstrativos.
  Future<List<VetEntity>> getAll();
  Future<VetEntity?>      getById(String id);

  /// Perfil profissional do veterinário logado (null se não publicado).
  Future<VetEntity?> getMyProfile(String uid);

  /// Publica/atualiza o perfil profissional (id = uid do veterinário).
  Future<void> saveMyProfile(VetEntity profile);

  /// Remove o perfil do diretório público.
  Future<void> deleteMyProfile(String uid);
}
