// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'animal_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AnimalEntity {
  String get id => throw _privateConstructorUsedError;
  String get earTag => throw _privateConstructorUsedError;
  String get breed => throw _privateConstructorUsedError;
  AnimalSex get sex => throw _privateConstructorUsedError;
  DateTime get birthDate => throw _privateConstructorUsedError;
  AnimalStatus get status => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  double? get weightKg => throw _privateConstructorUsedError;
  String? get rfid => throw _privateConstructorUsedError;

  /// Data de cobertura/inseminação — usada para calcular progresso da prenhez.
  DateTime? get pregnancyDate => throw _privateConstructorUsedError;

  /// Create a copy of AnimalEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnimalEntityCopyWith<AnimalEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnimalEntityCopyWith<$Res> {
  factory $AnimalEntityCopyWith(
    AnimalEntity value,
    $Res Function(AnimalEntity) then,
  ) = _$AnimalEntityCopyWithImpl<$Res, AnimalEntity>;
  @useResult
  $Res call({
    String id,
    String earTag,
    String breed,
    AnimalSex sex,
    DateTime birthDate,
    AnimalStatus status,
    String? name,
    double? weightKg,
    String? rfid,
    DateTime? pregnancyDate,
  });
}

/// @nodoc
class _$AnimalEntityCopyWithImpl<$Res, $Val extends AnimalEntity>
    implements $AnimalEntityCopyWith<$Res> {
  _$AnimalEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnimalEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? earTag = null,
    Object? breed = null,
    Object? sex = null,
    Object? birthDate = null,
    Object? status = null,
    Object? name = freezed,
    Object? weightKg = freezed,
    Object? rfid = freezed,
    Object? pregnancyDate = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            earTag: null == earTag
                ? _value.earTag
                : earTag // ignore: cast_nullable_to_non_nullable
                      as String,
            breed: null == breed
                ? _value.breed
                : breed // ignore: cast_nullable_to_non_nullable
                      as String,
            sex: null == sex
                ? _value.sex
                : sex // ignore: cast_nullable_to_non_nullable
                      as AnimalSex,
            birthDate: null == birthDate
                ? _value.birthDate
                : birthDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as AnimalStatus,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            weightKg: freezed == weightKg
                ? _value.weightKg
                : weightKg // ignore: cast_nullable_to_non_nullable
                      as double?,
            rfid: freezed == rfid
                ? _value.rfid
                : rfid // ignore: cast_nullable_to_non_nullable
                      as String?,
            pregnancyDate: freezed == pregnancyDate
                ? _value.pregnancyDate
                : pregnancyDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnimalEntityImplCopyWith<$Res>
    implements $AnimalEntityCopyWith<$Res> {
  factory _$$AnimalEntityImplCopyWith(
    _$AnimalEntityImpl value,
    $Res Function(_$AnimalEntityImpl) then,
  ) = __$$AnimalEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String earTag,
    String breed,
    AnimalSex sex,
    DateTime birthDate,
    AnimalStatus status,
    String? name,
    double? weightKg,
    String? rfid,
    DateTime? pregnancyDate,
  });
}

/// @nodoc
class __$$AnimalEntityImplCopyWithImpl<$Res>
    extends _$AnimalEntityCopyWithImpl<$Res, _$AnimalEntityImpl>
    implements _$$AnimalEntityImplCopyWith<$Res> {
  __$$AnimalEntityImplCopyWithImpl(
    _$AnimalEntityImpl _value,
    $Res Function(_$AnimalEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AnimalEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? earTag = null,
    Object? breed = null,
    Object? sex = null,
    Object? birthDate = null,
    Object? status = null,
    Object? name = freezed,
    Object? weightKg = freezed,
    Object? rfid = freezed,
    Object? pregnancyDate = freezed,
  }) {
    return _then(
      _$AnimalEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        earTag: null == earTag
            ? _value.earTag
            : earTag // ignore: cast_nullable_to_non_nullable
                  as String,
        breed: null == breed
            ? _value.breed
            : breed // ignore: cast_nullable_to_non_nullable
                  as String,
        sex: null == sex
            ? _value.sex
            : sex // ignore: cast_nullable_to_non_nullable
                  as AnimalSex,
        birthDate: null == birthDate
            ? _value.birthDate
            : birthDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as AnimalStatus,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        weightKg: freezed == weightKg
            ? _value.weightKg
            : weightKg // ignore: cast_nullable_to_non_nullable
                  as double?,
        rfid: freezed == rfid
            ? _value.rfid
            : rfid // ignore: cast_nullable_to_non_nullable
                  as String?,
        pregnancyDate: freezed == pregnancyDate
            ? _value.pregnancyDate
            : pregnancyDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$AnimalEntityImpl implements _AnimalEntity {
  const _$AnimalEntityImpl({
    required this.id,
    required this.earTag,
    required this.breed,
    required this.sex,
    required this.birthDate,
    required this.status,
    this.name,
    this.weightKg,
    this.rfid,
    this.pregnancyDate,
  });

  @override
  final String id;
  @override
  final String earTag;
  @override
  final String breed;
  @override
  final AnimalSex sex;
  @override
  final DateTime birthDate;
  @override
  final AnimalStatus status;
  @override
  final String? name;
  @override
  final double? weightKg;
  @override
  final String? rfid;

  /// Data de cobertura/inseminação — usada para calcular progresso da prenhez.
  @override
  final DateTime? pregnancyDate;

  @override
  String toString() {
    return 'AnimalEntity(id: $id, earTag: $earTag, breed: $breed, sex: $sex, birthDate: $birthDate, status: $status, name: $name, weightKg: $weightKg, rfid: $rfid, pregnancyDate: $pregnancyDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnimalEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.earTag, earTag) || other.earTag == earTag) &&
            (identical(other.breed, breed) || other.breed == breed) &&
            (identical(other.sex, sex) || other.sex == sex) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.rfid, rfid) || other.rfid == rfid) &&
            (identical(other.pregnancyDate, pregnancyDate) ||
                other.pregnancyDate == pregnancyDate));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    earTag,
    breed,
    sex,
    birthDate,
    status,
    name,
    weightKg,
    rfid,
    pregnancyDate,
  );

  /// Create a copy of AnimalEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnimalEntityImplCopyWith<_$AnimalEntityImpl> get copyWith =>
      __$$AnimalEntityImplCopyWithImpl<_$AnimalEntityImpl>(this, _$identity);
}

abstract class _AnimalEntity implements AnimalEntity {
  const factory _AnimalEntity({
    required final String id,
    required final String earTag,
    required final String breed,
    required final AnimalSex sex,
    required final DateTime birthDate,
    required final AnimalStatus status,
    final String? name,
    final double? weightKg,
    final String? rfid,
    final DateTime? pregnancyDate,
  }) = _$AnimalEntityImpl;

  @override
  String get id;
  @override
  String get earTag;
  @override
  String get breed;
  @override
  AnimalSex get sex;
  @override
  DateTime get birthDate;
  @override
  AnimalStatus get status;
  @override
  String? get name;
  @override
  double? get weightKg;
  @override
  String? get rfid;

  /// Data de cobertura/inseminação — usada para calcular progresso da prenhez.
  @override
  DateTime? get pregnancyDate;

  /// Create a copy of AnimalEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnimalEntityImplCopyWith<_$AnimalEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
