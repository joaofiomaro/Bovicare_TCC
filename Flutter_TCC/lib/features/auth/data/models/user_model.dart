import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    required String role,
    String? farmName,
  }) = _UserModel;

  // Freezed exige que o construtor privado exista para permitir métodos customizados.
  // ignore: sort_unnamed_constructors_first
  const UserModel._();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        id:       entity.id,
        name:     entity.name,
        email:    entity.email,
        role:     entity.role.name,
        farmName: entity.farmName,
      );

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserModel(
      id:       doc.id,
      name:     data['name'] as String,
      email:    data['email'] as String,
      role:     data['role'] as String,
      farmName: data['farmName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name':  name,
        'email': email,
        'role':  role,
        if (farmName != null) 'farmName': farmName,
      };

  UserEntity toEntity() => UserEntity(
        id:       id,
        name:     name,
        email:    email,
        role:     role == 'vet' ? UserRole.vet : UserRole.producer,
        farmName: farmName,
      );
}
