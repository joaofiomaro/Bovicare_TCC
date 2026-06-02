// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DashboardStats {
  int get totalAnimals => throw _privateConstructorUsedError;
  int get pregnantCount => throw _privateConstructorUsedError;
  int get alertCount => throw _privateConstructorUsedError;
  int get upcomingVaccinations => throw _privateConstructorUsedError;

  /// Título do banner de alerta (ex: "3 vacinas vencem em 7 dias").
  String? get alertMessage => throw _privateConstructorUsedError;

  /// Detalhe adicional do alerta.
  String? get alertDetail => throw _privateConstructorUsedError;

  /// Create a copy of DashboardStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardStatsCopyWith<DashboardStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardStatsCopyWith<$Res> {
  factory $DashboardStatsCopyWith(
    DashboardStats value,
    $Res Function(DashboardStats) then,
  ) = _$DashboardStatsCopyWithImpl<$Res, DashboardStats>;
  @useResult
  $Res call({
    int totalAnimals,
    int pregnantCount,
    int alertCount,
    int upcomingVaccinations,
    String? alertMessage,
    String? alertDetail,
  });
}

/// @nodoc
class _$DashboardStatsCopyWithImpl<$Res, $Val extends DashboardStats>
    implements $DashboardStatsCopyWith<$Res> {
  _$DashboardStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalAnimals = null,
    Object? pregnantCount = null,
    Object? alertCount = null,
    Object? upcomingVaccinations = null,
    Object? alertMessage = freezed,
    Object? alertDetail = freezed,
  }) {
    return _then(
      _value.copyWith(
            totalAnimals: null == totalAnimals
                ? _value.totalAnimals
                : totalAnimals // ignore: cast_nullable_to_non_nullable
                      as int,
            pregnantCount: null == pregnantCount
                ? _value.pregnantCount
                : pregnantCount // ignore: cast_nullable_to_non_nullable
                      as int,
            alertCount: null == alertCount
                ? _value.alertCount
                : alertCount // ignore: cast_nullable_to_non_nullable
                      as int,
            upcomingVaccinations: null == upcomingVaccinations
                ? _value.upcomingVaccinations
                : upcomingVaccinations // ignore: cast_nullable_to_non_nullable
                      as int,
            alertMessage: freezed == alertMessage
                ? _value.alertMessage
                : alertMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            alertDetail: freezed == alertDetail
                ? _value.alertDetail
                : alertDetail // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DashboardStatsImplCopyWith<$Res>
    implements $DashboardStatsCopyWith<$Res> {
  factory _$$DashboardStatsImplCopyWith(
    _$DashboardStatsImpl value,
    $Res Function(_$DashboardStatsImpl) then,
  ) = __$$DashboardStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalAnimals,
    int pregnantCount,
    int alertCount,
    int upcomingVaccinations,
    String? alertMessage,
    String? alertDetail,
  });
}

/// @nodoc
class __$$DashboardStatsImplCopyWithImpl<$Res>
    extends _$DashboardStatsCopyWithImpl<$Res, _$DashboardStatsImpl>
    implements _$$DashboardStatsImplCopyWith<$Res> {
  __$$DashboardStatsImplCopyWithImpl(
    _$DashboardStatsImpl _value,
    $Res Function(_$DashboardStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DashboardStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalAnimals = null,
    Object? pregnantCount = null,
    Object? alertCount = null,
    Object? upcomingVaccinations = null,
    Object? alertMessage = freezed,
    Object? alertDetail = freezed,
  }) {
    return _then(
      _$DashboardStatsImpl(
        totalAnimals: null == totalAnimals
            ? _value.totalAnimals
            : totalAnimals // ignore: cast_nullable_to_non_nullable
                  as int,
        pregnantCount: null == pregnantCount
            ? _value.pregnantCount
            : pregnantCount // ignore: cast_nullable_to_non_nullable
                  as int,
        alertCount: null == alertCount
            ? _value.alertCount
            : alertCount // ignore: cast_nullable_to_non_nullable
                  as int,
        upcomingVaccinations: null == upcomingVaccinations
            ? _value.upcomingVaccinations
            : upcomingVaccinations // ignore: cast_nullable_to_non_nullable
                  as int,
        alertMessage: freezed == alertMessage
            ? _value.alertMessage
            : alertMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        alertDetail: freezed == alertDetail
            ? _value.alertDetail
            : alertDetail // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$DashboardStatsImpl implements _DashboardStats {
  const _$DashboardStatsImpl({
    required this.totalAnimals,
    required this.pregnantCount,
    required this.alertCount,
    required this.upcomingVaccinations,
    this.alertMessage,
    this.alertDetail,
  });

  @override
  final int totalAnimals;
  @override
  final int pregnantCount;
  @override
  final int alertCount;
  @override
  final int upcomingVaccinations;

  /// Título do banner de alerta (ex: "3 vacinas vencem em 7 dias").
  @override
  final String? alertMessage;

  /// Detalhe adicional do alerta.
  @override
  final String? alertDetail;

  @override
  String toString() {
    return 'DashboardStats(totalAnimals: $totalAnimals, pregnantCount: $pregnantCount, alertCount: $alertCount, upcomingVaccinations: $upcomingVaccinations, alertMessage: $alertMessage, alertDetail: $alertDetail)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardStatsImpl &&
            (identical(other.totalAnimals, totalAnimals) ||
                other.totalAnimals == totalAnimals) &&
            (identical(other.pregnantCount, pregnantCount) ||
                other.pregnantCount == pregnantCount) &&
            (identical(other.alertCount, alertCount) ||
                other.alertCount == alertCount) &&
            (identical(other.upcomingVaccinations, upcomingVaccinations) ||
                other.upcomingVaccinations == upcomingVaccinations) &&
            (identical(other.alertMessage, alertMessage) ||
                other.alertMessage == alertMessage) &&
            (identical(other.alertDetail, alertDetail) ||
                other.alertDetail == alertDetail));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalAnimals,
    pregnantCount,
    alertCount,
    upcomingVaccinations,
    alertMessage,
    alertDetail,
  );

  /// Create a copy of DashboardStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardStatsImplCopyWith<_$DashboardStatsImpl> get copyWith =>
      __$$DashboardStatsImplCopyWithImpl<_$DashboardStatsImpl>(
        this,
        _$identity,
      );
}

abstract class _DashboardStats implements DashboardStats {
  const factory _DashboardStats({
    required final int totalAnimals,
    required final int pregnantCount,
    required final int alertCount,
    required final int upcomingVaccinations,
    final String? alertMessage,
    final String? alertDetail,
  }) = _$DashboardStatsImpl;

  @override
  int get totalAnimals;
  @override
  int get pregnantCount;
  @override
  int get alertCount;
  @override
  int get upcomingVaccinations;

  /// Título do banner de alerta (ex: "3 vacinas vencem em 7 dias").
  @override
  String? get alertMessage;

  /// Detalhe adicional do alerta.
  @override
  String? get alertDetail;

  /// Create a copy of DashboardStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardStatsImplCopyWith<_$DashboardStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
