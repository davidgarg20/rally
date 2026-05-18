// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rating_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RatingHistoryPoint _$RatingHistoryPointFromJson(Map<String, dynamic> json) {
  return _RatingHistoryPoint.fromJson(json);
}

/// @nodoc
mixin _$RatingHistoryPoint {
  @JsonKey(name: 'match_id')
  String get matchId => throw _privateConstructorUsedError;
  String get format => throw _privateConstructorUsedError;
  @JsonKey(name: 'rating_after')
  double get ratingAfter => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this RatingHistoryPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RatingHistoryPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RatingHistoryPointCopyWith<RatingHistoryPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RatingHistoryPointCopyWith<$Res> {
  factory $RatingHistoryPointCopyWith(
          RatingHistoryPoint value, $Res Function(RatingHistoryPoint) then) =
      _$RatingHistoryPointCopyWithImpl<$Res, RatingHistoryPoint>;
  @useResult
  $Res call(
      {@JsonKey(name: 'match_id') String matchId,
      String format,
      @JsonKey(name: 'rating_after') double ratingAfter,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$RatingHistoryPointCopyWithImpl<$Res, $Val extends RatingHistoryPoint>
    implements $RatingHistoryPointCopyWith<$Res> {
  _$RatingHistoryPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RatingHistoryPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? matchId = null,
    Object? format = null,
    Object? ratingAfter = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      matchId: null == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      ratingAfter: null == ratingAfter
          ? _value.ratingAfter
          : ratingAfter // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RatingHistoryPointImplCopyWith<$Res>
    implements $RatingHistoryPointCopyWith<$Res> {
  factory _$$RatingHistoryPointImplCopyWith(_$RatingHistoryPointImpl value,
          $Res Function(_$RatingHistoryPointImpl) then) =
      __$$RatingHistoryPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'match_id') String matchId,
      String format,
      @JsonKey(name: 'rating_after') double ratingAfter,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$RatingHistoryPointImplCopyWithImpl<$Res>
    extends _$RatingHistoryPointCopyWithImpl<$Res, _$RatingHistoryPointImpl>
    implements _$$RatingHistoryPointImplCopyWith<$Res> {
  __$$RatingHistoryPointImplCopyWithImpl(_$RatingHistoryPointImpl _value,
      $Res Function(_$RatingHistoryPointImpl) _then)
      : super(_value, _then);

  /// Create a copy of RatingHistoryPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? matchId = null,
    Object? format = null,
    Object? ratingAfter = null,
    Object? createdAt = null,
  }) {
    return _then(_$RatingHistoryPointImpl(
      matchId: null == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      ratingAfter: null == ratingAfter
          ? _value.ratingAfter
          : ratingAfter // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RatingHistoryPointImpl implements _RatingHistoryPoint {
  const _$RatingHistoryPointImpl(
      {@JsonKey(name: 'match_id') required this.matchId,
      required this.format,
      @JsonKey(name: 'rating_after') required this.ratingAfter,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$RatingHistoryPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$RatingHistoryPointImplFromJson(json);

  @override
  @JsonKey(name: 'match_id')
  final String matchId;
  @override
  final String format;
  @override
  @JsonKey(name: 'rating_after')
  final double ratingAfter;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'RatingHistoryPoint(matchId: $matchId, format: $format, ratingAfter: $ratingAfter, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RatingHistoryPointImpl &&
            (identical(other.matchId, matchId) || other.matchId == matchId) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.ratingAfter, ratingAfter) ||
                other.ratingAfter == ratingAfter) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, matchId, format, ratingAfter, createdAt);

  /// Create a copy of RatingHistoryPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RatingHistoryPointImplCopyWith<_$RatingHistoryPointImpl> get copyWith =>
      __$$RatingHistoryPointImplCopyWithImpl<_$RatingHistoryPointImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RatingHistoryPointImplToJson(
      this,
    );
  }
}

abstract class _RatingHistoryPoint implements RatingHistoryPoint {
  const factory _RatingHistoryPoint(
          {@JsonKey(name: 'match_id') required final String matchId,
          required final String format,
          @JsonKey(name: 'rating_after') required final double ratingAfter,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$RatingHistoryPointImpl;

  factory _RatingHistoryPoint.fromJson(Map<String, dynamic> json) =
      _$RatingHistoryPointImpl.fromJson;

  @override
  @JsonKey(name: 'match_id')
  String get matchId;
  @override
  String get format;
  @override
  @JsonKey(name: 'rating_after')
  double get ratingAfter;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of RatingHistoryPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RatingHistoryPointImplCopyWith<_$RatingHistoryPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
