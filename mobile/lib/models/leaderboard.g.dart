// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LeaderboardEntryImpl _$$LeaderboardEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$LeaderboardEntryImpl(
      rank: (json['rank'] as num).toInt(),
      playerId: json['player_id'] as String,
      displayName: json['display_name'] as String,
      rating: (json['rating'] as num).toDouble(),
      matchesPlayed: (json['matches_played'] as num).toInt(),
    );

Map<String, dynamic> _$$LeaderboardEntryImplToJson(
        _$LeaderboardEntryImpl instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'player_id': instance.playerId,
      'display_name': instance.displayName,
      'rating': instance.rating,
      'matches_played': instance.matchesPlayed,
    };

_$LeaderboardResponseImpl _$$LeaderboardResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$LeaderboardResponseImpl(
      gender: json['gender'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$LeaderboardResponseImplToJson(
        _$LeaderboardResponseImpl instance) =>
    <String, dynamic>{
      'gender': instance.gender,
      'entries': instance.entries,
    };
