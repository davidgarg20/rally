// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerRatingImpl _$$PlayerRatingImplFromJson(Map<String, dynamic> json) =>
    _$PlayerRatingImpl(
      format: $enumDecode(_$RatingFormatEnumMap, json['format']),
      rating: (json['rating'] as num).toDouble(),
      rd: (json['rd'] as num).toDouble(),
      matchesPlayed: (json['matches_played'] as num).toInt(),
    );

Map<String, dynamic> _$$PlayerRatingImplToJson(_$PlayerRatingImpl instance) =>
    <String, dynamic>{
      'format': _$RatingFormatEnumMap[instance.format]!,
      'rating': instance.rating,
      'rd': instance.rd,
      'matches_played': instance.matchesPlayed,
    };

const _$RatingFormatEnumMap = {
  RatingFormat.singles: 'S',
  RatingFormat.doubles: 'D',
};

_$OverallImpl _$$OverallImplFromJson(Map<String, dynamic> json) =>
    _$OverallImpl(
      rating: (json['rating'] as num?)?.toDouble(),
      matchesPlayed: (json['matches_played'] as num).toInt(),
    );

Map<String, dynamic> _$$OverallImplToJson(_$OverallImpl instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      'matches_played': instance.matchesPlayed,
    };

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
      id: json['id'] as String,
      phoneE164: json['phone_e164'] as String,
      displayName: json['display_name'] as String,
      gender: json['gender'] as String?,
      dob: json['dob'] == null ? null : DateTime.parse(json['dob'] as String),
      homeCity: json['home_city'] as String,
      ratings: (json['ratings'] as List<dynamic>)
          .map((e) => PlayerRating.fromJson(e as Map<String, dynamic>))
          .toList(),
      overall: Overall.fromJson(json['overall'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone_e164': instance.phoneE164,
      'display_name': instance.displayName,
      'gender': instance.gender,
      'dob': instance.dob?.toIso8601String(),
      'home_city': instance.homeCity,
      'ratings': instance.ratings,
      'overall': instance.overall,
    };
