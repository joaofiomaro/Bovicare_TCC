// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weighing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Weighing {
  String get id => throw _privateConstructorUsedError;
  String get animalId => throw _privateConstructorUsedError;
  double get weightKg => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Create a copy of Weighing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WeighingCopyWith<Weighing> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeighingCopyWith<$Res> {
  factory $WeighingCopyWith(Weighing value, $Res Function(Weighing) then) =
      _$WeighingCopyWithImpl<$Res, Weighing>;
  @useResult
  $Res call({
    String id,
    String animalId,
    double weightKg,
    DateTime date,
    String? notes,
  });
}

/// @nodoc
class _$WeighingCopyWithImpl<$Res, $Val extends Weighing>
    implements $WeighingCopyWith<$Res> {
  _$WeighingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Weighing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? animalId = null,
    Object? weightKg = null,
    Object? date = null,
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
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
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
abstract class _$$WeighingImplCopyWith<$Res>
    implements $WeighingCopyWith<$Res> {
  factory _$$WeighingImplCopyWith(
    _$WeighingImpl value,
    $Res Function(_$WeighingImpl) then,
  ) = __$$WeighingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String animalId,
    double weightKg,
    DateTime date,
    String? notes,
  });
}

/// @nodoc
class __$$WeighingImplCopyWithImpl<$Res>
    extends _$WeighingCopyWithImpl<$Res, _$WeighingImpl>
    implements _$$WeighingImplCopyWith<$Res> {
  __$$WeighingImplCopyWithImpl(
    _$WeighingImpl _value,
    $Res Function(_$WeighingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Weighing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? animalId = null,
    Object? weightKg = null,
    Object? date = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$WeighingImpl(
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
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$WeighingImpl implements _Weighing {
  const _$WeighingImpl({
    required this.id,
    required this.animalId,
    required this.weightKg,
    required this.date,
    this.notes,
  });

  @override
  final String id;
  @override
  final String animalId;
  @override
  final double weightKg;
  @override
  final DateTime date;
  @override
  final String? notes;

  @override
  String toString() {
    return 'Weighing(id: $id, animalId: $animalId, weightKg: $weightKg, date: $date, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeighingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.animalId, animalId) ||
                other.animalId == animalId) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, animalId, weightKg, date, notes);

  /// Create a copy of Weighing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WeighingImplCopyWith<_$WeighingImpl> get copyWith =>
      __$$WeighingImplCopyWithImpl<_$WeighingImpl>(this, _$identity);
}

abstract class _Weighing implements Weighing {
  const factory _Weighing({
    required final String id,
    required final String animalId,
    required final double weightKg,
    required final DateTime date,
    final String? notes,
  }) = _$WeighingImpl;

  @override
  String get id;
  @override
  String get animalId;
  @override
  double get weightKg;
  @override
  DateTime get date;
  @override
  String? get notes;

  /// Create a copy of Weighing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WeighingImplCopyWith<_$WeighingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
