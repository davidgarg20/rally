// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Participant _$ParticipantFromJson(Map<String, dynamic> json) {
  return _Participant.fromJson(json);
}

/// @nodoc
mixin _$Participant {
  @JsonKey(name: 'player_id')
  String? get playerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'phone_e164')
  String get phoneE164 => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String? get displayName => throw _privateConstructorUsedError;
  int get team => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_submitter')
  bool get isSubmitter => throw _privateConstructorUsedError;
  bool get confirmed => throw _privateConstructorUsedError;
  bool get disputed => throw _privateConstructorUsedError;

  /// Serializes this Participant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ParticipantCopyWith<Participant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ParticipantCopyWith<$Res> {
  factory $ParticipantCopyWith(
          Participant value, $Res Function(Participant) then) =
      _$ParticipantCopyWithImpl<$Res, Participant>;
  @useResult
  $Res call(
      {@JsonKey(name: 'player_id') String? playerId,
      @JsonKey(name: 'phone_e164') String phoneE164,
      @JsonKey(name: 'display_name') String? displayName,
      int team,
      @JsonKey(name: 'is_submitter') bool isSubmitter,
      bool confirmed,
      bool disputed});
}

/// @nodoc
class _$ParticipantCopyWithImpl<$Res, $Val extends Participant>
    implements $ParticipantCopyWith<$Res> {
  _$ParticipantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = freezed,
    Object? phoneE164 = null,
    Object? displayName = freezed,
    Object? team = null,
    Object? isSubmitter = null,
    Object? confirmed = null,
    Object? disputed = null,
  }) {
    return _then(_value.copyWith(
      playerId: freezed == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneE164: null == phoneE164
          ? _value.phoneE164
          : phoneE164 // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as int,
      isSubmitter: null == isSubmitter
          ? _value.isSubmitter
          : isSubmitter // ignore: cast_nullable_to_non_nullable
              as bool,
      confirmed: null == confirmed
          ? _value.confirmed
          : confirmed // ignore: cast_nullable_to_non_nullable
              as bool,
      disputed: null == disputed
          ? _value.disputed
          : disputed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ParticipantImplCopyWith<$Res>
    implements $ParticipantCopyWith<$Res> {
  factory _$$ParticipantImplCopyWith(
          _$ParticipantImpl value, $Res Function(_$ParticipantImpl) then) =
      __$$ParticipantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'player_id') String? playerId,
      @JsonKey(name: 'phone_e164') String phoneE164,
      @JsonKey(name: 'display_name') String? displayName,
      int team,
      @JsonKey(name: 'is_submitter') bool isSubmitter,
      bool confirmed,
      bool disputed});
}

/// @nodoc
class __$$ParticipantImplCopyWithImpl<$Res>
    extends _$ParticipantCopyWithImpl<$Res, _$ParticipantImpl>
    implements _$$ParticipantImplCopyWith<$Res> {
  __$$ParticipantImplCopyWithImpl(
      _$ParticipantImpl _value, $Res Function(_$ParticipantImpl) _then)
      : super(_value, _then);

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = freezed,
    Object? phoneE164 = null,
    Object? displayName = freezed,
    Object? team = null,
    Object? isSubmitter = null,
    Object? confirmed = null,
    Object? disputed = null,
  }) {
    return _then(_$ParticipantImpl(
      playerId: freezed == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneE164: null == phoneE164
          ? _value.phoneE164
          : phoneE164 // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as int,
      isSubmitter: null == isSubmitter
          ? _value.isSubmitter
          : isSubmitter // ignore: cast_nullable_to_non_nullable
              as bool,
      confirmed: null == confirmed
          ? _value.confirmed
          : confirmed // ignore: cast_nullable_to_non_nullable
              as bool,
      disputed: null == disputed
          ? _value.disputed
          : disputed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ParticipantImpl implements _Participant {
  const _$ParticipantImpl(
      {@JsonKey(name: 'player_id') this.playerId,
      @JsonKey(name: 'phone_e164') required this.phoneE164,
      @JsonKey(name: 'display_name') this.displayName,
      required this.team,
      @JsonKey(name: 'is_submitter') required this.isSubmitter,
      required this.confirmed,
      required this.disputed});

  factory _$ParticipantImpl.fromJson(Map<String, dynamic> json) =>
      _$$ParticipantImplFromJson(json);

  @override
  @JsonKey(name: 'player_id')
  final String? playerId;
  @override
  @JsonKey(name: 'phone_e164')
  final String phoneE164;
  @override
  @JsonKey(name: 'display_name')
  final String? displayName;
  @override
  final int team;
  @override
  @JsonKey(name: 'is_submitter')
  final bool isSubmitter;
  @override
  final bool confirmed;
  @override
  final bool disputed;

  @override
  String toString() {
    return 'Participant(playerId: $playerId, phoneE164: $phoneE164, displayName: $displayName, team: $team, isSubmitter: $isSubmitter, confirmed: $confirmed, disputed: $disputed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ParticipantImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.phoneE164, phoneE164) ||
                other.phoneE164 == phoneE164) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.team, team) || other.team == team) &&
            (identical(other.isSubmitter, isSubmitter) ||
                other.isSubmitter == isSubmitter) &&
            (identical(other.confirmed, confirmed) ||
                other.confirmed == confirmed) &&
            (identical(other.disputed, disputed) ||
                other.disputed == disputed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId, phoneE164, displayName,
      team, isSubmitter, confirmed, disputed);

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ParticipantImplCopyWith<_$ParticipantImpl> get copyWith =>
      __$$ParticipantImplCopyWithImpl<_$ParticipantImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ParticipantImplToJson(
      this,
    );
  }
}

abstract class _Participant implements Participant {
  const factory _Participant(
      {@JsonKey(name: 'player_id') final String? playerId,
      @JsonKey(name: 'phone_e164') required final String phoneE164,
      @JsonKey(name: 'display_name') final String? displayName,
      required final int team,
      @JsonKey(name: 'is_submitter') required final bool isSubmitter,
      required final bool confirmed,
      required final bool disputed}) = _$ParticipantImpl;

  factory _Participant.fromJson(Map<String, dynamic> json) =
      _$ParticipantImpl.fromJson;

  @override
  @JsonKey(name: 'player_id')
  String? get playerId;
  @override
  @JsonKey(name: 'phone_e164')
  String get phoneE164;
  @override
  @JsonKey(name: 'display_name')
  String? get displayName;
  @override
  int get team;
  @override
  @JsonKey(name: 'is_submitter')
  bool get isSubmitter;
  @override
  bool get confirmed;
  @override
  bool get disputed;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ParticipantImplCopyWith<_$ParticipantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GameOut _$GameOutFromJson(Map<String, dynamic> json) {
  return _GameOut.fromJson(json);
}

/// @nodoc
mixin _$GameOut {
  @JsonKey(name: 'game_no')
  int get gameNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'team1_points')
  int get team1Points => throw _privateConstructorUsedError;
  @JsonKey(name: 'team2_points')
  int get team2Points => throw _privateConstructorUsedError;

  /// Serializes this GameOut to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameOut
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameOutCopyWith<GameOut> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameOutCopyWith<$Res> {
  factory $GameOutCopyWith(GameOut value, $Res Function(GameOut) then) =
      _$GameOutCopyWithImpl<$Res, GameOut>;
  @useResult
  $Res call(
      {@JsonKey(name: 'game_no') int gameNo,
      @JsonKey(name: 'team1_points') int team1Points,
      @JsonKey(name: 'team2_points') int team2Points});
}

/// @nodoc
class _$GameOutCopyWithImpl<$Res, $Val extends GameOut>
    implements $GameOutCopyWith<$Res> {
  _$GameOutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameOut
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameNo = null,
    Object? team1Points = null,
    Object? team2Points = null,
  }) {
    return _then(_value.copyWith(
      gameNo: null == gameNo
          ? _value.gameNo
          : gameNo // ignore: cast_nullable_to_non_nullable
              as int,
      team1Points: null == team1Points
          ? _value.team1Points
          : team1Points // ignore: cast_nullable_to_non_nullable
              as int,
      team2Points: null == team2Points
          ? _value.team2Points
          : team2Points // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameOutImplCopyWith<$Res> implements $GameOutCopyWith<$Res> {
  factory _$$GameOutImplCopyWith(
          _$GameOutImpl value, $Res Function(_$GameOutImpl) then) =
      __$$GameOutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'game_no') int gameNo,
      @JsonKey(name: 'team1_points') int team1Points,
      @JsonKey(name: 'team2_points') int team2Points});
}

/// @nodoc
class __$$GameOutImplCopyWithImpl<$Res>
    extends _$GameOutCopyWithImpl<$Res, _$GameOutImpl>
    implements _$$GameOutImplCopyWith<$Res> {
  __$$GameOutImplCopyWithImpl(
      _$GameOutImpl _value, $Res Function(_$GameOutImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameOut
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameNo = null,
    Object? team1Points = null,
    Object? team2Points = null,
  }) {
    return _then(_$GameOutImpl(
      gameNo: null == gameNo
          ? _value.gameNo
          : gameNo // ignore: cast_nullable_to_non_nullable
              as int,
      team1Points: null == team1Points
          ? _value.team1Points
          : team1Points // ignore: cast_nullable_to_non_nullable
              as int,
      team2Points: null == team2Points
          ? _value.team2Points
          : team2Points // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameOutImpl implements _GameOut {
  const _$GameOutImpl(
      {@JsonKey(name: 'game_no') required this.gameNo,
      @JsonKey(name: 'team1_points') required this.team1Points,
      @JsonKey(name: 'team2_points') required this.team2Points});

  factory _$GameOutImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameOutImplFromJson(json);

  @override
  @JsonKey(name: 'game_no')
  final int gameNo;
  @override
  @JsonKey(name: 'team1_points')
  final int team1Points;
  @override
  @JsonKey(name: 'team2_points')
  final int team2Points;

  @override
  String toString() {
    return 'GameOut(gameNo: $gameNo, team1Points: $team1Points, team2Points: $team2Points)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameOutImpl &&
            (identical(other.gameNo, gameNo) || other.gameNo == gameNo) &&
            (identical(other.team1Points, team1Points) ||
                other.team1Points == team1Points) &&
            (identical(other.team2Points, team2Points) ||
                other.team2Points == team2Points));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, gameNo, team1Points, team2Points);

  /// Create a copy of GameOut
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameOutImplCopyWith<_$GameOutImpl> get copyWith =>
      __$$GameOutImplCopyWithImpl<_$GameOutImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameOutImplToJson(
      this,
    );
  }
}

abstract class _GameOut implements GameOut {
  const factory _GameOut(
          {@JsonKey(name: 'game_no') required final int gameNo,
          @JsonKey(name: 'team1_points') required final int team1Points,
          @JsonKey(name: 'team2_points') required final int team2Points}) =
      _$GameOutImpl;

  factory _GameOut.fromJson(Map<String, dynamic> json) = _$GameOutImpl.fromJson;

  @override
  @JsonKey(name: 'game_no')
  int get gameNo;
  @override
  @JsonKey(name: 'team1_points')
  int get team1Points;
  @override
  @JsonKey(name: 'team2_points')
  int get team2Points;

  /// Create a copy of GameOut
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameOutImplCopyWith<_$GameOutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RatingDelta _$RatingDeltaFromJson(Map<String, dynamic> json) {
  return _RatingDelta.fromJson(json);
}

/// @nodoc
mixin _$RatingDelta {
  @JsonKey(name: 'player_id')
  String get playerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'rating_before')
  double get ratingBefore => throw _privateConstructorUsedError;
  @JsonKey(name: 'rating_after')
  double get ratingAfter => throw _privateConstructorUsedError;

  /// Serializes this RatingDelta to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RatingDelta
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RatingDeltaCopyWith<RatingDelta> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RatingDeltaCopyWith<$Res> {
  factory $RatingDeltaCopyWith(
          RatingDelta value, $Res Function(RatingDelta) then) =
      _$RatingDeltaCopyWithImpl<$Res, RatingDelta>;
  @useResult
  $Res call(
      {@JsonKey(name: 'player_id') String playerId,
      @JsonKey(name: 'rating_before') double ratingBefore,
      @JsonKey(name: 'rating_after') double ratingAfter});
}

/// @nodoc
class _$RatingDeltaCopyWithImpl<$Res, $Val extends RatingDelta>
    implements $RatingDeltaCopyWith<$Res> {
  _$RatingDeltaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RatingDelta
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? ratingBefore = null,
    Object? ratingAfter = null,
  }) {
    return _then(_value.copyWith(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      ratingBefore: null == ratingBefore
          ? _value.ratingBefore
          : ratingBefore // ignore: cast_nullable_to_non_nullable
              as double,
      ratingAfter: null == ratingAfter
          ? _value.ratingAfter
          : ratingAfter // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RatingDeltaImplCopyWith<$Res>
    implements $RatingDeltaCopyWith<$Res> {
  factory _$$RatingDeltaImplCopyWith(
          _$RatingDeltaImpl value, $Res Function(_$RatingDeltaImpl) then) =
      __$$RatingDeltaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'player_id') String playerId,
      @JsonKey(name: 'rating_before') double ratingBefore,
      @JsonKey(name: 'rating_after') double ratingAfter});
}

/// @nodoc
class __$$RatingDeltaImplCopyWithImpl<$Res>
    extends _$RatingDeltaCopyWithImpl<$Res, _$RatingDeltaImpl>
    implements _$$RatingDeltaImplCopyWith<$Res> {
  __$$RatingDeltaImplCopyWithImpl(
      _$RatingDeltaImpl _value, $Res Function(_$RatingDeltaImpl) _then)
      : super(_value, _then);

  /// Create a copy of RatingDelta
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? ratingBefore = null,
    Object? ratingAfter = null,
  }) {
    return _then(_$RatingDeltaImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      ratingBefore: null == ratingBefore
          ? _value.ratingBefore
          : ratingBefore // ignore: cast_nullable_to_non_nullable
              as double,
      ratingAfter: null == ratingAfter
          ? _value.ratingAfter
          : ratingAfter // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RatingDeltaImpl implements _RatingDelta {
  const _$RatingDeltaImpl(
      {@JsonKey(name: 'player_id') required this.playerId,
      @JsonKey(name: 'rating_before') required this.ratingBefore,
      @JsonKey(name: 'rating_after') required this.ratingAfter});

  factory _$RatingDeltaImpl.fromJson(Map<String, dynamic> json) =>
      _$$RatingDeltaImplFromJson(json);

  @override
  @JsonKey(name: 'player_id')
  final String playerId;
  @override
  @JsonKey(name: 'rating_before')
  final double ratingBefore;
  @override
  @JsonKey(name: 'rating_after')
  final double ratingAfter;

  @override
  String toString() {
    return 'RatingDelta(playerId: $playerId, ratingBefore: $ratingBefore, ratingAfter: $ratingAfter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RatingDeltaImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.ratingBefore, ratingBefore) ||
                other.ratingBefore == ratingBefore) &&
            (identical(other.ratingAfter, ratingAfter) ||
                other.ratingAfter == ratingAfter));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, playerId, ratingBefore, ratingAfter);

  /// Create a copy of RatingDelta
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RatingDeltaImplCopyWith<_$RatingDeltaImpl> get copyWith =>
      __$$RatingDeltaImplCopyWithImpl<_$RatingDeltaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RatingDeltaImplToJson(
      this,
    );
  }
}

abstract class _RatingDelta implements RatingDelta {
  const factory _RatingDelta(
          {@JsonKey(name: 'player_id') required final String playerId,
          @JsonKey(name: 'rating_before') required final double ratingBefore,
          @JsonKey(name: 'rating_after') required final double ratingAfter}) =
      _$RatingDeltaImpl;

  factory _RatingDelta.fromJson(Map<String, dynamic> json) =
      _$RatingDeltaImpl.fromJson;

  @override
  @JsonKey(name: 'player_id')
  String get playerId;
  @override
  @JsonKey(name: 'rating_before')
  double get ratingBefore;
  @override
  @JsonKey(name: 'rating_after')
  double get ratingAfter;

  /// Create a copy of RatingDelta
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RatingDeltaImplCopyWith<_$RatingDeltaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MatchOut _$MatchOutFromJson(Map<String, dynamic> json) {
  return _MatchOut.fromJson(json);
}

/// @nodoc
mixin _$MatchOut {
  String get id => throw _privateConstructorUsedError;
  MatchFormat get format => throw _privateConstructorUsedError;
  @JsonKey(name: 'played_at')
  DateTime get playedAt => throw _privateConstructorUsedError;
  String? get venue => throw _privateConstructorUsedError;
  MatchStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'validation_deadline')
  DateTime get validationDeadline => throw _privateConstructorUsedError;
  @JsonKey(name: 'validated_at')
  DateTime? get validatedAt => throw _privateConstructorUsedError;
  List<Participant> get participants => throw _privateConstructorUsedError;
  List<GameOut> get games => throw _privateConstructorUsedError;
  @JsonKey(name: 'rating_deltas')
  List<RatingDelta> get ratingDeltas => throw _privateConstructorUsedError;

  /// Serializes this MatchOut to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatchOut
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchOutCopyWith<MatchOut> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchOutCopyWith<$Res> {
  factory $MatchOutCopyWith(MatchOut value, $Res Function(MatchOut) then) =
      _$MatchOutCopyWithImpl<$Res, MatchOut>;
  @useResult
  $Res call(
      {String id,
      MatchFormat format,
      @JsonKey(name: 'played_at') DateTime playedAt,
      String? venue,
      MatchStatus status,
      @JsonKey(name: 'validation_deadline') DateTime validationDeadline,
      @JsonKey(name: 'validated_at') DateTime? validatedAt,
      List<Participant> participants,
      List<GameOut> games,
      @JsonKey(name: 'rating_deltas') List<RatingDelta> ratingDeltas});
}

/// @nodoc
class _$MatchOutCopyWithImpl<$Res, $Val extends MatchOut>
    implements $MatchOutCopyWith<$Res> {
  _$MatchOutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatchOut
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? format = null,
    Object? playedAt = null,
    Object? venue = freezed,
    Object? status = null,
    Object? validationDeadline = null,
    Object? validatedAt = freezed,
    Object? participants = null,
    Object? games = null,
    Object? ratingDeltas = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as MatchFormat,
      playedAt: null == playedAt
          ? _value.playedAt
          : playedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      venue: freezed == venue
          ? _value.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MatchStatus,
      validationDeadline: null == validationDeadline
          ? _value.validationDeadline
          : validationDeadline // ignore: cast_nullable_to_non_nullable
              as DateTime,
      validatedAt: freezed == validatedAt
          ? _value.validatedAt
          : validatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      participants: null == participants
          ? _value.participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<Participant>,
      games: null == games
          ? _value.games
          : games // ignore: cast_nullable_to_non_nullable
              as List<GameOut>,
      ratingDeltas: null == ratingDeltas
          ? _value.ratingDeltas
          : ratingDeltas // ignore: cast_nullable_to_non_nullable
              as List<RatingDelta>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MatchOutImplCopyWith<$Res>
    implements $MatchOutCopyWith<$Res> {
  factory _$$MatchOutImplCopyWith(
          _$MatchOutImpl value, $Res Function(_$MatchOutImpl) then) =
      __$$MatchOutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      MatchFormat format,
      @JsonKey(name: 'played_at') DateTime playedAt,
      String? venue,
      MatchStatus status,
      @JsonKey(name: 'validation_deadline') DateTime validationDeadline,
      @JsonKey(name: 'validated_at') DateTime? validatedAt,
      List<Participant> participants,
      List<GameOut> games,
      @JsonKey(name: 'rating_deltas') List<RatingDelta> ratingDeltas});
}

/// @nodoc
class __$$MatchOutImplCopyWithImpl<$Res>
    extends _$MatchOutCopyWithImpl<$Res, _$MatchOutImpl>
    implements _$$MatchOutImplCopyWith<$Res> {
  __$$MatchOutImplCopyWithImpl(
      _$MatchOutImpl _value, $Res Function(_$MatchOutImpl) _then)
      : super(_value, _then);

  /// Create a copy of MatchOut
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? format = null,
    Object? playedAt = null,
    Object? venue = freezed,
    Object? status = null,
    Object? validationDeadline = null,
    Object? validatedAt = freezed,
    Object? participants = null,
    Object? games = null,
    Object? ratingDeltas = null,
  }) {
    return _then(_$MatchOutImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as MatchFormat,
      playedAt: null == playedAt
          ? _value.playedAt
          : playedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      venue: freezed == venue
          ? _value.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MatchStatus,
      validationDeadline: null == validationDeadline
          ? _value.validationDeadline
          : validationDeadline // ignore: cast_nullable_to_non_nullable
              as DateTime,
      validatedAt: freezed == validatedAt
          ? _value.validatedAt
          : validatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      participants: null == participants
          ? _value._participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<Participant>,
      games: null == games
          ? _value._games
          : games // ignore: cast_nullable_to_non_nullable
              as List<GameOut>,
      ratingDeltas: null == ratingDeltas
          ? _value._ratingDeltas
          : ratingDeltas // ignore: cast_nullable_to_non_nullable
              as List<RatingDelta>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchOutImpl implements _MatchOut {
  const _$MatchOutImpl(
      {required this.id,
      required this.format,
      @JsonKey(name: 'played_at') required this.playedAt,
      this.venue,
      required this.status,
      @JsonKey(name: 'validation_deadline') required this.validationDeadline,
      @JsonKey(name: 'validated_at') this.validatedAt,
      required final List<Participant> participants,
      required final List<GameOut> games,
      @JsonKey(name: 'rating_deltas')
      required final List<RatingDelta> ratingDeltas})
      : _participants = participants,
        _games = games,
        _ratingDeltas = ratingDeltas;

  factory _$MatchOutImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchOutImplFromJson(json);

  @override
  final String id;
  @override
  final MatchFormat format;
  @override
  @JsonKey(name: 'played_at')
  final DateTime playedAt;
  @override
  final String? venue;
  @override
  final MatchStatus status;
  @override
  @JsonKey(name: 'validation_deadline')
  final DateTime validationDeadline;
  @override
  @JsonKey(name: 'validated_at')
  final DateTime? validatedAt;
  final List<Participant> _participants;
  @override
  List<Participant> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  final List<GameOut> _games;
  @override
  List<GameOut> get games {
    if (_games is EqualUnmodifiableListView) return _games;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_games);
  }

  final List<RatingDelta> _ratingDeltas;
  @override
  @JsonKey(name: 'rating_deltas')
  List<RatingDelta> get ratingDeltas {
    if (_ratingDeltas is EqualUnmodifiableListView) return _ratingDeltas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ratingDeltas);
  }

  @override
  String toString() {
    return 'MatchOut(id: $id, format: $format, playedAt: $playedAt, venue: $venue, status: $status, validationDeadline: $validationDeadline, validatedAt: $validatedAt, participants: $participants, games: $games, ratingDeltas: $ratingDeltas)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchOutImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.playedAt, playedAt) ||
                other.playedAt == playedAt) &&
            (identical(other.venue, venue) || other.venue == venue) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.validationDeadline, validationDeadline) ||
                other.validationDeadline == validationDeadline) &&
            (identical(other.validatedAt, validatedAt) ||
                other.validatedAt == validatedAt) &&
            const DeepCollectionEquality()
                .equals(other._participants, _participants) &&
            const DeepCollectionEquality().equals(other._games, _games) &&
            const DeepCollectionEquality()
                .equals(other._ratingDeltas, _ratingDeltas));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      format,
      playedAt,
      venue,
      status,
      validationDeadline,
      validatedAt,
      const DeepCollectionEquality().hash(_participants),
      const DeepCollectionEquality().hash(_games),
      const DeepCollectionEquality().hash(_ratingDeltas));

  /// Create a copy of MatchOut
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchOutImplCopyWith<_$MatchOutImpl> get copyWith =>
      __$$MatchOutImplCopyWithImpl<_$MatchOutImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchOutImplToJson(
      this,
    );
  }
}

abstract class _MatchOut implements MatchOut {
  const factory _MatchOut(
      {required final String id,
      required final MatchFormat format,
      @JsonKey(name: 'played_at') required final DateTime playedAt,
      final String? venue,
      required final MatchStatus status,
      @JsonKey(name: 'validation_deadline')
      required final DateTime validationDeadline,
      @JsonKey(name: 'validated_at') final DateTime? validatedAt,
      required final List<Participant> participants,
      required final List<GameOut> games,
      @JsonKey(name: 'rating_deltas')
      required final List<RatingDelta> ratingDeltas}) = _$MatchOutImpl;

  factory _MatchOut.fromJson(Map<String, dynamic> json) =
      _$MatchOutImpl.fromJson;

  @override
  String get id;
  @override
  MatchFormat get format;
  @override
  @JsonKey(name: 'played_at')
  DateTime get playedAt;
  @override
  String? get venue;
  @override
  MatchStatus get status;
  @override
  @JsonKey(name: 'validation_deadline')
  DateTime get validationDeadline;
  @override
  @JsonKey(name: 'validated_at')
  DateTime? get validatedAt;
  @override
  List<Participant> get participants;
  @override
  List<GameOut> get games;
  @override
  @JsonKey(name: 'rating_deltas')
  List<RatingDelta> get ratingDeltas;

  /// Create a copy of MatchOut
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchOutImplCopyWith<_$MatchOutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GameIn _$GameInFromJson(Map<String, dynamic> json) {
  return _GameIn.fromJson(json);
}

/// @nodoc
mixin _$GameIn {
  @JsonKey(name: 'game_no')
  int get gameNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'team1_points')
  int get team1Points => throw _privateConstructorUsedError;
  @JsonKey(name: 'team2_points')
  int get team2Points => throw _privateConstructorUsedError;

  /// Serializes this GameIn to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameIn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameInCopyWith<GameIn> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameInCopyWith<$Res> {
  factory $GameInCopyWith(GameIn value, $Res Function(GameIn) then) =
      _$GameInCopyWithImpl<$Res, GameIn>;
  @useResult
  $Res call(
      {@JsonKey(name: 'game_no') int gameNo,
      @JsonKey(name: 'team1_points') int team1Points,
      @JsonKey(name: 'team2_points') int team2Points});
}

/// @nodoc
class _$GameInCopyWithImpl<$Res, $Val extends GameIn>
    implements $GameInCopyWith<$Res> {
  _$GameInCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameIn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameNo = null,
    Object? team1Points = null,
    Object? team2Points = null,
  }) {
    return _then(_value.copyWith(
      gameNo: null == gameNo
          ? _value.gameNo
          : gameNo // ignore: cast_nullable_to_non_nullable
              as int,
      team1Points: null == team1Points
          ? _value.team1Points
          : team1Points // ignore: cast_nullable_to_non_nullable
              as int,
      team2Points: null == team2Points
          ? _value.team2Points
          : team2Points // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameInImplCopyWith<$Res> implements $GameInCopyWith<$Res> {
  factory _$$GameInImplCopyWith(
          _$GameInImpl value, $Res Function(_$GameInImpl) then) =
      __$$GameInImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'game_no') int gameNo,
      @JsonKey(name: 'team1_points') int team1Points,
      @JsonKey(name: 'team2_points') int team2Points});
}

/// @nodoc
class __$$GameInImplCopyWithImpl<$Res>
    extends _$GameInCopyWithImpl<$Res, _$GameInImpl>
    implements _$$GameInImplCopyWith<$Res> {
  __$$GameInImplCopyWithImpl(
      _$GameInImpl _value, $Res Function(_$GameInImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameIn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameNo = null,
    Object? team1Points = null,
    Object? team2Points = null,
  }) {
    return _then(_$GameInImpl(
      gameNo: null == gameNo
          ? _value.gameNo
          : gameNo // ignore: cast_nullable_to_non_nullable
              as int,
      team1Points: null == team1Points
          ? _value.team1Points
          : team1Points // ignore: cast_nullable_to_non_nullable
              as int,
      team2Points: null == team2Points
          ? _value.team2Points
          : team2Points // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameInImpl implements _GameIn {
  const _$GameInImpl(
      {@JsonKey(name: 'game_no') required this.gameNo,
      @JsonKey(name: 'team1_points') required this.team1Points,
      @JsonKey(name: 'team2_points') required this.team2Points});

  factory _$GameInImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameInImplFromJson(json);

  @override
  @JsonKey(name: 'game_no')
  final int gameNo;
  @override
  @JsonKey(name: 'team1_points')
  final int team1Points;
  @override
  @JsonKey(name: 'team2_points')
  final int team2Points;

  @override
  String toString() {
    return 'GameIn(gameNo: $gameNo, team1Points: $team1Points, team2Points: $team2Points)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameInImpl &&
            (identical(other.gameNo, gameNo) || other.gameNo == gameNo) &&
            (identical(other.team1Points, team1Points) ||
                other.team1Points == team1Points) &&
            (identical(other.team2Points, team2Points) ||
                other.team2Points == team2Points));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, gameNo, team1Points, team2Points);

  /// Create a copy of GameIn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameInImplCopyWith<_$GameInImpl> get copyWith =>
      __$$GameInImplCopyWithImpl<_$GameInImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameInImplToJson(
      this,
    );
  }
}

abstract class _GameIn implements GameIn {
  const factory _GameIn(
          {@JsonKey(name: 'game_no') required final int gameNo,
          @JsonKey(name: 'team1_points') required final int team1Points,
          @JsonKey(name: 'team2_points') required final int team2Points}) =
      _$GameInImpl;

  factory _GameIn.fromJson(Map<String, dynamic> json) = _$GameInImpl.fromJson;

  @override
  @JsonKey(name: 'game_no')
  int get gameNo;
  @override
  @JsonKey(name: 'team1_points')
  int get team1Points;
  @override
  @JsonKey(name: 'team2_points')
  int get team2Points;

  /// Create a copy of GameIn
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameInImplCopyWith<_$GameInImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MatchSubmit _$MatchSubmitFromJson(Map<String, dynamic> json) {
  return _MatchSubmit.fromJson(json);
}

/// @nodoc
mixin _$MatchSubmit {
  MatchFormat get format => throw _privateConstructorUsedError;
  @JsonKey(name: 'played_at')
  DateTime get playedAt => throw _privateConstructorUsedError;
  String? get venue => throw _privateConstructorUsedError;
  @JsonKey(name: 'team1_phones')
  List<String> get team1Phones => throw _privateConstructorUsedError;
  @JsonKey(name: 'team2_phones')
  List<String> get team2Phones => throw _privateConstructorUsedError;
  List<GameIn> get games => throw _privateConstructorUsedError;

  /// Serializes this MatchSubmit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatchSubmit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchSubmitCopyWith<MatchSubmit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchSubmitCopyWith<$Res> {
  factory $MatchSubmitCopyWith(
          MatchSubmit value, $Res Function(MatchSubmit) then) =
      _$MatchSubmitCopyWithImpl<$Res, MatchSubmit>;
  @useResult
  $Res call(
      {MatchFormat format,
      @JsonKey(name: 'played_at') DateTime playedAt,
      String? venue,
      @JsonKey(name: 'team1_phones') List<String> team1Phones,
      @JsonKey(name: 'team2_phones') List<String> team2Phones,
      List<GameIn> games});
}

/// @nodoc
class _$MatchSubmitCopyWithImpl<$Res, $Val extends MatchSubmit>
    implements $MatchSubmitCopyWith<$Res> {
  _$MatchSubmitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatchSubmit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? format = null,
    Object? playedAt = null,
    Object? venue = freezed,
    Object? team1Phones = null,
    Object? team2Phones = null,
    Object? games = null,
  }) {
    return _then(_value.copyWith(
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as MatchFormat,
      playedAt: null == playedAt
          ? _value.playedAt
          : playedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      venue: freezed == venue
          ? _value.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as String?,
      team1Phones: null == team1Phones
          ? _value.team1Phones
          : team1Phones // ignore: cast_nullable_to_non_nullable
              as List<String>,
      team2Phones: null == team2Phones
          ? _value.team2Phones
          : team2Phones // ignore: cast_nullable_to_non_nullable
              as List<String>,
      games: null == games
          ? _value.games
          : games // ignore: cast_nullable_to_non_nullable
              as List<GameIn>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MatchSubmitImplCopyWith<$Res>
    implements $MatchSubmitCopyWith<$Res> {
  factory _$$MatchSubmitImplCopyWith(
          _$MatchSubmitImpl value, $Res Function(_$MatchSubmitImpl) then) =
      __$$MatchSubmitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {MatchFormat format,
      @JsonKey(name: 'played_at') DateTime playedAt,
      String? venue,
      @JsonKey(name: 'team1_phones') List<String> team1Phones,
      @JsonKey(name: 'team2_phones') List<String> team2Phones,
      List<GameIn> games});
}

/// @nodoc
class __$$MatchSubmitImplCopyWithImpl<$Res>
    extends _$MatchSubmitCopyWithImpl<$Res, _$MatchSubmitImpl>
    implements _$$MatchSubmitImplCopyWith<$Res> {
  __$$MatchSubmitImplCopyWithImpl(
      _$MatchSubmitImpl _value, $Res Function(_$MatchSubmitImpl) _then)
      : super(_value, _then);

  /// Create a copy of MatchSubmit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? format = null,
    Object? playedAt = null,
    Object? venue = freezed,
    Object? team1Phones = null,
    Object? team2Phones = null,
    Object? games = null,
  }) {
    return _then(_$MatchSubmitImpl(
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as MatchFormat,
      playedAt: null == playedAt
          ? _value.playedAt
          : playedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      venue: freezed == venue
          ? _value.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as String?,
      team1Phones: null == team1Phones
          ? _value._team1Phones
          : team1Phones // ignore: cast_nullable_to_non_nullable
              as List<String>,
      team2Phones: null == team2Phones
          ? _value._team2Phones
          : team2Phones // ignore: cast_nullable_to_non_nullable
              as List<String>,
      games: null == games
          ? _value._games
          : games // ignore: cast_nullable_to_non_nullable
              as List<GameIn>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchSubmitImpl implements _MatchSubmit {
  const _$MatchSubmitImpl(
      {required this.format,
      @JsonKey(name: 'played_at') required this.playedAt,
      this.venue,
      @JsonKey(name: 'team1_phones') required final List<String> team1Phones,
      @JsonKey(name: 'team2_phones') required final List<String> team2Phones,
      required final List<GameIn> games})
      : _team1Phones = team1Phones,
        _team2Phones = team2Phones,
        _games = games;

  factory _$MatchSubmitImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchSubmitImplFromJson(json);

  @override
  final MatchFormat format;
  @override
  @JsonKey(name: 'played_at')
  final DateTime playedAt;
  @override
  final String? venue;
  final List<String> _team1Phones;
  @override
  @JsonKey(name: 'team1_phones')
  List<String> get team1Phones {
    if (_team1Phones is EqualUnmodifiableListView) return _team1Phones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_team1Phones);
  }

  final List<String> _team2Phones;
  @override
  @JsonKey(name: 'team2_phones')
  List<String> get team2Phones {
    if (_team2Phones is EqualUnmodifiableListView) return _team2Phones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_team2Phones);
  }

  final List<GameIn> _games;
  @override
  List<GameIn> get games {
    if (_games is EqualUnmodifiableListView) return _games;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_games);
  }

  @override
  String toString() {
    return 'MatchSubmit(format: $format, playedAt: $playedAt, venue: $venue, team1Phones: $team1Phones, team2Phones: $team2Phones, games: $games)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchSubmitImpl &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.playedAt, playedAt) ||
                other.playedAt == playedAt) &&
            (identical(other.venue, venue) || other.venue == venue) &&
            const DeepCollectionEquality()
                .equals(other._team1Phones, _team1Phones) &&
            const DeepCollectionEquality()
                .equals(other._team2Phones, _team2Phones) &&
            const DeepCollectionEquality().equals(other._games, _games));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      format,
      playedAt,
      venue,
      const DeepCollectionEquality().hash(_team1Phones),
      const DeepCollectionEquality().hash(_team2Phones),
      const DeepCollectionEquality().hash(_games));

  /// Create a copy of MatchSubmit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchSubmitImplCopyWith<_$MatchSubmitImpl> get copyWith =>
      __$$MatchSubmitImplCopyWithImpl<_$MatchSubmitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchSubmitImplToJson(
      this,
    );
  }
}

abstract class _MatchSubmit implements MatchSubmit {
  const factory _MatchSubmit(
      {required final MatchFormat format,
      @JsonKey(name: 'played_at') required final DateTime playedAt,
      final String? venue,
      @JsonKey(name: 'team1_phones') required final List<String> team1Phones,
      @JsonKey(name: 'team2_phones') required final List<String> team2Phones,
      required final List<GameIn> games}) = _$MatchSubmitImpl;

  factory _MatchSubmit.fromJson(Map<String, dynamic> json) =
      _$MatchSubmitImpl.fromJson;

  @override
  MatchFormat get format;
  @override
  @JsonKey(name: 'played_at')
  DateTime get playedAt;
  @override
  String? get venue;
  @override
  @JsonKey(name: 'team1_phones')
  List<String> get team1Phones;
  @override
  @JsonKey(name: 'team2_phones')
  List<String> get team2Phones;
  @override
  List<GameIn> get games;

  /// Create a copy of MatchSubmit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchSubmitImplCopyWith<_$MatchSubmitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
