import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/models/match.dart';

class LogMatchState {
  LogMatchState({
    this.format = MatchFormat.singles,
    this.team1Phones = const [],
    this.team2Phones = const [],
    this.games = const [GameIn(gameNo: 1, team1Points: 0, team2Points: 0)],
    this.venue,
    DateTime? playedAt,
  }) : playedAt = playedAt ?? DateTime.now();

  final MatchFormat format;
  final List<String> team1Phones;
  final List<String> team2Phones;
  final List<GameIn> games;
  final String? venue;
  final DateTime playedAt;

  LogMatchState copy({
    MatchFormat? format,
    List<String>? team1Phones,
    List<String>? team2Phones,
    List<GameIn>? games,
    String? venue,
    DateTime? playedAt,
  }) => LogMatchState(
        format: format ?? this.format,
        team1Phones: team1Phones ?? this.team1Phones,
        team2Phones: team2Phones ?? this.team2Phones,
        games: games ?? this.games,
        venue: venue ?? this.venue,
        playedAt: playedAt ?? this.playedAt,
      );
}

class LogMatchController extends Notifier<LogMatchState> {
  @override
  LogMatchState build() => LogMatchState();

  void setFormat(MatchFormat f) {
    state = state.copy(format: f, team1Phones: [], team2Phones: []);
  }

  void setTeam(int teamNo, List<String> phones) {
    state = teamNo == 1
        ? state.copy(team1Phones: phones)
        : state.copy(team2Phones: phones);
  }

  void setGame(int gameNo, int team1Points, int team2Points) {
    final games = [...state.games];
    final idx = games.indexWhere((g) => g.gameNo == gameNo);
    final g = GameIn(gameNo: gameNo, team1Points: team1Points, team2Points: team2Points);
    if (idx == -1) {
      games.add(g);
    } else {
      games[idx] = g;
    }
    state = state.copy(games: games);
  }

  void addGame() {
    final next = state.games.length + 1;
    if (next > 3) return;
    setGame(next, 0, 0);
  }

  void removeGame(int gameNo) {
    state = state.copy(games: state.games.where((g) => g.gameNo != gameNo).toList());
  }

  void setVenue(String? v) => state = state.copy(venue: v);

  MatchSubmit toRequest(String submitterPhone) {
    final t1 = state.format == MatchFormat.singles
        ? [submitterPhone]
        : [submitterPhone, ...state.team1Phones];
    return MatchSubmit(
      format: state.format,
      playedAt: state.playedAt,
      venue: state.venue,
      team1Phones: t1,
      team2Phones: state.team2Phones,
      games: state.games,
    );
  }
}

final logMatchControllerProvider =
    NotifierProvider<LogMatchController, LogMatchState>(LogMatchController.new);
