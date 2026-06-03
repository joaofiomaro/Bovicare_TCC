// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vaccination_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VaccinationModel _$VaccinationModelFromJson(Map<String, dynamic> json) {
  return _VaccinationModel.fromJson(json);
}

/// @nodoc
mixin _$VaccinationModel {
  String get id => throw _privateConstructorUsedError;
  String get animalId => throw _privateConstructorUsedError;
  String get vaccineName => throw _privateConstructorUsedError;
  String get dose => throw _privateConstructorUsedError;
  String get dateIso => throw _privateConstructorUsedError;
  int get quarantineDays => throw _privateConstructorUsedError;
  String? get lot => throw _privateConstructorUsedError;
  String? get veterinarianName => throw _privateConstructorUsedError;
  String? get nextDoseDateIso => throw _privateConstructorUsedError;

  /// Serializes this VaccinationModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VaccinationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VaccinationModelCopyWith<VaccinationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VaccinationModelCopyWith<$Res> {
  factory $VaccinationModelCopyWith(
    VaccinationModel value,
    $Res Function(VaccinationModel) then,
  ) = _$VaccinationModelCopyWithImpl<$Res, VaccinationModel>;
  @useResult
  $Res call({
    String id,
    String animalId,
    String vaccineName,
    String dose,
    String dateIso,
    int quarantineDays,
    String? lot,
    String? veterinarianName,
    String? nextDoseDateIso,
  });
}

/// @nodoc
class _$VaccinationModelCopyWithImpl<$Res, $Val extends VaccinationModel>
    implements $VaccinationModelCopyWith<$Res> {
  _$VaccinationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VaccinationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? animalId = null,
    Object? vaccineName = null,
    Object? dose = null,
    Object? dateIso = null,
    Object? quarantineDays = null,
    Object? lot = freezed,
    Object? veterinarianName = freezed,
    Object? nextDoseDateIso = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            animalId: null == animalId
                ? _value.animalId
                : animalId // ignore: cast_nullable_to_non_nullable
                      as String,
            vaccineName: null == vaccineName
                ? _value.vaccineName
                : vaccineName // ignore: cast_nullable_to_non_nullable
                      as String,
            dose: null == dose
                ? _value.dose
                : dose // ignore: cast_nullable_to_non_nullable
                      as String,
            dateIso: null == dateIso
                ? _value.dateIso
                : dateIso // ignore: cast_nullable_to_non_nullable
                      as String,
            quarantineDays: null == quarantineDays
                ? _value.quarantineDays
                : quarantineDays // ignore: cast_nullable_to_non_nullable
                      as int,
            lot: freezed == lot
                ? _value.lot
                : lot // ignore: cast_nullable_to_non_nullable
                      as String?,
            veterinarianName: freezed == veterinarianName
                ? _value.veterinarianName
                : veterinarianName // ignore: cast_nullable_to_non_nullable
                      as String?,
            nextDoseDateIso: freezed == nextDoseDateIso
                ? _value.nextDoseDateIso
                : nextDoseDateIso // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VaccinationModelImplCopyWith<$Res>
    implements $VaccinationModelCopyWith<$Res> {
  factory _$$VaccinationModelImplCopyWith(
    _$VaccinationModelImpl value,
    $Res Function(_$VaccinationModelImpl) then,
  ) = __$$VaccinationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String animalId,
    String vaccineName,
    String dose,
    String dateIso,
    int quarantineDays,
    String? lot,
    String? veterinarianName,
    String? nextDoseDateIso,
  });
}

/// @nodoc
class __$$VaccinationModelImplCopyWithImpl<$Res>
    extends _$VaccinationModelCopyWithImpl<$Res, _$VaccinationModelImpl>
    implements _$$VaccinationModelImplCopyWith<$Res> {
  __$$VaccinationModelImplCopyWithImpl(
    _$VaccinationModelImpl _value,
    $Res Function(_$VaccinationModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VaccinationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? animalId = null,
    Object? vaccineName = null,
    Object? dose = null,
    Object? dateIso = null,
    Object? quarantineDays = null,
    Object? lot = freezed,
    Object? veterinarianName = freezed,
    Object? nextDoseDateIso = freezed,
  }) {
    return _then(
      _$VaccinationModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        animalId: null == animalId
            ? _value.animalId
            : animalId // ignore: cast_nullable_to_non_nullable
                  as String,
        vaccineName: null == vaccineName
            ? _value.vaccineName
            : vaccineName // ignore: cast_nullable_to_non_nullable
                  as String,
        dose: null == dose
            ? _value.dose
            : dose // ignore: cast_nullable_to_non_nullable
                  as String,
        dateIso: null == dateIso
            ? _value.dateIso
            : dateIso // ignore: cast_nullable_to_non_nullable
                  as String,
        quarantineDays: null == quarantineDays
            ? _value.quarantineDays
            : quarantineDays // ignore: cast_nullable_to_non_nullable
                  as int,
        lot: freezed == lot
            ? _value.lot
            : lot // ignore: cast_nullable_to_non_nullable
                  as String?,
        veterinarianName: freezed == veterinarianName
            ? _value.veterinarianName
            : veterinarianName // ignore: cast_nullable_to_non_nullable
                  as String?,
        nextDoseDateIso: freezed == nextDoseDateIso
            ? _value.nextDoseDateIso
            : nextDoseDateIso // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VaccinationModelImpl extends _VaccinationModel {
  const _$VaccinationModelImpl({
    required this.id,
    required this.animalId,
    required this.vaccineName,
    required this.dose,
    required this.dateIso,
    required this.quarantineDays,
    this.lot,
    this.veterinarianName,
    this.nextDoseDateIso,
  }) : super._();

  factory _$VaccinationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VaccinationModelImplFromJson(json);

  @override
  final String id;
  @override
  final String animalId;
  @override
  final String vaccineName;
  @override
  final String dose;
  @override
  final String dateIso;
  @override
  final int quarantineDays;
  @override
  final String? lot;
  @override
  final String? veterinarianName;
  @override
  final String? nextDoseDateIso;

  @override
  String toString() {
    return 'VaccinationModel(id: $id, animalId: $animalId, vaccineName: $vaccineName, dose: $dose, dateIso: $dateIso, quarantineDays: $quarantineDays, lot: $lot, veterinarianName: $veterinarianName, nextDoseDateIso: $nextDoseDateIso)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaccinationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.animalId, animalId) ||
                other.animalId == animalId) &&
            (identical(other.vaccineName, vaccineName) ||
                other.vaccineName == vaccineName) &&
            (identical(other.dose, dose) || other.dose == dose) &&
            (identical(other.dateIso, dateIso) || other.dateIso == dateIso) &&
            (identical(other.quarantineDays, quarantineDays) ||
                other.quarantineDays == quarantineDays) &&
            (identical(other.lot, lot) || other.lot == lot) &&
            (identical(other.veterinarianName, veterinarianName) ||
                other.veterinarianName == veterinarianName) &&
            (identical(other.nextDoseDateIso, nextDoseDateIso) ||
                other.nextDoseDateIso == nextDoseDateIso));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    animalId,
    vaccineName,
    dose,
    dateIso,
    quarantineDays,
    lot,
    veterinarianName,
    nextDoseDateIso,
  );

  /// Create a copy of VaccinationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VaccinationModelImplCopyWith<_$VaccinationModelImpl> get copyWith =>
      __$$VaccinationModelImplCopyWithImpl<_$VaccinationModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VaccinationModelImplToJson(this);
  }
}

abstract class _VaccinationModel extends VaccinationModel {
  const factory _VaccinationModel({
    required final String id,
    required final String animalId,
    required final String vaccineName,
    required final String dose,
    required final String dateIso,
    required final int quarantineDays,
    final String? lot,
    final String? veterinarianName,
    final String? nextDoseDateIso,
  }) = _$VaccinationModelImpl;
  const _VaccinationModel._() : super._();

  factory _VaccinationModel.fromJson(Map<String, dynamic> json) =
      _$VaccinationModelImpl.fromJson;

  @override
  String get id;
  @override
  String get animalId;
  @override
  String get vaccineName;
  @override
  String get dose;
  @override
  String get dateIso;
  @override
  int get quarantineDays;
  @override
  String? get lot;
  @override
  String? get veterinarianName;
  @override
  String? get nextDoseDateIso;

  /// Create a copy of VaccinationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VaccinationModelImplCopyWith<_$VaccinationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
