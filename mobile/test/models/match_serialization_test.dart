// test/models/match_serialization_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/models/match.dart';

void main() {
  test('MatchOut round-trips JSON', () {
    final json = {
      'id': 'm-1',
      'format': 'S',
      'played_at': '2026-05-18T12:00:00Z',
      'venue': null,
      'status': 'validated',
      'validation_deadline': '2026-05-21T12:00:00Z',
      'validated_at': '2026-05-18T12:30:00Z',
      'participants': [
        {
          'player_id': 'p-1', 'phone_e164': '+91990000001',
          'display_name': 'Alice', 'team': 1, 'is_submitter': true,
          'confirmed': true, 'disputed': false,
        },
        {
          'player_id': 'p-2', 'phone_e164': '+91990000002',
          'display_name': 'Bob', 'team': 2, 'is_submitter': false,
          'confirmed': true, 'disputed': false,
        },
      ],
      'games': [
        {'game_no': 1, 'team1_points': 21, 'team2_points': 18},
      ],
      'rating_deltas': [
        {'player_id': 'p-1', 'rating_before': 3.5, 'rating_after': 3.62},
        {'player_id': 'p-2', 'rating_before': 3.5, 'rating_after': 3.38},
      ],
    };
    final m = MatchOut.fromJson(json);
    expect(m.id, 'm-1');
    expect(m.format, MatchFormat.singles);
    expect(m.status, MatchStatus.validated);
    expect(m.participants.length, 2);
    expect(m.games.first.team1Points, 21);
    expect(m.ratingDeltas.first.ratingAfter, 3.62);
  });
}
