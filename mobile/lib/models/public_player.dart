import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:rally/models/match.dart';
import 'package:rally/models/player.dart';

part 'public_player.freezed.dart';
part 'public_player.g.dart';

/// Public-facing player profile. No phone, no DOB.
@freezed
class PublicPlayer with _$PublicPlayer {
  const factory PublicPlayer({
    required String id,
    required String username,
    @JsonKey(name: 'display_name') required String displayName,
    String? gender,
    @JsonKey(name: 'home_city') required String homeCity,
    required List<PlayerRating> ratings,
    required Overall overall,
    int? rank,
  }) = _PublicPlayer;

  factory PublicPlayer.fromJson(Map<String, dynamic> json) =>
      _$PublicPlayerFromJson(json);
}

/// Stats between the current user and a target player.
@freezed
class HeadToHead with _$HeadToHead {
  const factory HeadToHead({
    @JsonKey(name: 'me_wins') required int meWins,
    @JsonKey(name: 'opponent_wins') required int opponentWins,
    @JsonKey(name: 'last_matches') required List<MatchOut> lastMatches,
  }) = _HeadToHead;

  factory HeadToHead.fromJson(Map<String, dynamic> json) =>
      _$HeadToHeadFromJson(json);
}
