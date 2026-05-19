import 'package:freezed_annotation/freezed_annotation.dart';

part 'rating_event.freezed.dart';
part 'rating_event.g.dart';

@freezed
class RatingHistoryPoint with _$RatingHistoryPoint {
  const factory RatingHistoryPoint({
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'rating_after') required double ratingAfter,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _RatingHistoryPoint;

  factory RatingHistoryPoint.fromJson(Map<String, dynamic> json) =>
      _$RatingHistoryPointFromJson(json);
}
