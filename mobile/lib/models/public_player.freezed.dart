// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'public_player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PublicPlayer _$PublicPlayerFromJson(Map<String, dynamic> json) {
  return _PublicPlayer.fromJson(json);
}

/// @nodoc
mixin _$PublicPlayer {
  String get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  @JsonKey(name: 'home_city')
  String get homeCity => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  double get rd => throw _privateConstructorUsedError;
  @JsonKey(name: 'matches_played')
  int get matchesPlayed => throw _privateConstructorUsedError;
  int? get rank => throw _privateConstructorUsedError;

  /// Serializes this PublicPlayer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PublicPlayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PublicPlayerCopyWith<PublicPlayer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicPlayerCopyWith<$Res> {
  factory $PublicPlayerCopyWith(
          PublicPlayer value, $Res Function(PublicPlayer) then) =
      _$PublicPlayerCopyWithImpl<$Res, PublicPlayer>;
  @useResult
  $Res call(
      {String id,
      String username,
      @JsonKey(name: 'display_name') String displayName,
      String? gender,
      @JsonKey(name: 'home_city') String homeCity,
      double rating,
      double rd,
      @JsonKey(name: 'matches_played') int matchesPlayed,
      int? rank});
}

/// @nodoc
class _$PublicPlayerCopyWithImpl<$Res, $Val extends PublicPlayer>
    implements $PublicPlayerCopyWith<$Res> {
  _$PublicPlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PublicPlayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? displayName = null,
    Object? gender = freezed,
    Object? homeCity = null,
    Object? rating = null,
    Object? rd = null,
    Object? matchesPlayed = null,
    Object? rank = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      rank: freezed == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PublicPlayerImplCopyWith<$Res>
    implements $PublicPlayerCopyWith<$Res> {
  factory _$$PublicPlayerImplCopyWith(
          _$PublicPlayerImpl value, $Res Function(_$PublicPlayerImpl) then) =
      __$$PublicPlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String username,
      @JsonKey(name: 'display_name') String displayName,
      String? gender,
      @JsonKey(name: 'home_city') String homeCity,
      double rating,
      double rd,
      @JsonKey(name: 'matches_played') int matchesPlayed,
      int? rank});
}

/// @nodoc
class __$$PublicPlayerImplCopyWithImpl<$Res>
    extends _$PublicPlayerCopyWithImpl<$Res, _$PublicPlayerImpl>
    implements _$$PublicPlayerImplCopyWith<$Res> {
  __$$PublicPlayerImplCopyWithImpl(
      _$PublicPlayerImpl _value, $Res Function(_$PublicPlayerImpl) _then)
      : super(_value, _then);

  /// Create a copy of PublicPlayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? displayName = null,
    Object? gender = freezed,
    Object? homeCity = null,
    Object? rating = null,
    Object? rd = null,
    Object? matchesPlayed = null,
    Object? rank = freezed,
  }) {
    return _then(_$PublicPlayerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      rank: freezed == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PublicPlayerImpl implements _PublicPlayer {
  const _$PublicPlayerImpl(
      {required this.id,
      required this.username,
      @JsonKey(name: 'display_name') required this.displayName,
      this.gender,
      @JsonKey(name: 'home_city') required this.homeCity,
      required this.rating,
      required this.rd,
      @JsonKey(name: 'matches_played') required this.matchesPlayed,
      this.rank});

  factory _$PublicPlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PublicPlayerImplFromJson(json);

  @override
  final String id;
  @override
  final String username;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  final String? gender;
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
  final int? rank;

  @override
  String toString() {
    return 'PublicPlayer(id: $id, username: $username, displayName: $displayName, gender: $gender, homeCity: $homeCity, rating: $rating, rd: $rd, matchesPlayed: $matchesPlayed, rank: $rank)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PublicPlayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.homeCity, homeCity) ||
                other.homeCity == homeCity) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.rd, rd) || other.rd == rd) &&
            (identical(other.matchesPlayed, matchesPlayed) ||
                other.matchesPlayed == matchesPlayed) &&
            (identical(other.rank, rank) || other.rank == rank));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, username, displayName,
      gender, homeCity, rating, rd, matchesPlayed, rank);

  /// Create a copy of PublicPlayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PublicPlayerImplCopyWith<_$PublicPlayerImpl> get copyWith =>
      __$$PublicPlayerImplCopyWithImpl<_$PublicPlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PublicPlayerImplToJson(
      this,
    );
  }
}

abstract class _PublicPlayer implements PublicPlayer {
  const factory _PublicPlayer(
      {required final String id,
      required final String username,
      @JsonKey(name: 'display_name') required final String displayName,
      final String? gender,
      @JsonKey(name: 'home_city') required final String homeCity,
      required final double rating,
      required final double rd,
      @JsonKey(name: 'matches_played') required final int matchesPlayed,
      final int? rank}) = _$PublicPlayerImpl;

  factory _PublicPlayer.fromJson(Map<String, dynamic> json) =
      _$PublicPlayerImpl.fromJson;

  @override
  String get id;
  @override
  String get username;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  String? get gender;
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
  @override
  int? get rank;

  /// Create a copy of PublicPlayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PublicPlayerImplCopyWith<_$PublicPlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HeadToHead _$HeadToHeadFromJson(Map<String, dynamic> json) {
  return _HeadToHead.fromJson(json);
}

/// @nodoc
mixin _$HeadToHead {
  @JsonKey(name: 'me_wins')
  int get meWins => throw _privateConstructorUsedError;
  @JsonKey(name: 'opponent_wins')
  int get opponentWins => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_matches')
  List<MatchOut> get lastMatches => throw _privateConstructorUsedError;

  /// Serializes this HeadToHead to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HeadToHead
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HeadToHeadCopyWith<HeadToHead> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeadToHeadCopyWith<$Res> {
  factory $HeadToHeadCopyWith(
          HeadToHead value, $Res Function(HeadToHead) then) =
      _$HeadToHeadCopyWithImpl<$Res, HeadToHead>;
  @useResult
  $Res call(
      {@JsonKey(name: 'me_wins') int meWins,
      @JsonKey(name: 'opponent_wins') int opponentWins,
      @JsonKey(name: 'last_matches') List<MatchOut> lastMatches});
}

/// @nodoc
class _$HeadToHeadCopyWithImpl<$Res, $Val extends HeadToHead>
    implements $HeadToHeadCopyWith<$Res> {
  _$HeadToHeadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HeadToHead
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? meWins = null,
    Object? opponentWins = null,
    Object? lastMatches = null,
  }) {
    return _then(_value.copyWith(
      meWins: null == meWins
          ? _value.meWins
          : meWins // ignore: cast_nullable_to_non_nullable
              as int,
      opponentWins: null == opponentWins
          ? _value.opponentWins
          : opponentWins // ignore: cast_nullable_to_non_nullable
              as int,
      lastMatches: null == lastMatches
          ? _value.lastMatches
          : lastMatches // ignore: cast_nullable_to_non_nullable
              as List<MatchOut>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HeadToHeadImplCopyWith<$Res>
    implements $HeadToHeadCopyWith<$Res> {
  factory _$$HeadToHeadImplCopyWith(
          _$HeadToHeadImpl value, $Res Function(_$HeadToHeadImpl) then) =
      __$$HeadToHeadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'me_wins') int meWins,
      @JsonKey(name: 'opponent_wins') int opponentWins,
      @JsonKey(name: 'last_matches') List<MatchOut> lastMatches});
}

/// @nodoc
class __$$HeadToHeadImplCopyWithImpl<$Res>
    extends _$HeadToHeadCopyWithImpl<$Res, _$HeadToHeadImpl>
    implements _$$HeadToHeadImplCopyWith<$Res> {
  __$$HeadToHeadImplCopyWithImpl(
      _$HeadToHeadImpl _value, $Res Function(_$HeadToHeadImpl) _then)
      : super(_value, _then);

  /// Create a copy of HeadToHead
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? meWins = null,
    Object? opponentWins = null,
    Object? lastMatches = null,
  }) {
    return _then(_$HeadToHeadImpl(
      meWins: null == meWins
          ? _value.meWins
          : meWins // ignore: cast_nullable_to_non_nullable
              as int,
      opponentWins: null == opponentWins
          ? _value.opponentWins
          : opponentWins // ignore: cast_nullable_to_non_nullable
              as int,
      lastMatches: null == lastMatches
          ? _value._lastMatches
          : lastMatches // ignore: cast_nullable_to_non_nullable
              as List<MatchOut>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HeadToHeadImpl implements _HeadToHead {
  const _$HeadToHeadImpl(
      {@JsonKey(name: 'me_wins') required this.meWins,
      @JsonKey(name: 'opponent_wins') required this.opponentWins,
      @JsonKey(name: 'last_matches') required final List<MatchOut> lastMatches})
      : _lastMatches = lastMatches;

  factory _$HeadToHeadImpl.fromJson(Map<String, dynamic> json) =>
      _$$HeadToHeadImplFromJson(json);

  @override
  @JsonKey(name: 'me_wins')
  final int meWins;
  @override
  @JsonKey(name: 'opponent_wins')
  final int opponentWins;
  final List<MatchOut> _lastMatches;
  @override
  @JsonKey(name: 'last_matches')
  List<MatchOut> get lastMatches {
    if (_lastMatches is EqualUnmodifiableListView) return _lastMatches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lastMatches);
  }

  @override
  String toString() {
    return 'HeadToHead(meWins: $meWins, opponentWins: $opponentWins, lastMatches: $lastMatches)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HeadToHeadImpl &&
            (identical(other.meWins, meWins) || other.meWins == meWins) &&
            (identical(other.opponentWins, opponentWins) ||
                other.opponentWins == opponentWins) &&
            const DeepCollectionEquality()
                .equals(other._lastMatches, _lastMatches));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, meWins, opponentWins,
      const DeepCollectionEquality().hash(_lastMatches));

  /// Create a copy of HeadToHead
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HeadToHeadImplCopyWith<_$HeadToHeadImpl> get copyWith =>
      __$$HeadToHeadImplCopyWithImpl<_$HeadToHeadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HeadToHeadImplToJson(
      this,
    );
  }
}

abstract class _HeadToHead implements HeadToHead {
  const factory _HeadToHead(
      {@JsonKey(name: 'me_wins') required final int meWins,
      @JsonKey(name: 'opponent_wins') required final int opponentWins,
      @JsonKey(name: 'last_matches')
      required final List<MatchOut> lastMatches}) = _$HeadToHeadImpl;

  factory _HeadToHead.fromJson(Map<String, dynamic> json) =
      _$HeadToHeadImpl.fromJson;

  @override
  @JsonKey(name: 'me_wins')
  int get meWins;
  @override
  @JsonKey(name: 'opponent_wins')
  int get opponentWins;
  @override
  @JsonKey(name: 'last_matches')
  List<MatchOut> get lastMatches;

  /// Create a copy of HeadToHead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HeadToHeadImplCopyWith<_$HeadToHeadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
