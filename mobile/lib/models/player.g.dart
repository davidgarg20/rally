// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
      id: json['id'] as String,
      phoneE164: json['phone_e164'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      gender: json['gender'] as String?,
      dob: json['dob'] == null ? null : DateTime.parse(json['dob'] as String),
      homeCity: json['home_city'] as String,
      rating: (json['rating'] as num).toDouble(),
      rd: (json['rd'] as num).toDouble(),
      matchesPlayed: (json['matches_played'] as num).toInt(),
    );

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone_e164': instance.phoneE164,
      'username': instance.username,
      'display_name': instance.displayName,
      'gender': instance.gender,
      'dob': instance.dob?.toIso8601String(),
      'home_city': instance.homeCity,
      'rating': instance.rating,
      'rd': instance.rd,
      'matches_played': instance.matchesPlayed,
    };
