import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

enum RatingFormat {
  @JsonValue('S') singles,
  @JsonValue('D') doubles,
}

@freezed
class PlayerRating with _$PlayerRating {
  const factory PlayerRating({
    required RatingFormat format,
    required double rating,
    required double rd,
    @JsonKey(name: 'matches_played') required int matchesPlayed,
  }) = _PlayerRating;

  factory PlayerRating.fromJson(Map<String, dynamic> json) =>
      _$PlayerRatingFromJson(json);
}

@freezed
class Overall with _$Overall {
  const factory Overall({
    required double? rating,
    @JsonKey(name: 'matches_played') required int matchesPlayed,
  }) = _Overall;

  factory Overall.fromJson(Map<String, dynamic> json) =>
      _$OverallFromJson(json);
}

@freezed
class Player with _$Player {
  const factory Player({
    required String id,
    @JsonKey(name: 'phone_e164') required String phoneE164,
    @JsonKey(name: 'display_name') required String displayName,
    String? gender,
    DateTime? dob,
    @JsonKey(name: 'home_city') required String homeCity,
    required List<PlayerRating> ratings,
    required Overall overall,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
}
