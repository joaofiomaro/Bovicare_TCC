// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vet_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VetModel _$VetModelFromJson(Map<String, dynamic> json) {
  return _VetModel.fromJson(json);
}

/// @nodoc
mixin _$VetModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get crmv => throw _privateConstructorUsedError;
  List<String> get specialties => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  bool get isAvailable => throw _privateConstructorUsedError;
  int get coverageRadiusKm => throw _privateConstructorUsedError;
  String? get whatsapp => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;

  /// Serializes this VetModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VetModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VetModelCopyWith<VetModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VetModelCopyWith<$Res> {
  factory $VetModelCopyWith(VetModel value, $Res Function(VetModel) then) =
      _$VetModelCopyWithImpl<$Res, VetModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String crmv,
    List<String> specialties,
    String phone,
    String city,
    String state,
    double lat,
    double lng,
    bool isAvailable,
    int coverageRadiusKm,
    String? whatsapp,
    String? email,
  });
}

/// @nodoc
class _$VetModelCopyWithImpl<$Res, $Val extends VetModel>
    implements $VetModelCopyWith<$Res> {
  _$VetModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VetModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? crmv = null,
    Object? specialties = null,
    Object? phone = null,
    Object? city = null,
    Object? state = null,
    Object? lat = null,
    Object? lng = null,
    Object? isAvailable = null,
    Object? coverageRadiusKm = null,
    Object? whatsapp = freezed,
    Object? email = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            crmv: null == crmv
                ? _value.crmv
                : crmv // ignore: cast_nullable_to_non_nullable
                      as String,
            specialties: null == specialties
                ? _value.specialties
                : specialties // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String,
            lat: null == lat
                ? _value.lat
                : lat // ignore: cast_nullable_to_non_nullable
                      as double,
            lng: null == lng
                ? _value.lng
                : lng // ignore: cast_nullable_to_non_nullable
                      as double,
            isAvailable: null == isAvailable
                ? _value.isAvailable
                : isAvailable // ignore: cast_nullable_to_non_nullable
                      as bool,
            coverageRadiusKm: null == coverageRadiusKm
                ? _value.coverageRadiusKm
                : coverageRadiusKm // ignore: cast_nullable_to_non_nullable
                      as int,
            whatsapp: freezed == whatsapp
                ? _value.whatsapp
                : whatsapp // ignore: cast_nullable_to_non_nullable
                      as String?,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VetModelImplCopyWith<$Res>
    implements $VetModelCopyWith<$Res> {
  factory _$$VetModelImplCopyWith(
    _$VetModelImpl value,
    $Res Function(_$VetModelImpl) then,
  ) = __$$VetModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String crmv,
    List<String> specialties,
    String phone,
    String city,
    String state,
    double lat,
    double lng,
    bool isAvailable,
    int coverageRadiusKm,
    String? whatsapp,
    String? email,
  });
}

/// @nodoc
class __$$VetModelImplCopyWithImpl<$Res>
    extends _$VetModelCopyWithImpl<$Res, _$VetModelImpl>
    implements _$$VetModelImplCopyWith<$Res> {
  __$$VetModelImplCopyWithImpl(
    _$VetModelImpl _value,
    $Res Function(_$VetModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VetModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? crmv = null,
    Object? specialties = null,
    Object? phone = null,
    Object? city = null,
    Object? state = null,
    Object? lat = null,
    Object? lng = null,
    Object? isAvailable = null,
    Object? coverageRadiusKm = null,
    Object? whatsapp = freezed,
    Object? email = freezed,
  }) {
    return _then(
      _$VetModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        crmv: null == crmv
            ? _value.crmv
            : crmv // ignore: cast_nullable_to_non_nullable
                  as String,
        specialties: null == specialties
            ? _value._specialties
            : specialties // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String,
        lat: null == lat
            ? _value.lat
            : lat // ignore: cast_nullable_to_non_nullable
                  as double,
        lng: null == lng
            ? _value.lng
            : lng // ignore: cast_nullable_to_non_nullable
                  as double,
        isAvailable: null == isAvailable
            ? _value.isAvailable
            : isAvailable // ignore: cast_nullable_to_non_nullable
                  as bool,
        coverageRadiusKm: null == coverageRadiusKm
            ? _value.coverageRadiusKm
            : coverageRadiusKm // ignore: cast_nullable_to_non_nullable
                  as int,
        whatsapp: freezed == whatsapp
            ? _value.whatsapp
            : whatsapp // ignore: cast_nullable_to_non_nullable
                  as String?,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VetModelImpl extends _VetModel {
  const _$VetModelImpl({
    required this.id,
    required this.name,
    required this.crmv,
    required final List<String> specialties,
    required this.phone,
    required this.city,
    required this.state,
    required this.lat,
    required this.lng,
    required this.isAvailable,
    required this.coverageRadiusKm,
    this.whatsapp,
    this.email,
  }) : _specialties = specialties,
       super._();

  factory _$VetModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VetModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String crmv;
  final List<String> _specialties;
  @override
  List<String> get specialties {
    if (_specialties is EqualUnmodifiableListView) return _specialties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_specialties);
  }

  @override
  final String phone;
  @override
  final String city;
  @override
  final String state;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final bool isAvailable;
  @override
  final int coverageRadiusKm;
  @override
  final String? whatsapp;
  @override
  final String? email;

  @override
  String toString() {
    return 'VetModel(id: $id, name: $name, crmv: $crmv, specialties: $specialties, phone: $phone, city: $city, state: $state, lat: $lat, lng: $lng, isAvailable: $isAvailable, coverageRadiusKm: $coverageRadiusKm, whatsapp: $whatsapp, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VetModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.crmv, crmv) || other.crmv == crmv) &&
            const DeepCollectionEquality().equals(
              other._specialties,
              _specialties,
            ) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.coverageRadiusKm, coverageRadiusKm) ||
                other.coverageRadiusKm == coverageRadiusKm) &&
            (identical(other.whatsapp, whatsapp) ||
                other.whatsapp == whatsapp) &&
            (identical(other.email, email) || other.email == email));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    crmv,
    const DeepCollectionEquality().hash(_specialties),
    phone,
    city,
    state,
    lat,
    lng,
    isAvailable,
    coverageRadiusKm,
    whatsapp,
    email,
  );

  /// Create a copy of VetModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VetModelImplCopyWith<_$VetModelImpl> get copyWith =>
      __$$VetModelImplCopyWithImpl<_$VetModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VetModelImplToJson(this);
  }
}

abstract class _VetModel extends VetModel {
  const factory _VetModel({
    required final String id,
    required final String name,
    required final String crmv,
    required final List<String> specialties,
    required final String phone,
    required final String city,
    required final String state,
    required final double lat,
    required final double lng,
    required final bool isAvailable,
    required final int coverageRadiusKm,
    final String? whatsapp,
    final String? email,
  }) = _$VetModelImpl;
  const _VetModel._() : super._();

  factory _VetModel.fromJson(Map<String, dynamic> json) =
      _$VetModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get crmv;
  @override
  List<String> get specialties;
  @override
  String get phone;
  @override
  String get city;
  @override
  String get state;
  @override
  double get lat;
  @override
  double get lng;
  @override
  bool get isAvailable;
  @override
  int get coverageRadiusKm;
  @override
  String? get whatsapp;
  @override
  String? get email;

  /// Create a copy of VetModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VetModelImplCopyWith<_$VetModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
