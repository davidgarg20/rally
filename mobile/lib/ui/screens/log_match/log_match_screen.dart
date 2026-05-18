import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/api/matches_api.dart';
import 'package:rally/models/match.dart';
import 'package:rally/state/pending_matches_provider.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/screens/log_match/log_match_controller.dart';
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

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return raw.trim();
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
                : [_normalizePhone(_teammate.text)]);
            ctrl.setTeam(2, s.format == MatchFormat.singles
                ? [_normalizePhone(_opp1.text)]
                : [_normalizePhone(_opp1.text), _normalizePhone(_opp2.text)]);
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
                  TextField(
                    controller: _teammate,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Your teammate (phone)',
                      prefixText: '+91 ',
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _opp1,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Opponent (phone)', prefixText: '+91 ',
                  ),
                ),
                if (s.format == MatchFormat.doubles) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _opp2,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Second opponent (phone)', prefixText: '+91 ',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Step(
            title: const Text('Score'),
            isActive: _step >= 2,
            content: Column(
              children: [
                for (final g in s.games)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text('Game ${g.gameNo}',
                              style: Theme.of(context).textTheme.titleSmall),
                          ScoreStepper(
                            label: 'You',
                            value: g.team1Points,
                            onChanged: (n) => ctrl.setGame(g.gameNo, n, g.team2Points),
                          ),
                          ScoreStepper(
                            label: 'Opponents',
                            value: g.team2Points,
                            onChanged: (n) => ctrl.setGame(g.gameNo, g.team1Points, n),
                          ),
                          if (g.gameNo > 1)
                            TextButton(
                              onPressed: () => ctrl.removeGame(g.gameNo),
                              child: const Text('Remove game'),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (s.games.length < 3)
                  TextButton.icon(
                    onPressed: ctrl.addGame,
                    icon: const Icon(Icons.add),
                    label: const Text('Add another game'),
                  ),
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
                Text('Games: ${s.games.map((g) => '${g.team1Points}-${g.team2Points}').join(', ')}'),
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
