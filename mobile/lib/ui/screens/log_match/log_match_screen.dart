import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/api/matches_api.dart';
import 'package:rally/models/match.dart';
import 'package:rally/state/pending_matches_provider.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/screens/log_match/log_match_controller.dart';
import 'package:rally/ui/widgets/opponent_field.dart';
import 'package:rally/ui/widgets/score_stepper.dart';

class LogMatchScreen extends ConsumerStatefulWidget {
  const LogMatchScreen({super.key});
  @override
  ConsumerState<LogMatchScreen> createState() => _LogMatchScreenState();
}

class _LogMatchScreenState extends ConsumerState<LogMatchScreen> {
  int _step = 0;
  bool _submitting = false;
  String? _error;
  final _teammate = TextEditingController();
  final _opp1 = TextEditingController();
  final _opp2 = TextEditingController();
  final _venue = TextEditingController();

  /// Accept a username (@asha) or a phone number. Backend resolves either way.
  String _normalizeIdentifier(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return s;
    // Looks like a username if it starts with @ or contains a letter.
    if (s.startsWith('@')) return s.substring(1).toLowerCase();
    if (RegExp(r'[a-zA-Z_]').hasMatch(s)) return s.toLowerCase();
    // Otherwise treat as a phone number.
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return s;
  }

  Future<void> _submit() async {
    final me = (await ref.read(currentPlayerProvider.future))!;
    final ctrl = ref.read(logMatchControllerProvider.notifier);
    ctrl.setVenue(_venue.text.trim().isEmpty ? null : _venue.text.trim());
    final body = ctrl.toRequest(me.phoneE164);
    setState(() {
      _submitting = true;
      _error = null;
    });
    final res = await ref.read(matchesApiProvider).submit(body);
    if (!mounted) return;
    res.fold(
      onOk: (m) {
        ref.invalidate(recentMatchesProvider);
        ref.invalidate(pendingMatchesProvider);
        context.go('/match/${m.id}');
      },
      onErr: (e) => setState(() {
        _error = e.message;
        _submitting = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(logMatchControllerProvider);
    final ctrl = ref.read(logMatchControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Log a match')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 1) {
            ctrl.setTeam(1, s.format == MatchFormat.singles
                ? []
                : [_normalizeIdentifier(_teammate.text)]);
            ctrl.setTeam(2, s.format == MatchFormat.singles
                ? [_normalizeIdentifier(_opp1.text)]
                : [_normalizeIdentifier(_opp1.text), _normalizeIdentifier(_opp2.text)]);
          }
          if (_step < 3) {
            setState(() => _step++);
          } else {
            _submit();
          }
        },
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        controlsBuilder: (_, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: _submitting ? null : details.onStepContinue,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_step == 3 ? 'Submit' : 'Continue'),
              ),
            ),
            if (details.onStepCancel != null) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
            ],
          ]),
        ),
        steps: [
          Step(
            title: const Text('Format'),
            isActive: _step >= 0,
            content: SegmentedButton<MatchFormat>(
              segments: const [
                ButtonSegment(value: MatchFormat.singles, label: Text('Singles')),
                ButtonSegment(value: MatchFormat.doubles, label: Text('Doubles')),
              ],
              selected: {s.format},
              onSelectionChanged: (v) => ctrl.setFormat(v.first),
            ),
          ),
          Step(
            title: const Text('Players'),
            isActive: _step >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (s.format == MatchFormat.doubles)
                  OpponentField(controller: _teammate, label: 'Your teammate'),
                const SizedBox(height: 8),
                OpponentField(controller: _opp1, label: 'Opponent'),
                if (s.format == MatchFormat.doubles) ...[
                  const SizedBox(height: 8),
                  OpponentField(controller: _opp2, label: 'Second opponent'),
                ],
              ],
            ),
          ),
          Step(
            title: const Text('Score'),
            isActive: _step >= 2,
            content: Column(
              children: [
                // Single-set: just one game. Use first (and only) game in state.
                Builder(builder: (_) {
                  final g = s.games.first;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ScoreStepper(
                            label: 'You',
                            value: g.team1Points,
                            onChanged: (n) => ctrl.setGame(1, n, g.team2Points),
                          ),
                          ScoreStepper(
                            label: 'Opponents',
                            value: g.team2Points,
                            onChanged: (n) => ctrl.setGame(1, g.team1Points, n),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _step >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.format == MatchFormat.singles ? 'Singles' : 'Doubles'),
                Text('Score: ${s.games.first.team1Points}-${s.games.first.team2Points}'),
                const SizedBox(height: 12),
                TextField(
                  controller: _venue,
                  decoration: const InputDecoration(
                    labelText: 'Venue (optional)', border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
