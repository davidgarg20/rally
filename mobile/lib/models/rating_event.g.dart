// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RatingHistoryPointImpl _$$RatingHistoryPointImplFromJson(
        Map<String, dynamic> json) =>
    _$RatingHistoryPointImpl(
      matchId: json['match_id'] as String,
      ratingAfter: (json['rating_after'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$RatingHistoryPointImplToJson(
        _$RatingHistoryPointImpl instance) =>
    <String, dynamic>{
      'match_id': instance.matchId,
      'rating_after': instance.ratingAfter,
      'created_at': instance.createdAt.toIso8601String(),
    };
