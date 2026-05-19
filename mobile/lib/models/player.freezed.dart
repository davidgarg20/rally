// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Player _$PlayerFromJson(Map<String, dynamic> json) {
  return _Player.fromJson(json);
}

/// @nodoc
mixin _$Player {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'phone_e164')
  String get phoneE164 => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  DateTime? get dob => throw _privateConstructorUsedError;
  @JsonKey(name: 'home_city')
  String get homeCity => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  double get rd => throw _privateConstructorUsedError;
  @JsonKey(name: 'matches_played')
  int get matchesPlayed => throw _privateConstructorUsedError;

  /// Serializes this Player to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerCopyWith<Player> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerCopyWith<$Res> {
  factory $PlayerCopyWith(Player value, $Res Function(Player) then) =
      _$PlayerCopyWithImpl<$Res, Player>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'phone_e164') String phoneE164,
      String username,
      @JsonKey(name: 'display_name') String displayName,
      String? gender,
      DateTime? dob,
      @JsonKey(name: 'home_city') String homeCity,
      double rating,
      double rd,
      @JsonKey(name: 'matches_played') int matchesPlayed});
}

/// @nodoc
class _$PlayerCopyWithImpl<$Res, $Val extends Player>
    implements $PlayerCopyWith<$Res> {
  _$PlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phoneE164 = null,
    Object? username = null,
    Object? displayName = null,
    Object? gender = freezed,
    Object? dob = freezed,
    Object? homeCity = null,
    Object? rating = null,
    Object? rd = null,
    Object? matchesPlayed = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      phoneE164: null == phoneE164
          ? _value.phoneE164
          : phoneE164 // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      dob: freezed == dob
          ? _value.dob
          : dob // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      homeCity: null == homeCity
          ? _value.homeCity
          : homeCity // ignore: cast_nullable_to_non_nullable
              as String,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      rd: null == rd
          ? _value.rd
          : rd // ignore: cast_nullable_to_non_nullable
              as double,
      matchesPlayed: null == matchesPlayed
          ? _value.matchesPlayed
          : matchesPlayed // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerImplCopyWith<$Res> implements $PlayerCopyWith<$Res> {
  factory _$$PlayerImplCopyWith(
          _$PlayerImpl value, $Res Function(_$PlayerImpl) then) =
      __$$PlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'phone_e164') String phoneE164,
      String username,
      @JsonKey(name: 'display_name') String displayName,
      String? gender,
      DateTime? dob,
      @JsonKey(name: 'home_city') String homeCity,
      double rating,
      double rd,
      @JsonKey(name: 'matches_played') int matchesPlayed});
}

/// @nodoc
class __$$PlayerImplCopyWithImpl<$Res>
    extends _$PlayerCopyWithImpl<$Res, _$PlayerImpl>
    implements _$$PlayerImplCopyWith<$Res> {
  __$$PlayerImplCopyWithImpl(
      _$PlayerImpl _value, $Res Function(_$PlayerImpl) _then)
      : super(_value, _then);

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phoneE164 = null,
    Object? username = null,
    Object? displayName = null,
    Object? gender = freezed,
    Object? dob = freezed,
    Object? homeCity = null,
    Object? rating = null,
    Object? rd = null,
    Object? matchesPlayed = null,
  }) {
    return _then(_$PlayerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      phoneE164: null == phoneE164
          ? _value.phoneE164
          : phoneE164 // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      dob: freezed == dob
          ? _value.dob
          : dob // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      homeCity: null == homeCity
          ? _value.homeCity
          : homeCity // ignore: cast_nullable_to_non_nullable
              as String,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      rd: null == rd
          ? _value.rd
          : rd // ignore: cast_nullable_to_non_nullable
              as double,
      matchesPlayed: null == matchesPlayed
          ? _value.matchesPlayed
          : matchesPlayed // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerImpl implements _Player {
  const _$PlayerImpl(
      {required this.id,
      @JsonKey(name: 'phone_e164') required this.phoneE164,
      required this.username,
      @JsonKey(name: 'display_name') required this.displayName,
      this.gender,
      this.dob,
      @JsonKey(name: 'home_city') required this.homeCity,
      required this.rating,
      required this.rd,
      @JsonKey(name: 'matches_played') required this.matchesPlayed});

  factory _$PlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'phone_e164')
  final String phoneE164;
  @override
  final String username;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  final String? gender;
  @override
  final DateTime? dob;
  @override
  @JsonKey(name: 'home_city')
  final String homeCity;
  @override
  final double rating;
  @override
  final double rd;
  @override
  @JsonKey(name: 'matches_played')
  final int matchesPlayed;

  @override
  String toString() {
    return 'Player(id: $id, phoneE164: $phoneE164, username: $username, displayName: $displayName, gender: $gender, dob: $dob, homeCity: $homeCity, rating: $rating, rd: $rd, matchesPlayed: $matchesPlayed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.phoneE164, phoneE164) ||
                other.phoneE164 == phoneE164) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.dob, dob) || other.dob == dob) &&
            (identical(other.homeCity, homeCity) ||
                other.homeCity == homeCity) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.rd, rd) || other.rd == rd) &&
            (identical(other.matchesPlayed, matchesPlayed) ||
                other.matchesPlayed == matchesPlayed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, phoneE164, username,
      displayName, gender, dob, homeCity, rating, rd, matchesPlayed);

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      __$$PlayerImplCopyWithImpl<_$PlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerImplToJson(
      this,
    );
  }
}

abstract class _Player implements Player {
  const factory _Player(
          {required final String id,
          @JsonKey(name: 'phone_e164') required final String phoneE164,
          required final String username,
          @JsonKey(name: 'display_name') required final String displayName,
          final String? gender,
          final DateTime? dob,
          @JsonKey(name: 'home_city') required final String homeCity,
          required final double rating,
          required final double rd,
          @JsonKey(name: 'matches_played') required final int matchesPlayed}) =
      _$PlayerImpl;

  factory _Player.fromJson(Map<String, dynamic> json) = _$PlayerImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'phone_e164')
  String get phoneE164;
  @override
  String get username;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  String? get gender;
  @override
  DateTime? get dob;
  @override
  @JsonKey(name: 'home_city')
  String get homeCity;
  @override
  double get rating;
  @override
  double get rd;
  @override
  @JsonKey(name: 'matches_played')
  int get matchesPlayed;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
