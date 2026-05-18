import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/api/players_api.dart';
import 'package:rally/state/session_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  String? _gender;
  DateTime? _dob;
  bool _saving = false;
  String? _error;

  /// Live availability check state for the username field.
  /// null = not checked yet, true = available, false = taken/invalid.
  bool? _usernameAvailable;
  String? _usernameReason;
  bool _usernameChecking = false;
  Timer? _debounce;
  bool _userTouchedUsername = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_autoSuggestUsername);
    _username.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  /// Auto-suggest a username from the display name (Twitter-style).
  /// Doesn't fight the user once they've manually typed in the field.
  void _autoSuggestUsername() {
    if (_userTouchedUsername) return;
    final suggestion = _name.text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    if (suggestion.length >= 3 && suggestion.length <= 20) {
      _username.value = TextEditingValue(
        text: suggestion,
        selection: TextSelection.collapsed(offset: suggestion.length),
      );
    }
  }

  void _onUsernameChanged() {
    _userTouchedUsername = true;
    _debounce?.cancel();
    setState(() => _usernameAvailable = null);
    final value = _username.text.trim();
    if (value.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _usernameChecking = true);
      final res = await ref.read(playersApiProvider).checkUsername(value);
      if (!mounted) return;
      res.fold(
        onOk: (r) => setState(() {
          _usernameAvailable = r.available;
          _usernameReason = r.reason;
          _usernameChecking = false;
        }),
        onErr: (_) => setState(() {
          _usernameChecking = false;
        }),
      );
    });
  }

  String? _usernameHelper() {
    if (_username.text.isEmpty) return '3–20 chars · a–z, 0–9, _';
    if (_usernameChecking) return 'Checking…';
    if (_usernameAvailable == true) return 'Available!';
    if (_usernameAvailable == false) {
      return _usernameReason == 'taken' ? 'Taken' : 'Invalid format';
    }
    return null;
  }

  Color? _usernameHelperColor(BuildContext context) {
    if (_usernameAvailable == true) return Colors.green.shade700;
    if (_usernameAvailable == false) {
      return Theme.of(context).colorScheme.error;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter your name'); return;
    }
    if (_username.text.trim().isEmpty) {
      setState(() => _error = 'Pick a username'); return;
    }
    if (_usernameAvailable != true) {
      setState(() => _error = 'Username is not available'); return;
    }
    setState(() { _saving = true; _error = null; });
    final res = await ref.read(playersApiProvider).create(
      username: _username.text.trim().toLowerCase(),
      displayName: _name.text.trim(),
      gender: _gender,
      dob: _dob,
    );
    if (!mounted) return;
    res.fold(
      onOk: (_) {
        ref.invalidate(currentPlayerProvider);
        context.go('/home');
      },
      onErr: (e) => setState(() { _error = e.message; _saving = false; }),
    );
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context, firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Display name', border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _username,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                border: const OutlineInputBorder(),
                helperText: _usernameHelper(),
                helperStyle: TextStyle(color: _usernameHelperColor(context)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender (optional)', border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Male')),
                DropdownMenuItem(value: 'F', child: Text('Female')),
                DropdownMenuItem(value: 'O', child: Text('Other / prefer not to say')),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pickDob,
              child: Text(_dob == null
                  ? 'Date of birth (optional)'
                  : 'DOB: ${_dob!.toIso8601String().substring(0, 10)}'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
