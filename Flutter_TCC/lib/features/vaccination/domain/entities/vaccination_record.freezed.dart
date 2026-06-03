// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vaccination_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$VaccinationRecord {
  String get id => throw _privateConstructorUsedError;
  String get animalId => throw _privateConstructorUsedError;
  String get vaccineName => throw _privateConstructorUsedError;
  String get dose => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;

  /// Dias de carência sanitária após a aplicação (varia por vacina).
  int get quarantineDays => throw _privateConstructorUsedError;
  String? get lot => throw _privateConstructorUsedError;
  String? get veterinarianName => throw _privateConstructorUsedError;

  /// Data calculada para a próxima dose (null se dose única sem reforço).
  DateTime? get nextDoseDate => throw _privateConstructorUsedError;

  /// Create a copy of VaccinationRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VaccinationRecordCopyWith<VaccinationRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VaccinationRecordCopyWith<$Res> {
  factory $VaccinationRecordCopyWith(
    VaccinationRecord value,
    $Res Function(VaccinationRecord) then,
  ) = _$VaccinationRecordCopyWithImpl<$Res, VaccinationRecord>;
  @useResult
  $Res call({
    String id,
    String animalId,
    String vaccineName,
    String dose,
    DateTime date,
    int quarantineDays,
    String? lot,
    String? veterinarianName,
    DateTime? nextDoseDate,
  });
}

/// @nodoc
class _$VaccinationRecordCopyWithImpl<$Res, $Val extends VaccinationRecord>
    implements $VaccinationRecordCopyWith<$Res> {
  _$VaccinationRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VaccinationRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? animalId = null,
    Object? vaccineName = null,
    Object? dose = null,
    Object? date = null,
    Object? quarantineDays = null,
    Object? lot = freezed,
    Object? veterinarianName = freezed,
    Object? nextDoseDate = freezed,
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
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
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
            nextDoseDate: freezed == nextDoseDate
                ? _value.nextDoseDate
                : nextDoseDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VaccinationRecordImplCopyWith<$Res>
    implements $VaccinationRecordCopyWith<$Res> {
  factory _$$VaccinationRecordImplCopyWith(
    _$VaccinationRecordImpl value,
    $Res Function(_$VaccinationRecordImpl) then,
  ) = __$$VaccinationRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String animalId,
    String vaccineName,
    String dose,
    DateTime date,
    int quarantineDays,
    String? lot,
    String? veterinarianName,
    DateTime? nextDoseDate,
  });
}

/// @nodoc
class __$$VaccinationRecordImplCopyWithImpl<$Res>
    extends _$VaccinationRecordCopyWithImpl<$Res, _$VaccinationRecordImpl>
    implements _$$VaccinationRecordImplCopyWith<$Res> {
  __$$VaccinationRecordImplCopyWithImpl(
    _$VaccinationRecordImpl _value,
    $Res Function(_$VaccinationRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VaccinationRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? animalId = null,
    Object? vaccineName = null,
    Object? dose = null,
    Object? date = null,
    Object? quarantineDays = null,
    Object? lot = freezed,
    Object? veterinarianName = freezed,
    Object? nextDoseDate = freezed,
  }) {
    return _then(
      _$VaccinationRecordImpl(
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
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
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
        nextDoseDate: freezed == nextDoseDate
            ? _value.nextDoseDate
            : nextDoseDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$VaccinationRecordImpl implements _VaccinationRecord {
  const _$VaccinationRecordImpl({
    required this.id,
    required this.animalId,
    required this.vaccineName,
    required this.dose,
    required this.date,
    required this.quarantineDays,
    this.lot,
    this.veterinarianName,
    this.nextDoseDate,
  });

  @override
  final String id;
  @override
  final String animalId;
  @override
  final String vaccineName;
  @override
  final String dose;
  @override
  final DateTime date;

  /// Dias de carência sanitária após a aplicação (varia por vacina).
  @override
  final int quarantineDays;
  @override
  final String? lot;
  @override
  final String? veterinarianName;

  /// Data calculada para a próxima dose (null se dose única sem reforço).
  @override
  final DateTime? nextDoseDate;

  @override
  String toString() {
    return 'VaccinationRecord(id: $id, animalId: $animalId, vaccineName: $vaccineName, dose: $dose, date: $date, quarantineDays: $quarantineDays, lot: $lot, veterinarianName: $veterinarianName, nextDoseDate: $nextDoseDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaccinationRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.animalId, animalId) ||
                other.animalId == animalId) &&
            (identical(other.vaccineName, vaccineName) ||
                other.vaccineName == vaccineName) &&
            (identical(other.dose, dose) || other.dose == dose) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.quarantineDays, quarantineDays) ||
                other.quarantineDays == quarantineDays) &&
            (identical(other.lot, lot) || other.lot == lot) &&
            (identical(other.veterinarianName, veterinarianName) ||
                other.veterinarianName == veterinarianName) &&
            (identical(other.nextDoseDate, nextDoseDate) ||
                other.nextDoseDate == nextDoseDate));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    animalId,
    vaccineName,
    dose,
    date,
    quarantineDays,
    lot,
    veterinarianName,
    nextDoseDate,
  );

  /// Create a copy of VaccinationRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VaccinationRecordImplCopyWith<_$VaccinationRecordImpl> get copyWith =>
      __$$VaccinationRecordImplCopyWithImpl<_$VaccinationRecordImpl>(
        this,
        _$identity,
      );
}

abstract class _VaccinationRecord implements VaccinationRecord {
  const factory _VaccinationRecord({
    required final String id,
    required final String animalId,
    required final String vaccineName,
    required final String dose,
    required final DateTime date,
    required final int quarantineDays,
    final String? lot,
    final String? veterinarianName,
    final DateTime? nextDoseDate,
  }) = _$VaccinationRecordImpl;

  @override
  String get id;
  @override
  String get animalId;
  @override
  String get vaccineName;
  @override
  String get dose;
  @override
  DateTime get date;

  /// Dias de carência sanitária após a aplicação (varia por vacina).
  @override
  int get quarantineDays;
  @override
  String? get lot;
  @override
  String? get veterinarianName;

  /// Data calculada para a próxima dose (null se dose única sem reforço).
  @override
  DateTime? get nextDoseDate;

  /// Create a copy of VaccinationRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VaccinationRecordImplCopyWith<_$VaccinationRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
