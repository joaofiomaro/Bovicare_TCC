import '../../../../core/errors/failures.dart';
import '../../domain/entities/vet_entity.dart';
import '../../domain/repositories/vet_repository.dart';
import '../datasources/vet_firestore_data_source.dart';
import '../datasources/vet_in_memory_data_source.dart';
import '../models/vet_model.dart';

/// Combina os perfis publicados no Firestore com os demonstrativos.
class VetRepositoryImpl implements VetRepository {
  const VetRepositoryImpl(this._remote, this._demo);

  final VetFirestoreDataSource _remote;
  final VetInMemoryDataSource  _demo;

  @override
  Future<List<VetEntity>> getAll() async {
    final demo = await _demo.getAll();
    List<VetModel> published;
    try {
      published = await _remote.getAll();
    } on Failure {
      // Sem conexão e sem cache: mantém ao menos o diretório demonstrativo
      // em vez de deixar a tela vazia.
      published = const [];
    }
    return [...published, ...demo].map((m) => m.toEntity()).toList();
  }

  @override
  Future<VetEntity?> getById(String id) async {
    final model = id.startsWith(kDemoVetIdPrefix)
        ? await _demo.getById(id)
        : await _remote.getById(id);
    return model?.toEntity();
  }

  @override
  Future<VetEntity?> getMyProfile(String uid) async =>
      (await _remote.getById(uid))?.toEntity();

  @override
  Future<void> saveMyProfile(VetEntity profile) =>
      _remote.save(VetModel.fromEntity(profile));

  @override
  Future<void> deleteMyProfile(String uid) => _remote.delete(uid);
}
