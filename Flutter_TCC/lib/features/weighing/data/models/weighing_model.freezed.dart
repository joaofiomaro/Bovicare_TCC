// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weighing_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WeighingModel _$WeighingModelFromJson(Map<String, dynamic> json) {
  return _WeighingModel.fromJson(json);
}

/// @nodoc
mixin _$WeighingModel {
  String get id => throw _privateConstructorUsedError;
  String get animalId => throw _privateConstructorUsedError;
  double get weightKg => throw _privateConstructorUsedError;
  String get dateIso => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this WeighingModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WeighingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WeighingModelCopyWith<WeighingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeighingModelCopyWith<$Res> {
  factory $WeighingModelCopyWith(
    WeighingModel value,
    $Res Function(WeighingModel) then,
  ) = _$WeighingModelCopyWithImpl<$Res, WeighingModel>;
  @useResult
  $Res call({
    String id,
    String animalId,
    double weightKg,
    String dateIso,
    String? notes,
  });
}

/// @nodoc
class _$WeighingModelCopyWithImpl<$Res, $Val extends WeighingModel>
    implements $WeighingModelCopyWith<$Res> {
  _$WeighingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WeighingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? animalId = null,
    Object? weightKg = null,
    Object? dateIso = null,
    Object? notes = freezed,
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
            weightKg: null == weightKg
                ? _value.weightKg
                : weightKg // ignore: cast_nullable_to_non_nullable
                      as double,
            dateIso: null == dateIso
                ? _value.dateIso
                : dateIso // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WeighingModelImplCopyWith<$Res>
    implements $WeighingModelCopyWith<$Res> {
  factory _$$WeighingModelImplCopyWith(
    _$WeighingModelImpl value,
    $Res Function(_$WeighingModelImpl) then,
  ) = __$$WeighingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String animalId,
    double weightKg,
    String dateIso,
    String? notes,
  });
}

/// @nodoc
class __$$WeighingModelImplCopyWithImpl<$Res>
    extends _$WeighingModelCopyWithImpl<$Res, _$WeighingModelImpl>
    implements _$$WeighingModelImplCopyWith<$Res> {
  __$$WeighingModelImplCopyWithImpl(
    _$WeighingModelImpl _value,
    $Res Function(_$WeighingModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WeighingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? animalId = null,
    Object? weightKg = null,
    Object? dateIso = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$WeighingModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        animalId: null == animalId
            ? _value.animalId
            : animalId // ignore: cast_nullable_to_non_nullable
                  as String,
        weightKg: null == weightKg
            ? _value.weightKg
            : weightKg // ignore: cast_nullable_to_non_nullable
                  as double,
        dateIso: null == dateIso
            ? _value.dateIso
            : dateIso // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WeighingModelImpl extends _WeighingModel {
  const _$WeighingModelImpl({
    required this.id,
    required this.animalId,
    required this.weightKg,
    required this.dateIso,
    this.notes,
  }) : super._();

  factory _$WeighingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeighingModelImplFromJson(json);

  @override
  final String id;
  @override
  final String animalId;
  @override
  final double weightKg;
  @override
  final String dateIso;
  @override
  final String? notes;

  @override
  String toString() {
    return 'WeighingModel(id: $id, animalId: $animalId, weightKg: $weightKg, dateIso: $dateIso, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeighingModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.animalId, animalId) ||
                other.animalId == animalId) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.dateIso, dateIso) || other.dateIso == dateIso) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, animalId, weightKg, dateIso, notes);

  /// Create a copy of WeighingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WeighingModelImplCopyWith<_$WeighingModelImpl> get copyWith =>
      __$$WeighingModelImplCopyWithImpl<_$WeighingModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeighingModelImplToJson(this);
  }
}

abstract class _WeighingModel extends WeighingModel {
  const factory _WeighingModel({
    required final String id,
    required final String animalId,
    required final double weightKg,
    required final String dateIso,
    final String? notes,
  }) = _$WeighingModelImpl;
  const _WeighingModel._() : super._();

  factory _WeighingModel.fromJson(Map<String, dynamic> json) =
      _$WeighingModelImpl.fromJson;

  @override
  String get id;
  @override
  String get animalId;
  @override
  double get weightKg;
  @override
  String get dateIso;
  @override
  String? get notes;

  /// Create a copy of WeighingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WeighingModelImplCopyWith<_$WeighingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
