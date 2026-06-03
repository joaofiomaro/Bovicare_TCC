// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sale_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SaleModel _$SaleModelFromJson(Map<String, dynamic> json) {
  return _SaleModel.fromJson(json);
}

/// @nodoc
mixin _$SaleModel {
  String get id => throw _privateConstructorUsedError;
  String get dateIso => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  List<String> get animalIds => throw _privateConstructorUsedError;
  int get headCount => throw _privateConstructorUsedError;
  double get totalValue => throw _privateConstructorUsedError;
  String? get buyer => throw _privateConstructorUsedError;
  double? get totalWeightKg => throw _privateConstructorUsedError;
  double? get pricePerArroba => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this SaleModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SaleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaleModelCopyWith<SaleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaleModelCopyWith<$Res> {
  factory $SaleModelCopyWith(SaleModel value, $Res Function(SaleModel) then) =
      _$SaleModelCopyWithImpl<$Res, SaleModel>;
  @useResult
  $Res call({
    String id,
    String dateIso,
    String type,
    List<String> animalIds,
    int headCount,
    double totalValue,
    String? buyer,
    double? totalWeightKg,
    double? pricePerArroba,
    String? notes,
  });
}

/// @nodoc
class _$SaleModelCopyWithImpl<$Res, $Val extends SaleModel>
    implements $SaleModelCopyWith<$Res> {
  _$SaleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dateIso = null,
    Object? type = null,
    Object? animalIds = null,
    Object? headCount = null,
    Object? totalValue = null,
    Object? buyer = freezed,
    Object? totalWeightKg = freezed,
    Object? pricePerArroba = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            dateIso: null == dateIso
                ? _value.dateIso
                : dateIso // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            animalIds: null == animalIds
                ? _value.animalIds
                : animalIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            headCount: null == headCount
                ? _value.headCount
                : headCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalValue: null == totalValue
                ? _value.totalValue
                : totalValue // ignore: cast_nullable_to_non_nullable
                      as double,
            buyer: freezed == buyer
                ? _value.buyer
                : buyer // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalWeightKg: freezed == totalWeightKg
                ? _value.totalWeightKg
                : totalWeightKg // ignore: cast_nullable_to_non_nullable
                      as double?,
            pricePerArroba: freezed == pricePerArroba
                ? _value.pricePerArroba
                : pricePerArroba // ignore: cast_nullable_to_non_nullable
                      as double?,
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
abstract class _$$SaleModelImplCopyWith<$Res>
    implements $SaleModelCopyWith<$Res> {
  factory _$$SaleModelImplCopyWith(
    _$SaleModelImpl value,
    $Res Function(_$SaleModelImpl) then,
  ) = __$$SaleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String dateIso,
    String type,
    List<String> animalIds,
    int headCount,
    double totalValue,
    String? buyer,
    double? totalWeightKg,
    double? pricePerArroba,
    String? notes,
  });
}

/// @nodoc
class __$$SaleModelImplCopyWithImpl<$Res>
    extends _$SaleModelCopyWithImpl<$Res, _$SaleModelImpl>
    implements _$$SaleModelImplCopyWith<$Res> {
  __$$SaleModelImplCopyWithImpl(
    _$SaleModelImpl _value,
    $Res Function(_$SaleModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SaleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dateIso = null,
    Object? type = null,
    Object? animalIds = null,
    Object? headCount = null,
    Object? totalValue = null,
    Object? buyer = freezed,
    Object? totalWeightKg = freezed,
    Object? pricePerArroba = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$SaleModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        dateIso: null == dateIso
            ? _value.dateIso
            : dateIso // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        animalIds: null == animalIds
            ? _value._animalIds
            : animalIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        headCount: null == headCount
            ? _value.headCount
            : headCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalValue: null == totalValue
            ? _value.totalValue
            : totalValue // ignore: cast_nullable_to_non_nullable
                  as double,
        buyer: freezed == buyer
            ? _value.buyer
            : buyer // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalWeightKg: freezed == totalWeightKg
            ? _value.totalWeightKg
            : totalWeightKg // ignore: cast_nullable_to_non_nullable
                  as double?,
        pricePerArroba: freezed == pricePerArroba
            ? _value.pricePerArroba
            : pricePerArroba // ignore: cast_nullable_to_non_nullable
                  as double?,
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
class _$SaleModelImpl extends _SaleModel {
  const _$SaleModelImpl({
    required this.id,
    required this.dateIso,
    required this.type,
    required final List<String> animalIds,
    required this.headCount,
    required this.totalValue,
    this.buyer,
    this.totalWeightKg,
    this.pricePerArroba,
    this.notes,
  }) : _animalIds = animalIds,
       super._();

  factory _$SaleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SaleModelImplFromJson(json);

  @override
  final String id;
  @override
  final String dateIso;
  @override
  final String type;
  final List<String> _animalIds;
  @override
  List<String> get animalIds {
    if (_animalIds is EqualUnmodifiableListView) return _animalIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_animalIds);
  }

  @override
  final int headCount;
  @override
  final double totalValue;
  @override
  final String? buyer;
  @override
  final double? totalWeightKg;
  @override
  final double? pricePerArroba;
  @override
  final String? notes;

  @override
  String toString() {
    return 'SaleModel(id: $id, dateIso: $dateIso, type: $type, animalIds: $animalIds, headCount: $headCount, totalValue: $totalValue, buyer: $buyer, totalWeightKg: $totalWeightKg, pricePerArroba: $pricePerArroba, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaleModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.dateIso, dateIso) || other.dateIso == dateIso) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(
              other._animalIds,
              _animalIds,
            ) &&
            (identical(other.headCount, headCount) ||
                other.headCount == headCount) &&
            (identical(other.totalValue, totalValue) ||
                other.totalValue == totalValue) &&
            (identical(other.buyer, buyer) || other.buyer == buyer) &&
            (identical(other.totalWeightKg, totalWeightKg) ||
                other.totalWeightKg == totalWeightKg) &&
            (identical(other.pricePerArroba, pricePerArroba) ||
                other.pricePerArroba == pricePerArroba) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    dateIso,
    type,
    const DeepCollectionEquality().hash(_animalIds),
    headCount,
    totalValue,
    buyer,
    totalWeightKg,
    pricePerArroba,
    notes,
  );

  /// Create a copy of SaleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaleModelImplCopyWith<_$SaleModelImpl> get copyWith =>
      __$$SaleModelImplCopyWithImpl<_$SaleModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SaleModelImplToJson(this);
  }
}

abstract class _SaleModel extends SaleModel {
  const factory _SaleModel({
    required final String id,
    required final String dateIso,
    required final String type,
    required final List<String> animalIds,
    required final int headCount,
    required final double totalValue,
    final String? buyer,
    final double? totalWeightKg,
    final double? pricePerArroba,
    final String? notes,
  }) = _$SaleModelImpl;
  const _SaleModel._() : super._();

  factory _SaleModel.fromJson(Map<String, dynamic> json) =
      _$SaleModelImpl.fromJson;

  @override
  String get id;
  @override
  String get dateIso;
  @override
  String get type;
  @override
  List<String> get animalIds;
  @override
  int get headCount;
  @override
  double get totalValue;
  @override
  String? get buyer;
  @override
  double? get totalWeightKg;
  @override
  double? get pricePerArroba;
  @override
  String? get notes;

  /// Create a copy of SaleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaleModelImplCopyWith<_$SaleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
