// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sale_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SaleRecord {
  String get id => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  SaleType get type => throw _privateConstructorUsedError;
  List<String> get animalIds => throw _privateConstructorUsedError;
  int get headCount => throw _privateConstructorUsedError;
  double get totalValue => throw _privateConstructorUsedError;
  String? get buyer => throw _privateConstructorUsedError;

  /// Peso total do lote na venda (kg) — usado para preço por arroba.
  double? get totalWeightKg => throw _privateConstructorUsedError;

  /// Preço por arroba informado (R$/@; arroba = 15 kg).
  double? get pricePerArroba => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Create a copy of SaleRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaleRecordCopyWith<SaleRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaleRecordCopyWith<$Res> {
  factory $SaleRecordCopyWith(
    SaleRecord value,
    $Res Function(SaleRecord) then,
  ) = _$SaleRecordCopyWithImpl<$Res, SaleRecord>;
  @useResult
  $Res call({
    String id,
    DateTime date,
    SaleType type,
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
class _$SaleRecordCopyWithImpl<$Res, $Val extends SaleRecord>
    implements $SaleRecordCopyWith<$Res> {
  _$SaleRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaleRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
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
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as SaleType,
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
abstract class _$$SaleRecordImplCopyWith<$Res>
    implements $SaleRecordCopyWith<$Res> {
  factory _$$SaleRecordImplCopyWith(
    _$SaleRecordImpl value,
    $Res Function(_$SaleRecordImpl) then,
  ) = __$$SaleRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    DateTime date,
    SaleType type,
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
class __$$SaleRecordImplCopyWithImpl<$Res>
    extends _$SaleRecordCopyWithImpl<$Res, _$SaleRecordImpl>
    implements _$$SaleRecordImplCopyWith<$Res> {
  __$$SaleRecordImplCopyWithImpl(
    _$SaleRecordImpl _value,
    $Res Function(_$SaleRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SaleRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
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
      _$SaleRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as SaleType,
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

class _$SaleRecordImpl implements _SaleRecord {
  const _$SaleRecordImpl({
    required this.id,
    required this.date,
    required this.type,
    required final List<String> animalIds,
    required this.headCount,
    required this.totalValue,
    this.buyer,
    this.totalWeightKg,
    this.pricePerArroba,
    this.notes,
  }) : _animalIds = animalIds;

  @override
  final String id;
  @override
  final DateTime date;
  @override
  final SaleType type;
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

  /// Peso total do lote na venda (kg) — usado para preço por arroba.
  @override
  final double? totalWeightKg;

  /// Preço por arroba informado (R$/@; arroba = 15 kg).
  @override
  final double? pricePerArroba;
  @override
  final String? notes;

  @override
  String toString() {
    return 'SaleRecord(id: $id, date: $date, type: $type, animalIds: $animalIds, headCount: $headCount, totalValue: $totalValue, buyer: $buyer, totalWeightKg: $totalWeightKg, pricePerArroba: $pricePerArroba, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaleRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
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

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    date,
    type,
    const DeepCollectionEquality().hash(_animalIds),
    headCount,
    totalValue,
    buyer,
    totalWeightKg,
    pricePerArroba,
    notes,
  );

  /// Create a copy of SaleRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaleRecordImplCopyWith<_$SaleRecordImpl> get copyWith =>
      __$$SaleRecordImplCopyWithImpl<_$SaleRecordImpl>(this, _$identity);
}

abstract class _SaleRecord implements SaleRecord {
  const factory _SaleRecord({
    required final String id,
    required final DateTime date,
    required final SaleType type,
    required final List<String> animalIds,
    required final int headCount,
    required final double totalValue,
    final String? buyer,
    final double? totalWeightKg,
    final double? pricePerArroba,
    final String? notes,
  }) = _$SaleRecordImpl;

  @override
  String get id;
  @override
  DateTime get date;
  @override
  SaleType get type;
  @override
  List<String> get animalIds;
  @override
  int get headCount;
  @override
  double get totalValue;
  @override
  String? get buyer;

  /// Peso total do lote na venda (kg) — usado para preço por arroba.
  @override
  double? get totalWeightKg;

  /// Preço por arroba informado (R$/@; arroba = 15 kg).
  @override
  double? get pricePerArroba;
  @override
  String? get notes;

  /// Create a copy of SaleRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaleRecordImplCopyWith<_$SaleRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
