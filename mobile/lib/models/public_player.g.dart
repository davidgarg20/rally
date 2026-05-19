// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PublicPlayerImpl _$$PublicPlayerImplFromJson(Map<String, dynamic> json) =>
    _$PublicPlayerImpl(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      gender: json['gender'] as String?,
      homeCity: json['home_city'] as String,
      ratings: (json['ratings'] as List<dynamic>)
          .map((e) => PlayerRating.fromJson(e as Map<String, dynamic>))
          .toList(),
      overall: Overall.fromJson(json['overall'] as Map<String, dynamic>),
      rank: (json['rank'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PublicPlayerImplToJson(_$PublicPlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'display_name': instance.displayName,
      'gender': instance.gender,
      'home_city': instance.homeCity,
      'ratings': instance.ratings,
      'overall': instance.overall,
      'rank': instance.rank,
    };

_$HeadToHeadImpl _$$HeadToHeadImplFromJson(Map<String, dynamic> json) =>
    _$HeadToHeadImpl(
      meWins: (json['me_wins'] as num).toInt(),
      opponentWins: (json['opponent_wins'] as num).toInt(),
      lastMatches: (json['last_matches'] as List<dynamic>)
          .map((e) => MatchOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$HeadToHeadImplToJson(_$HeadToHeadImpl instance) =>
    <String, dynamic>{
      'me_wins': instance.meWins,
      'opponent_wins': instance.opponentWins,
      'last_matches': instance.lastMatches,
    };
