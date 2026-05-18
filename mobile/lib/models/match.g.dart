// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ParticipantImpl _$$ParticipantImplFromJson(Map<String, dynamic> json) =>
    _$ParticipantImpl(
      playerId: json['player_id'] as String?,
      phoneE164: json['phone_e164'] as String,
      displayName: json['display_name'] as String?,
      team: (json['team'] as num).toInt(),
      isSubmitter: json['is_submitter'] as bool,
      confirmed: json['confirmed'] as bool,
      disputed: json['disputed'] as bool,
    );

Map<String, dynamic> _$$ParticipantImplToJson(_$ParticipantImpl instance) =>
    <String, dynamic>{
      'player_id': instance.playerId,
      'phone_e164': instance.phoneE164,
      'display_name': instance.displayName,
      'team': instance.team,
      'is_submitter': instance.isSubmitter,
      'confirmed': instance.confirmed,
      'disputed': instance.disputed,
    };

_$GameOutImpl _$$GameOutImplFromJson(Map<String, dynamic> json) =>
    _$GameOutImpl(
      gameNo: (json['game_no'] as num).toInt(),
      team1Points: (json['team1_points'] as num).toInt(),
      team2Points: (json['team2_points'] as num).toInt(),
    );

Map<String, dynamic> _$$GameOutImplToJson(_$GameOutImpl instance) =>
    <String, dynamic>{
      'game_no': instance.gameNo,
      'team1_points': instance.team1Points,
      'team2_points': instance.team2Points,
    };

_$RatingDeltaImpl _$$RatingDeltaImplFromJson(Map<String, dynamic> json) =>
    _$RatingDeltaImpl(
      playerId: json['player_id'] as String,
      ratingBefore: (json['rating_before'] as num).toDouble(),
      ratingAfter: (json['rating_after'] as num).toDouble(),
    );

Map<String, dynamic> _$$RatingDeltaImplToJson(_$RatingDeltaImpl instance) =>
    <String, dynamic>{
      'player_id': instance.playerId,
      'rating_before': instance.ratingBefore,
      'rating_after': instance.ratingAfter,
    };

_$MatchOutImpl _$$MatchOutImplFromJson(Map<String, dynamic> json) =>
    _$MatchOutImpl(
      id: json['id'] as String,
      format: $enumDecode(_$MatchFormatEnumMap, json['format']),
      playedAt: DateTime.parse(json['played_at'] as String),
      venue: json['venue'] as String?,
      status: $enumDecode(_$MatchStatusEnumMap, json['status']),
      validationDeadline: DateTime.parse(json['validation_deadline'] as String),
      validatedAt: json['validated_at'] == null
          ? null
          : DateTime.parse(json['validated_at'] as String),
      participants: (json['participants'] as List<dynamic>)
          .map((e) => Participant.fromJson(e as Map<String, dynamic>))
          .toList(),
      games: (json['games'] as List<dynamic>)
          .map((e) => GameOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      ratingDeltas: (json['rating_deltas'] as List<dynamic>)
          .map((e) => RatingDelta.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MatchOutImplToJson(_$MatchOutImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'format': _$MatchFormatEnumMap[instance.format]!,
      'played_at': instance.playedAt.toIso8601String(),
      'venue': instance.venue,
      'status': _$MatchStatusEnumMap[instance.status]!,
      'validation_deadline': instance.validationDeadline.toIso8601String(),
      'validated_at': instance.validatedAt?.toIso8601String(),
      'participants': instance.participants,
      'games': instance.games,
      'rating_deltas': instance.ratingDeltas,
    };

const _$MatchFormatEnumMap = {
  MatchFormat.singles: 'S',
  MatchFormat.doubles: 'D',
};

const _$MatchStatusEnumMap = {
  MatchStatus.pending: 'pending',
  MatchStatus.validated: 'validated',
  MatchStatus.disputed: 'disputed',
  MatchStatus.expired: 'expired',
};

_$GameInImpl _$$GameInImplFromJson(Map<String, dynamic> json) => _$GameInImpl(
      gameNo: (json['game_no'] as num).toInt(),
      team1Points: (json['team1_points'] as num).toInt(),
      team2Points: (json['team2_points'] as num).toInt(),
    );

Map<String, dynamic> _$$GameInImplToJson(_$GameInImpl instance) =>
    <String, dynamic>{
      'game_no': instance.gameNo,
      'team1_points': instance.team1Points,
      'team2_points': instance.team2Points,
    };

_$MatchSubmitImpl _$$MatchSubmitImplFromJson(Map<String, dynamic> json) =>
    _$MatchSubmitImpl(
      format: $enumDecode(_$MatchFormatEnumMap, json['format']),
      playedAt: DateTime.parse(json['played_at'] as String),
      venue: json['venue'] as String?,
      team1Phones: (json['team1_phones'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      team2Phones: (json['team2_phones'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      games: (json['games'] as List<dynamic>)
          .map((e) => GameIn.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MatchSubmitImplToJson(_$MatchSubmitImpl instance) =>
    <String, dynamic>{
      'format': _$MatchFormatEnumMap[instance.format]!,
      'played_at': instance.playedAt.toIso8601String(),
      'venue': instance.venue,
      'team1_phones': instance.team1Phones,
      'team2_phones': instance.team2Phones,
      'games': instance.games,
    };
