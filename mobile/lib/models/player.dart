import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class Player with _$Player {
  const factory Player({
    required String id,
    @JsonKey(name: 'phone_e164') required String phoneE164,
    required String username,
    @JsonKey(name: 'display_name') required String displayName,
    String? gender,
    DateTime? dob,
    @JsonKey(name: 'home_city') required String homeCity,
    required double rating,
    required double rd,
    @JsonKey(name: 'matches_played') required int matchesPlayed,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
}
