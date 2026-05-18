import 'package:freezed_annotation/freezed_annotation.dart';

part 'match.freezed.dart';
part 'match.g.dart';

enum MatchFormat {
  @JsonValue('S') singles,
  @JsonValue('D') doubles,
}

enum MatchStatus {
  @JsonValue('pending') pending,
  @JsonValue('validated') validated,
  @JsonValue('disputed') disputed,
  @JsonValue('expired') expired,
}

@freezed
class Participant with _$Participant {
  const factory Participant({
    @JsonKey(name: 'player_id') String? playerId,
    @JsonKey(name: 'phone_e164') required String phoneE164,
    String? username,
    @JsonKey(name: 'display_name') String? displayName,
    required int team,
    @JsonKey(name: 'is_submitter') required bool isSubmitter,
    required bool confirmed,
    required bool disputed,
  }) = _Participant;

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
}

@freezed
class GameOut with _$GameOut {
  const factory GameOut({
    @JsonKey(name: 'game_no') required int gameNo,
    @JsonKey(name: 'team1_points') required int team1Points,
    @JsonKey(name: 'team2_points') required int team2Points,
  }) = _GameOut;

  factory GameOut.fromJson(Map<String, dynamic> json) =>
      _$GameOutFromJson(json);
}

@freezed
class RatingDelta with _$RatingDelta {
  const factory RatingDelta({
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'rating_before') required double ratingBefore,
    @JsonKey(name: 'rating_after') required double ratingAfter,
  }) = _RatingDelta;

  factory RatingDelta.fromJson(Map<String, dynamic> json) =>
      _$RatingDeltaFromJson(json);
}

@freezed
class MatchOut with _$MatchOut {
  const factory MatchOut({
    required String id,
    required MatchFormat format,
    @JsonKey(name: 'played_at') required DateTime playedAt,
    String? venue,
    required MatchStatus status,
    @JsonKey(name: 'validation_deadline') required DateTime validationDeadline,
    @JsonKey(name: 'validated_at') DateTime? validatedAt,
    required List<Participant> participants,
    required List<GameOut> games,
    @JsonKey(name: 'rating_deltas') required List<RatingDelta> ratingDeltas,
  }) = _MatchOut;

  factory MatchOut.fromJson(Map<String, dynamic> json) =>
      _$MatchOutFromJson(json);
}

@freezed
class GameIn with _$GameIn {
  const factory GameIn({
    @JsonKey(name: 'game_no') required int gameNo,
    @JsonKey(name: 'team1_points') required int team1Points,
    @JsonKey(name: 'team2_points') required int team2Points,
  }) = _GameIn;

  factory GameIn.fromJson(Map<String, dynamic> json) => _$GameInFromJson(json);
}

@freezed
class MatchSubmit with _$MatchSubmit {
  const factory MatchSubmit({
    required MatchFormat format,
    @JsonKey(name: 'played_at') required DateTime playedAt,
    String? venue,
    @JsonKey(name: 'team1_phones') required List<String> team1Phones,
    @JsonKey(name: 'team2_phones') required List<String> team2Phones,
    required List<GameIn> games,
  }) = _MatchSubmit;

  factory MatchSubmit.fromJson(Map<String, dynamic> json) =>
      _$MatchSubmitFromJson(json);
}
