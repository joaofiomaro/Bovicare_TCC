// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ServiceCall {
  String get id => throw _privateConstructorUsedError; // Produtor (autor):
  String get producerId => throw _privateConstructorUsedError;
  String get producerName => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError; // Conteúdo:
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  ServiceUrgency get urgency => throw _privateConstructorUsedError;
  ServiceStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get farmName => throw _privateConstructorUsedError;
  double? get lat => throw _privateConstructorUsedError;
  double? get lng => throw _privateConstructorUsedError;
  String? get animalEarTag =>
      throw _privateConstructorUsedError; // Veterinário (atribuído ao aceitar):
  String? get vetId => throw _privateConstructorUsedError;
  String? get vetName => throw _privateConstructorUsedError; // Evolução:
  DateTime? get scheduledDate => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  String? get resolution => throw _privateConstructorUsedError;

  /// Create a copy of ServiceCall
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceCallCopyWith<ServiceCall> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceCallCopyWith<$Res> {
  factory $ServiceCallCopyWith(
    ServiceCall value,
    $Res Function(ServiceCall) then,
  ) = _$ServiceCallCopyWithImpl<$Res, ServiceCall>;
  @useResult
  $Res call({
    String id,
    String producerId,
    String producerName,
    String city,
    String state,
    String title,
    String description,
    ServiceUrgency urgency,
    ServiceStatus status,
    DateTime createdAt,
    String? farmName,
    double? lat,
    double? lng,
    String? animalEarTag,
    String? vetId,
    String? vetName,
    DateTime? scheduledDate,
    DateTime? completedAt,
    String? resolution,
  });
}

/// @nodoc
class _$ServiceCallCopyWithImpl<$Res, $Val extends ServiceCall>
    implements $ServiceCallCopyWith<$Res> {
  _$ServiceCallCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServiceCall
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? producerId = null,
    Object? producerName = null,
    Object? city = null,
    Object? state = null,
    Object? title = null,
    Object? description = null,
    Object? urgency = null,
    Object? status = null,
    Object? createdAt = null,
    Object? farmName = freezed,
    Object? lat = freezed,
    Object? lng = freezed,
    Object? animalEarTag = freezed,
    Object? vetId = freezed,
    Object? vetName = freezed,
    Object? scheduledDate = freezed,
    Object? completedAt = freezed,
    Object? resolution = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            producerId: null == producerId
                ? _value.producerId
                : producerId // ignore: cast_nullable_to_non_nullable
                      as String,
            producerName: null == producerName
                ? _value.producerName
                : producerName // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            urgency: null == urgency
                ? _value.urgency
                : urgency // ignore: cast_nullable_to_non_nullable
                      as ServiceUrgency,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ServiceStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            farmName: freezed == farmName
                ? _value.farmName
                : farmName // ignore: cast_nullable_to_non_nullable
                      as String?,
            lat: freezed == lat
                ? _value.lat
                : lat // ignore: cast_nullable_to_non_nullable
                      as double?,
            lng: freezed == lng
                ? _value.lng
                : lng // ignore: cast_nullable_to_non_nullable
                      as double?,
            animalEarTag: freezed == animalEarTag
                ? _value.animalEarTag
                : animalEarTag // ignore: cast_nullable_to_non_nullable
                      as String?,
            vetId: freezed == vetId
                ? _value.vetId
                : vetId // ignore: cast_nullable_to_non_nullable
                      as String?,
            vetName: freezed == vetName
                ? _value.vetName
                : vetName // ignore: cast_nullable_to_non_nullable
                      as String?,
            scheduledDate: freezed == scheduledDate
                ? _value.scheduledDate
                : scheduledDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            resolution: freezed == resolution
                ? _value.resolution
                : resolution // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServiceCallImplCopyWith<$Res>
    implements $ServiceCallCopyWith<$Res> {
  factory _$$ServiceCallImplCopyWith(
    _$ServiceCallImpl value,
    $Res Function(_$ServiceCallImpl) then,
  ) = __$$ServiceCallImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String producerId,
    String producerName,
    String city,
    String state,
    String title,
    String description,
    ServiceUrgency urgency,
    ServiceStatus status,
    DateTime createdAt,
    String? farmName,
    double? lat,
    double? lng,
    String? animalEarTag,
    String? vetId,
    String? vetName,
    DateTime? scheduledDate,
    DateTime? completedAt,
    String? resolution,
  });
}

/// @nodoc
class __$$ServiceCallImplCopyWithImpl<$Res>
    extends _$ServiceCallCopyWithImpl<$Res, _$ServiceCallImpl>
    implements _$$ServiceCallImplCopyWith<$Res> {
  __$$ServiceCallImplCopyWithImpl(
    _$ServiceCallImpl _value,
    $Res Function(_$ServiceCallImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ServiceCall
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? producerId = null,
    Object? producerName = null,
    Object? city = null,
    Object? state = null,
    Object? title = null,
    Object? description = null,
    Object? urgency = null,
    Object? status = null,
    Object? createdAt = null,
    Object? farmName = freezed,
    Object? lat = freezed,
    Object? lng = freezed,
    Object? animalEarTag = freezed,
    Object? vetId = freezed,
    Object? vetName = freezed,
    Object? scheduledDate = freezed,
    Object? completedAt = freezed,
    Object? resolution = freezed,
  }) {
    return _then(
      _$ServiceCallImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        producerId: null == producerId
            ? _value.producerId
            : producerId // ignore: cast_nullable_to_non_nullable
                  as String,
        producerName: null == producerName
            ? _value.producerName
            : producerName // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        urgency: null == urgency
            ? _value.urgency
            : urgency // ignore: cast_nullable_to_non_nullable
                  as ServiceUrgency,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ServiceStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        farmName: freezed == farmName
            ? _value.farmName
            : farmName // ignore: cast_nullable_to_non_nullable
                  as String?,
        lat: freezed == lat
            ? _value.lat
            : lat // ignore: cast_nullable_to_non_nullable
                  as double?,
        lng: freezed == lng
            ? _value.lng
            : lng // ignore: cast_nullable_to_non_nullable
                  as double?,
        animalEarTag: freezed == animalEarTag
            ? _value.animalEarTag
            : animalEarTag // ignore: cast_nullable_to_non_nullable
                  as String?,
        vetId: freezed == vetId
            ? _value.vetId
            : vetId // ignore: cast_nullable_to_non_nullable
                  as String?,
        vetName: freezed == vetName
            ? _value.vetName
            : vetName // ignore: cast_nullable_to_non_nullable
                  as String?,
        scheduledDate: freezed == scheduledDate
            ? _value.scheduledDate
            : scheduledDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        resolution: freezed == resolution
            ? _value.resolution
            : resolution // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ServiceCallImpl implements _ServiceCall {
  const _$ServiceCallImpl({
    required this.id,
    required this.producerId,
    required this.producerName,
    required this.city,
    required this.state,
    required this.title,
    required this.description,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.farmName,
    this.lat,
    this.lng,
    this.animalEarTag,
    this.vetId,
    this.vetName,
    this.scheduledDate,
    this.completedAt,
    this.resolution,
  });

  @override
  final String id;
  // Produtor (autor):
  @override
  final String producerId;
  @override
  final String producerName;
  @override
  final String city;
  @override
  final String state;
  // Conteúdo:
  @override
  final String title;
  @override
  final String description;
  @override
  final ServiceUrgency urgency;
  @override
  final ServiceStatus status;
  @override
  final DateTime createdAt;
  @override
  final String? farmName;
  @override
  final double? lat;
  @override
  final double? lng;
  @override
  final String? animalEarTag;
  // Veterinário (atribuído ao aceitar):
  @override
  final String? vetId;
  @override
  final String? vetName;
  // Evolução:
  @override
  final DateTime? scheduledDate;
  @override
  final DateTime? completedAt;
  @override
  final String? resolution;

  @override
  String toString() {
    return 'ServiceCall(id: $id, producerId: $producerId, producerName: $producerName, city: $city, state: $state, title: $title, description: $description, urgency: $urgency, status: $status, createdAt: $createdAt, farmName: $farmName, lat: $lat, lng: $lng, animalEarTag: $animalEarTag, vetId: $vetId, vetName: $vetName, scheduledDate: $scheduledDate, completedAt: $completedAt, resolution: $resolution)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceCallImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.producerId, producerId) ||
                other.producerId == producerId) &&
            (identical(other.producerName, producerName) ||
                other.producerName == producerName) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.urgency, urgency) || other.urgency == urgency) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.farmName, farmName) ||
                other.farmName == farmName) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.animalEarTag, animalEarTag) ||
                other.animalEarTag == animalEarTag) &&
            (identical(other.vetId, vetId) || other.vetId == vetId) &&
            (identical(other.vetName, vetName) || other.vetName == vetName) &&
            (identical(other.scheduledDate, scheduledDate) ||
                other.scheduledDate == scheduledDate) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.resolution, resolution) ||
                other.resolution == resolution));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    producerId,
    producerName,
    city,
    state,
    title,
    description,
    urgency,
    status,
    createdAt,
    farmName,
    lat,
    lng,
    animalEarTag,
    vetId,
    vetName,
    scheduledDate,
    completedAt,
    resolution,
  ]);

  /// Create a copy of ServiceCall
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceCallImplCopyWith<_$ServiceCallImpl> get copyWith =>
      __$$ServiceCallImplCopyWithImpl<_$ServiceCallImpl>(this, _$identity);
}

abstract class _ServiceCall implements ServiceCall {
  const factory _ServiceCall({
    required final String id,
    required final String producerId,
    required final String producerName,
    required final String city,
    required final String state,
    required final String title,
    required final String description,
    required final ServiceUrgency urgency,
    required final ServiceStatus status,
    required final DateTime createdAt,
    final String? farmName,
    final double? lat,
    final double? lng,
    final String? animalEarTag,
    final String? vetId,
    final String? vetName,
    final DateTime? scheduledDate,
    final DateTime? completedAt,
    final String? resolution,
  }) = _$ServiceCallImpl;

  @override
  String get id; // Produtor (autor):
  @override
  String get producerId;
  @override
  String get producerName;
  @override
  String get city;
  @override
  String get state; // Conteúdo:
  @override
  String get title;
  @override
  String get description;
  @override
  ServiceUrgency get urgency;
  @override
  ServiceStatus get status;
  @override
  DateTime get createdAt;
  @override
  String? get farmName;
  @override
  double? get lat;
  @override
  double? get lng;
  @override
  String? get animalEarTag; // Veterinário (atribuído ao aceitar):
  @override
  String? get vetId;
  @override
  String? get vetName; // Evolução:
  @override
  DateTime? get scheduledDate;
  @override
  DateTime? get completedAt;
  @override
  String? get resolution;

  /// Create a copy of ServiceCall
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceCallImplCopyWith<_$ServiceCallImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
