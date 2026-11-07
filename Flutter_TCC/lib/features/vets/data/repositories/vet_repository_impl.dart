import '../../domain/entities/vet_entity.dart';
import '../../domain/repositories/vet_repository.dart';
import '../datasources/vet_firestore_data_source.dart';
import '../models/vet_model.dart';

/// Veterinários com perfil público publicado no Firestore.
class VetRepositoryImpl implements VetRepository {
  const VetRepositoryImpl(this._remote);

  final VetFirestoreDataSource _remote;

  @override
  Future<List<VetEntity>> getAll() async =>
      (await _remote.getAll()).map((m) => m.toEntity()).toList();

  @override
  Future<VetEntity?> getById(String id) async =>
      (await _remote.getById(id))?.toEntity();

  @override
  Future<VetEntity?> getMyProfile(String uid) async =>
      (await _remote.getById(uid))?.toEntity();

  @override
  Future<void> saveMyProfile(VetEntity profile) =>
      _remote.save(VetModel.fromEntity(profile));

  @override
  Future<void> deleteMyProfile(String uid) => _remote.delete(uid);
}
