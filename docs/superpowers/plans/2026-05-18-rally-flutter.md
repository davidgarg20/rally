# Rally Flutter App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Rally iOS+Android mobile app — phone-OTP onboarding, log a match (singles/doubles), confirm/dispute opponent-posted matches, view rating + leaderboard + match history — against the FastAPI backend from Plan 1.

**Architecture:** Single Flutter codebase for iOS+Android. Firebase Auth (phone OTP) for identity; Firebase Cloud Messaging for push. Riverpod for state. `dio` HTTP client with auto-injected Firebase ID token. `freezed` + `json_serializable` for typed models matching backend schemas. `go_router` for nav. Local persistence only for the current Firebase token cache (no offline mode in MVP).

**Tech Stack:** Flutter 3.27+, Dart 3.6+, `flutter_riverpod`, `dio`, `go_router`, `firebase_core`, `firebase_auth`, `firebase_messaging`, `freezed`, `json_serializable`, `intl` (date formatting), `fl_chart` (rating-history sparkline), `flutter_test` + `integration_test`.

**Backend contract:** Documented in `/Users/davidgarg20/Documents/startup_0/backend/README.md` and the spec at `docs/superpowers/specs/2026-05-18-rally-mvp-design.md`. All endpoints require `Authorization: Bearer <jwt>` except `/healthz` and `/internal/*`. In dev, the shortcut `Bearer dev:<uid>:<phone_e164>` works.

**Repository layout:**

```
mobile/
  pubspec.yaml
  analysis_options.yaml
  l10n.yaml
  .gitignore
  android/
    app/google-services.json            -- placeholder; real one comes in Plan 3
    app/build.gradle.kts                -- standard flutter init
  ios/
    Runner/GoogleService-Info.plist     -- placeholder
    Runner/Info.plist                   -- mic/contacts perms NOT needed for MVP
  lib/
    main.dart                            -- runApp, ProviderScope, Firebase init
    app.dart                             -- MaterialApp.router + theme
    router.dart                          -- go_router config + guards
    env.dart                             -- API base URL, env enum
    core/
      result.dart                        -- Result<T, AppError> sealed type
      errors.dart                        -- AppError model from API error envelope
      api_client.dart                    -- dio instance + token interceptor
      firebase_init.dart                 -- ensureFirebase()
      providers.dart                     -- shared Riverpod providers (api, auth, router)
    auth/
      auth_repository.dart               -- FirebaseAuth wrapper, OTP send/verify
      auth_controller.dart               -- Riverpod auth state
      dev_token.dart                     -- dev-mode bypass for emulators
    models/
      player.dart                        -- freezed Player + Rating
      match.dart                         -- freezed Match + Participant + Game
      leaderboard.dart                   -- freezed LeaderboardEntry
      rating_event.dart
      *.g.dart / *.freezed.dart          -- generated
    api/
      players_api.dart                   -- typed wrappers over /players
      matches_api.dart                   -- typed wrappers over /matches
      leaderboard_api.dart               -- typed wrapper over /leaderboard
    state/
      session_provider.dart              -- current player + ratings
      pending_matches_provider.dart      -- matches awaiting my confirm
      recent_matches_provider.dart       -- last 10
      leaderboard_provider.dart
    push/
      fcm_service.dart                   -- token registration + foreground handler
    ui/
      theme.dart                          -- colors, typography, shape
      widgets/
        rating_card.dart
        sparkline.dart
        score_stepper.dart
        match_tile.dart
        empty_state.dart
        async_value_view.dart            -- common loading/error/data switch
      screens/
        onboarding/phone_screen.dart
        onboarding/otp_screen.dart
        onboarding/profile_screen.dart
        home/home_screen.dart
        log_match/log_match_screen.dart
        log_match/log_match_controller.dart
        match_detail/match_detail_screen.dart
        leaderboard/leaderboard_screen.dart
        profile/profile_screen.dart
  test/
    models/match_serialization_test.dart
    api/api_client_test.dart             -- dio interceptor token injection
    state/session_provider_test.dart
    widgets/score_stepper_test.dart
  integration_test/
    onboarding_smoke_test.dart           -- dev-token path on emulator
```

**Conventions across the plan:**

- All API call sites return `Future<Result<T, AppError>>` so the UI never throws.
- All screens use a single `AsyncValueView` widget for loading/error/data — no ad-hoc spinners.
- All date display uses `DateFormat.yMMMd().add_jm()` ("May 18, 2026 7:30 PM").
- All money/rating display: 2 decimal places (`.toStringAsFixed(2)`).
- In `ENV=dev`, the OTP screen accepts `123456` and the auth path uses `dev:<firebase-uid>:<phone>` directly — bypasses real Firebase. This lets you develop against a backend without a real Firebase project until Plan 3.
- We run codegen via `dart run build_runner build --delete-conflicting-outputs` after any change to `freezed` / `json_serializable` annotated files. Each task that adds such a file includes the codegen step.
- Run tests via `flutter test`. Integration tests run on a connected device/emulator via `flutter test integration_test/`.

**Out of scope (per spec §10):** matchmaking, friends graph, club entities, tournaments, in-app settings beyond profile edit, push preferences UI, video analysis. Do not add these.

---

## Task 1: Bootstrap Flutter project and tooling

**Files:**
- Create: `mobile/pubspec.yaml`
- Create: `mobile/analysis_options.yaml`
- Create: `mobile/.gitignore`
- Create: `mobile/README.md`

- [ ] **Step 1: Create the Flutter project skeleton**

Run from `/Users/davidgarg20/Documents/startup_0`:

```bash
flutter create --platforms=ios,android --org com.rally --project-name rally mobile
```

This generates the standard tree (`lib/main.dart`, `android/`, `ios/`, `test/widget_test.dart`).

If `flutter` is not on PATH, report BLOCKED with the system PATH.

- [ ] **Step 2: Replace `mobile/pubspec.yaml`**

```yaml
name: rally
description: "Rally — universal badminton rating."
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^3.6.0
  flutter: ">=3.27.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  dio: ^5.7.0
  go_router: ^14.6.0
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  firebase_messaging: ^15.1.3
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  intl: ^0.19.0
  fl_chart: ^0.69.0
  shared_preferences: ^2.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Replace `mobile/analysis_options.yaml`**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore  # freezed/json_serializable noise
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_declarations: true
    use_key_in_widget_constructors: true
    avoid_print: true
```

- [ ] **Step 4: Update `mobile/.gitignore`** — append:

```
.flutter-plugins
.flutter-plugins-dependencies
ios/Pods/
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

- [ ] **Step 5: Create `mobile/README.md`**

```markdown
# Rally Mobile

Flutter app for the Rally badminton-rating MVP.

## Setup

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Run

```bash
flutter run -d <device>
```

The default backend URL is `http://localhost:8000` (dev). Override with:

```bash
flutter run --dart-define=API_BASE_URL=https://staging.rally.example
```

In dev, the app uses a fake Firebase identity: tap "Send OTP" → enter `123456` → you sign in as `dev:<random-uid>:<phone>` against the backend.

## Tests

```bash
flutter test                       # unit + widget tests
flutter test integration_test/     # on a device/emulator
```
```

- [ ] **Step 6: Install deps**

```bash
cd /Users/davidgarg20/Documents/startup_0/mobile && flutter pub get
```

Expected: "Got dependencies!" with no errors.

- [ ] **Step 7: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): bootstrap flutter project + tooling"
```

---

## Task 2: Environment + Result + AppError

**Files:**
- Create: `mobile/lib/env.dart`
- Create: `mobile/lib/core/result.dart`
- Create: `mobile/lib/core/errors.dart`
- Create: `mobile/test/core/result_test.dart`

- [ ] **Step 1: Write failing test `test/core/result_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/core/result.dart';
import 'package:rally/core/errors.dart';

void main() {
  test('Ok holds value', () {
    final r = Result<int, AppError>.ok(42);
    expect(r.isOk, true);
    expect(r.valueOrNull, 42);
    expect(r.errorOrNull, null);
  });

  test('Err holds error', () {
    final e = AppError(code: 'x', message: 'm', httpStatus: 400);
    final r = Result<int, AppError>.err(e);
    expect(r.isOk, false);
    expect(r.valueOrNull, null);
    expect(r.errorOrNull, e);
  });

  test('fold dispatches', () {
    final ok = Result<int, AppError>.ok(7);
    expect(ok.fold(onOk: (v) => 'v=$v', onErr: (e) => 'e=${e.code}'), 'v=7');
  });
}
```

- [ ] **Step 2: Run test, expect compile failure**

```bash
cd /Users/davidgarg20/Documents/startup_0/mobile && flutter test test/core/result_test.dart
```

Expected: compile errors (Result / AppError missing).

- [ ] **Step 3: Implement `lib/env.dart`**

```dart
enum AppEnv { dev, staging, prod }

class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static AppEnv get current => switch (_envName) {
        'prod' => AppEnv.prod,
        'staging' => AppEnv.staging,
        _ => AppEnv.dev,
      };

  static bool get isDev => current == AppEnv.dev;
}
```

- [ ] **Step 4: Implement `lib/core/errors.dart`**

```dart
import 'package:dio/dio.dart';

class AppError implements Exception {
  AppError({
    required this.code,
    required this.message,
    required this.httpStatus,
  });

  final String code;
  final String message;
  final int httpStatus;

  factory AppError.network() => AppError(
        code: 'network',
        message: 'No network connection.',
        httpStatus: 0,
      );

  factory AppError.unknown(Object e) => AppError(
        code: 'unknown',
        message: e.toString(),
        httpStatus: 0,
      );

  factory AppError.fromDioException(DioException e) {
    final res = e.response;
    if (res == null) {
      return AppError.network();
    }
    final data = res.data;
    if (data is Map && data['code'] is String && data['message'] is String) {
      return AppError(
        code: data['code'] as String,
        message: data['message'] as String,
        httpStatus: res.statusCode ?? 0,
      );
    }
    return AppError(
      code: 'http_${res.statusCode ?? 0}',
      message: res.statusMessage ?? 'Request failed',
      httpStatus: res.statusCode ?? 0,
    );
  }

  @override
  String toString() => 'AppError($code, $httpStatus): $message';
}
```

- [ ] **Step 5: Implement `lib/core/result.dart`**

```dart
sealed class Result<T, E> {
  const Result();

  factory Result.ok(T value) = Ok<T, E>;
  factory Result.err(E error) = Err<T, E>;

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T? get valueOrNull => switch (this) {
        Ok<T, E>(:final value) => value,
        Err<T, E>() => null,
      };

  E? get errorOrNull => switch (this) {
        Ok<T, E>() => null,
        Err<T, E>(:final error) => error,
      };

  R fold<R>({required R Function(T) onOk, required R Function(E) onErr}) =>
      switch (this) {
        Ok<T, E>(:final value) => onOk(value),
        Err<T, E>(:final error) => onErr(error),
      };
}

class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;
}

class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;
}
```

- [ ] **Step 6: Run test**

```bash
flutter test test/core/result_test.dart
```

Expected: 3 tests passed.

- [ ] **Step 7: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/env.dart mobile/lib/core/ mobile/test/core/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): env config + Result/AppError primitives"
```

---

## Task 3: API client with token interceptor

**Files:**
- Create: `mobile/lib/core/api_client.dart`
- Create: `mobile/lib/core/providers.dart`
- Create: `mobile/test/api/api_client_test.dart`

The interceptor reads a token from a `TokenProvider` and injects `Authorization: Bearer <token>` on every request unless the path starts with `/healthz`.

- [ ] **Step 1: Write failing test**

```dart
// test/api/api_client_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/core/api_client.dart';

void main() {
  test('injects bearer token on authed requests', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
    final captured = <String, String>{};
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) {
        captured['authz'] = opts.headers['Authorization'] as String? ?? '';
        captured['path'] = opts.path;
        return handler.reject(
          DioException(requestOptions: opts, type: DioExceptionType.cancel),
        );
      },
    ));
    final client = ApiClient(dio: dio, tokenProvider: () async => 'tok-123');

    try { await client.dio.get('/players/me'); } on DioException {}
    expect(captured['authz'], 'Bearer tok-123');
  });

  test('skips token for healthz', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
    String? capturedAuth;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) {
        capturedAuth = opts.headers['Authorization'] as String?;
        return handler.reject(
          DioException(requestOptions: opts, type: DioExceptionType.cancel),
        );
      },
    ));
    final client = ApiClient(dio: dio, tokenProvider: () async => 'tok');
    try { await client.dio.get('/healthz'); } on DioException {}
    expect(capturedAuth, isNull);
  });
}
```

- [ ] **Step 2: Run test, expect compile failure (ApiClient missing).**

```bash
flutter test test/api/api_client_test.dart
```

- [ ] **Step 3: Implement `lib/core/api_client.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:rally/env.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({Dio? dio, required TokenProvider tokenProvider})
      : dio = dio ?? Dio(BaseOptions(baseUrl: Env.apiBaseUrl)),
        _tokenProvider = tokenProvider {
    this.dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) async {
        if (!opts.path.startsWith('/healthz')) {
          final token = await _tokenProvider();
          if (token != null && token.isNotEmpty) {
            opts.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(opts);
      },
    ));
    this.dio.options.connectTimeout = const Duration(seconds: 8);
    this.dio.options.receiveTimeout = const Duration(seconds: 12);
  }

  final Dio dio;
  final TokenProvider _tokenProvider;
}
```

- [ ] **Step 4: Implement `lib/core/providers.dart`** (just the API client provider for now; auth provider is wired in Task 5)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/core/api_client.dart';

/// Overridden in main.dart once auth is wired.
final tokenProvider = Provider<TokenProvider>((ref) => () async => null);

final apiClientProvider = Provider<ApiClient>((ref) {
  final tp = ref.watch(tokenProvider);
  return ApiClient(tokenProvider: tp);
});
```

- [ ] **Step 5: Run test, expect 2 passed.**

```bash
flutter test test/api/api_client_test.dart
```

- [ ] **Step 6: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/core/api_client.dart mobile/lib/core/providers.dart mobile/test/api/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): dio client + bearer-token interceptor"
```

---

## Task 4: Typed models (Player, Match, Leaderboard, RatingEvent)

**Files:**
- Create: `mobile/lib/models/player.dart`
- Create: `mobile/lib/models/match.dart`
- Create: `mobile/lib/models/leaderboard.dart`
- Create: `mobile/lib/models/rating_event.dart`
- Create: `mobile/test/models/match_serialization_test.dart`

- [ ] **Step 1: Write failing test**

```dart
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
```

- [ ] **Step 2: Run, expect failure.**

```bash
flutter test test/models/
```

- [ ] **Step 3: Implement `lib/models/player.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

enum RatingFormat {
  @JsonValue('S') singles,
  @JsonValue('D') doubles,
}

@freezed
class PlayerRating with _$PlayerRating {
  const factory PlayerRating({
    required RatingFormat format,
    required double rating,
    required double rd,
    @JsonKey(name: 'matches_played') required int matchesPlayed,
  }) = _PlayerRating;

  factory PlayerRating.fromJson(Map<String, dynamic> json) =>
      _$PlayerRatingFromJson(json);
}

@freezed
class Player with _$Player {
  const factory Player({
    required String id,
    @JsonKey(name: 'phone_e164') required String phoneE164,
    @JsonKey(name: 'display_name') required String displayName,
    String? gender,
    DateTime? dob,
    @JsonKey(name: 'home_city') required String homeCity,
    required List<PlayerRating> ratings,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
}
```

- [ ] **Step 4: Implement `lib/models/match.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'match.freezed.dart';
part 'match.g.dart';

enum MatchFormat {
  @JsonValue('S') singles,
  @JsonValue('D') doubles,
}

enum MatchStatus {
  @JsonValue('pending') pending,
  @JsonValue('validated') validated,
  @JsonValue('disputed') disputed,
  @JsonValue('expired') expired,
}

@freezed
class Participant with _$Participant {
  const factory Participant({
    @JsonKey(name: 'player_id') String? playerId,
    @JsonKey(name: 'phone_e164') required String phoneE164,
    @JsonKey(name: 'display_name') String? displayName,
    required int team,
    @JsonKey(name: 'is_submitter') required bool isSubmitter,
    required bool confirmed,
    required bool disputed,
  }) = _Participant;

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
}

@freezed
class GameOut with _$GameOut {
  const factory GameOut({
    @JsonKey(name: 'game_no') required int gameNo,
    @JsonKey(name: 'team1_points') required int team1Points,
    @JsonKey(name: 'team2_points') required int team2Points,
  }) = _GameOut;

  factory GameOut.fromJson(Map<String, dynamic> json) =>
      _$GameOutFromJson(json);
}

@freezed
class RatingDelta with _$RatingDelta {
  const factory RatingDelta({
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'rating_before') required double ratingBefore,
    @JsonKey(name: 'rating_after') required double ratingAfter,
  }) = _RatingDelta;

  factory RatingDelta.fromJson(Map<String, dynamic> json) =>
      _$RatingDeltaFromJson(json);
}

@freezed
class MatchOut with _$MatchOut {
  const factory MatchOut({
    required String id,
    required MatchFormat format,
    @JsonKey(name: 'played_at') required DateTime playedAt,
    String? venue,
    required MatchStatus status,
    @JsonKey(name: 'validation_deadline') required DateTime validationDeadline,
    @JsonKey(name: 'validated_at') DateTime? validatedAt,
    required List<Participant> participants,
    required List<GameOut> games,
    @JsonKey(name: 'rating_deltas') required List<RatingDelta> ratingDeltas,
  }) = _MatchOut;

  factory MatchOut.fromJson(Map<String, dynamic> json) =>
      _$MatchOutFromJson(json);
}

@freezed
class GameIn with _$GameIn {
  const factory GameIn({
    @JsonKey(name: 'game_no') required int gameNo,
    @JsonKey(name: 'team1_points') required int team1Points,
    @JsonKey(name: 'team2_points') required int team2Points,
  }) = _GameIn;

  factory GameIn.fromJson(Map<String, dynamic> json) => _$GameInFromJson(json);
}

@freezed
class MatchSubmit with _$MatchSubmit {
  const factory MatchSubmit({
    required MatchFormat format,
    @JsonKey(name: 'played_at') required DateTime playedAt,
    String? venue,
    @JsonKey(name: 'team1_phones') required List<String> team1Phones,
    @JsonKey(name: 'team2_phones') required List<String> team2Phones,
    required List<GameIn> games,
  }) = _MatchSubmit;

  factory MatchSubmit.fromJson(Map<String, dynamic> json) =>
      _$MatchSubmitFromJson(json);
}
```

- [ ] **Step 5: Implement `lib/models/leaderboard.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard.freezed.dart';
part 'leaderboard.g.dart';

@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required int rank,
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'display_name') required String displayName,
    required double rating,
    @JsonKey(name: 'matches_played') required int matchesPlayed,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}

@freezed
class LeaderboardResponse with _$LeaderboardResponse {
  const factory LeaderboardResponse({
    required String format,
    required String city,
    required String gender,
    required List<LeaderboardEntry> entries,
  }) = _LeaderboardResponse;

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardResponseFromJson(json);
}
```

- [ ] **Step 6: Implement `lib/models/rating_event.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rating_event.freezed.dart';
part 'rating_event.g.dart';

@freezed
class RatingHistoryPoint with _$RatingHistoryPoint {
  const factory RatingHistoryPoint({
    @JsonKey(name: 'match_id') required String matchId,
    required String format,
    @JsonKey(name: 'rating_after') required double ratingAfter,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _RatingHistoryPoint;

  factory RatingHistoryPoint.fromJson(Map<String, dynamic> json) =>
      _$RatingHistoryPointFromJson(json);
}
```

- [ ] **Step 7: Run codegen**

```bash
cd /Users/davidgarg20/Documents/startup_0/mobile && dart run build_runner build --delete-conflicting-outputs
```

Expected: "Succeeded" with `.freezed.dart` and `.g.dart` files generated next to each source.

- [ ] **Step 8: Run test**

```bash
flutter test test/models/
```

Expected: 1 passed.

- [ ] **Step 9: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/models/ mobile/test/models/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): freezed models for Player, Match, Leaderboard, RatingEvent"
```

---

## Task 5: Auth — Firebase wrapper + dev-token bypass

**Files:**
- Create: `mobile/lib/auth/auth_repository.dart`
- Create: `mobile/lib/auth/dev_token.dart`
- Create: `mobile/lib/auth/auth_controller.dart`
- Create: `mobile/lib/core/firebase_init.dart`
- Modify: `mobile/lib/core/providers.dart`

In `dev` mode we never call Firebase. We synthesize a `dev:<uid>:<phone>` token and treat the user as authed once they type any 10-digit number + OTP `123456`.

- [ ] **Step 1: Create `lib/auth/dev_token.dart`**

```dart
import 'dart:math';

String devTokenFor(String phoneE164) {
  // Stable uid for a given phone so backend reuses the same Player.
  final hash = phoneE164.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
  return 'dev:u-${hash.toRadixString(16)}:$phoneE164';
}

String mockPhone() {
  final r = Random().nextInt(900000000) + 100000000;
  return '+9199${r.toString().padLeft(9, '0').substring(0, 9)}';
}
```

- [ ] **Step 2: Create `lib/core/firebase_init.dart`**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:rally/env.dart';

Future<void> ensureFirebase() async {
  if (Env.isDev) return; // skip in dev; we use dev_token
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}
```

- [ ] **Step 3: Create `lib/auth/auth_repository.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rally/auth/dev_token.dart';
import 'package:rally/env.dart';

class AuthSession {
  AuthSession({required this.uid, required this.phoneE164, required this.token});
  final String uid;
  final String phoneE164;
  final String token;
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  /// Returns a verificationId. In dev, the verificationId is the phone itself.
  Future<String> sendOtp(String phoneE164) async {
    if (Env.isDev) return phoneE164;

    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      verificationCompleted: (_) {},
      verificationFailed: (e) => completer.completeError(e),
      codeSent: (verificationId, _) => completer.complete(verificationId),
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      timeout: const Duration(seconds: 60),
    );
    return completer.future;
  }

  /// Returns an `AuthSession` containing a backend-usable token.
  Future<AuthSession> verifyOtp({
    required String verificationId,
    required String otpCode,
    required String phoneE164,
  }) async {
    if (Env.isDev) {
      if (otpCode != '123456') throw Exception('Invalid dev OTP');
      final token = devTokenFor(phoneE164);
      // uid format: dev:u-<hex>:<phone> → uid = "u-<hex>"
      final uid = token.split(':')[1];
      return AuthSession(uid: uid, phoneE164: phoneE164, token: token);
    }

    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );
    final result = await _auth.signInWithCredential(cred);
    final user = result.user!;
    final token = await user.getIdToken();
    return AuthSession(
      uid: user.uid,
      phoneE164: user.phoneNumber ?? phoneE164,
      token: token ?? '',
    );
  }

  Future<String?> currentToken() async {
    if (Env.isDev) return null; // dev token comes from controller cache
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  Future<void> signOut() async {
    if (!Env.isDev) await _auth.signOut();
  }
}
```

(Add `import 'dart:async';` at top — the linter will catch it; insert it now to avoid a later test failure.)

- [ ] **Step 4: Create `lib/auth/auth_controller.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rally/auth/auth_repository.dart';

const _kTokenKey = 'rally.token';
const _kUidKey = 'rally.uid';
const _kPhoneKey = 'rally.phone';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

class AuthController extends AsyncNotifier<AuthSession?> {
  late SharedPreferences _prefs;
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthSession?> build() async {
    _prefs = await SharedPreferences.getInstance();
    final t = _prefs.getString(_kTokenKey);
    final u = _prefs.getString(_kUidKey);
    final p = _prefs.getString(_kPhoneKey);
    if (t == null || u == null || p == null) return null;
    return AuthSession(uid: u, phoneE164: p, token: t);
  }

  Future<String> sendOtp(String phone) => _repo.sendOtp(phone);

  Future<void> verifyOtp({
    required String verificationId,
    required String otp,
    required String phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final s = await _repo.verifyOtp(
        verificationId: verificationId,
        otpCode: otp,
        phoneE164: phone,
      );
      await _prefs.setString(_kTokenKey, s.token);
      await _prefs.setString(_kUidKey, s.uid);
      await _prefs.setString(_kPhoneKey, s.phoneE164);
      return s;
    });
  }

  Future<void> signOut() async {
    await _repo.signOut();
    await _prefs.remove(_kTokenKey);
    await _prefs.remove(_kUidKey);
    await _prefs.remove(_kPhoneKey);
    state = const AsyncData(null);
  }

  String? get tokenSync => state.valueOrNull?.token;
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);
```

- [ ] **Step 5: Update `lib/core/providers.dart`** — wire token provider to auth.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/auth/auth_controller.dart';
import 'package:rally/core/api_client.dart';

final tokenProvider = Provider<TokenProvider>((ref) {
  return () async => ref.read(authControllerProvider).valueOrNull?.token;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tp = ref.watch(tokenProvider);
  return ApiClient(tokenProvider: tp);
});
```

- [ ] **Step 6: Sanity build**

```bash
cd /Users/davidgarg20/Documents/startup_0/mobile && flutter analyze lib/
```

Expected: no errors. Warnings about unused imports OK to ignore until next task.

- [ ] **Step 7: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/auth/ mobile/lib/core/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): auth repo + controller with dev-token bypass"
```

---

## Task 6: Typed API wrappers

**Files:**
- Create: `mobile/lib/api/players_api.dart`
- Create: `mobile/lib/api/matches_api.dart`
- Create: `mobile/lib/api/leaderboard_api.dart`

Each API method returns `Future<Result<T, AppError>>` and uses the dio instance from `apiClientProvider`.

- [ ] **Step 1: Create `lib/api/players_api.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/core/api_client.dart';
import 'package:rally/core/errors.dart';
import 'package:rally/core/providers.dart';
import 'package:rally/core/result.dart';
import 'package:rally/models/match.dart';
import 'package:rally/models/player.dart';
import 'package:rally/models/rating_event.dart';

class PlayersApi {
  PlayersApi(this._client);
  final ApiClient _client;

  Future<Result<Player, AppError>> create({
    required String displayName, String? gender, DateTime? dob,
    String homeCity = 'BLR',
  }) => _wrap(() async {
        final res = await _client.dio.post('/players', data: {
          'display_name': displayName,
          if (gender != null) 'gender': gender,
          if (dob != null) 'dob': dob.toIso8601String().substring(0, 10),
          'home_city': homeCity,
        });
        return Player.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<Player, AppError>> me() => _wrap(() async {
        final res = await _client.dio.get('/players/me');
        return Player.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<Player, AppError>> patchMe({
    String? displayName, String? gender, DateTime? dob, String? homeCity,
  }) => _wrap(() async {
        final res = await _client.dio.patch('/players/me', data: {
          if (displayName != null) 'display_name': displayName,
          if (gender != null) 'gender': gender,
          if (dob != null) 'dob': dob.toIso8601String().substring(0, 10),
          if (homeCity != null) 'home_city': homeCity,
        });
        return Player.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<List<MatchOut>, AppError>> myMatches({String? status}) =>
      _wrap(() async {
        final res = await _client.dio.get(
          '/players/me/matches',
          queryParameters: {if (status != null) 'status': status},
        );
        return (res.data as List)
            .map((e) => MatchOut.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Result<List<RatingHistoryPoint>, AppError>> ratingHistory({int days = 90}) =>
      _wrap(() async {
        final res = await _client.dio.get(
          '/players/me/rating-history',
          queryParameters: {'days': days},
        );
        return (res.data as List)
            .map((e) => RatingHistoryPoint.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Result<T, AppError>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Result.ok(await fn());
    } on DioException catch (e) {
      return Result.err(AppError.fromDioException(e));
    } catch (e) {
      return Result.err(AppError.unknown(e));
    }
  }
}

final playersApiProvider = Provider<PlayersApi>(
  (ref) => PlayersApi(ref.watch(apiClientProvider)),
);
```

- [ ] **Step 2: Create `lib/api/matches_api.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/core/api_client.dart';
import 'package:rally/core/errors.dart';
import 'package:rally/core/providers.dart';
import 'package:rally/core/result.dart';
import 'package:rally/models/match.dart';

class MatchesApi {
  MatchesApi(this._client);
  final ApiClient _client;

  Future<Result<MatchOut, AppError>> submit(MatchSubmit body) => _wrap(() async {
        final res = await _client.dio.post('/matches', data: {
          'format': body.format == MatchFormat.singles ? 'S' : 'D',
          'played_at': body.playedAt.toIso8601String(),
          if (body.venue != null) 'venue': body.venue,
          'team1_phones': body.team1Phones,
          'team2_phones': body.team2Phones,
          'games': body.games
              .map((g) => {
                    'game_no': g.gameNo,
                    'team1_points': g.team1Points,
                    'team2_points': g.team2Points,
                  })
              .toList(),
        });
        return MatchOut.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<MatchOut, AppError>> get(String id) => _wrap(() async {
        final res = await _client.dio.get('/matches/$id');
        return MatchOut.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<MatchOut, AppError>> confirm(String id) => _wrap(() async {
        final res = await _client.dio.post('/matches/$id/confirm');
        return MatchOut.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<MatchOut, AppError>> dispute(String id) => _wrap(() async {
        final res = await _client.dio.post('/matches/$id/dispute');
        return MatchOut.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<T, AppError>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Result.ok(await fn());
    } on DioException catch (e) {
      return Result.err(AppError.fromDioException(e));
    } catch (e) {
      return Result.err(AppError.unknown(e));
    }
  }
}

final matchesApiProvider = Provider<MatchesApi>(
  (ref) => MatchesApi(ref.watch(apiClientProvider)),
);
```

- [ ] **Step 3: Create `lib/api/leaderboard_api.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/core/api_client.dart';
import 'package:rally/core/errors.dart';
import 'package:rally/core/providers.dart';
import 'package:rally/core/result.dart';
import 'package:rally/models/leaderboard.dart';

class LeaderboardApi {
  LeaderboardApi(this._client);
  final ApiClient _client;

  Future<Result<LeaderboardResponse, AppError>> fetch({
    String format = 'S', String gender = 'All', String city = 'BLR',
    int limit = 100,
  }) async {
    try {
      final res = await _client.dio.get('/leaderboard', queryParameters: {
        'format': format, 'gender': gender, 'city': city, 'limit': limit,
      });
      return Result.ok(
        LeaderboardResponse.fromJson(res.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return Result.err(AppError.fromDioException(e));
    } catch (e) {
      return Result.err(AppError.unknown(e));
    }
  }
}

final leaderboardApiProvider = Provider<LeaderboardApi>(
  (ref) => LeaderboardApi(ref.watch(apiClientProvider)),
);
```

- [ ] **Step 4: Verify build**

```bash
cd /Users/davidgarg20/Documents/startup_0/mobile && flutter analyze lib/
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/api/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): typed API wrappers for players/matches/leaderboard"
```

---

## Task 7: Session + state providers

**Files:**
- Create: `mobile/lib/state/session_provider.dart`
- Create: `mobile/lib/state/pending_matches_provider.dart`
- Create: `mobile/lib/state/recent_matches_provider.dart`
- Create: `mobile/lib/state/leaderboard_provider.dart`

- [ ] **Step 1: Create `lib/state/session_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/api/players_api.dart';
import 'package:rally/models/player.dart';

final currentPlayerProvider = FutureProvider<Player?>((ref) async {
  final api = ref.watch(playersApiProvider);
  final res = await api.me();
  return res.fold(
    onOk: (p) => p,
    onErr: (e) => e.code == 'player_not_found' ? null : throw e,
  );
});
```

- [ ] **Step 2: Create `lib/state/pending_matches_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/api/players_api.dart';
import 'package:rally/models/match.dart';

final pendingMatchesProvider = FutureProvider<List<MatchOut>>((ref) async {
  final api = ref.watch(playersApiProvider);
  final res = await api.myMatches(status: 'pending');
  return res.fold(onOk: (m) => m, onErr: (e) => throw e);
});
```

- [ ] **Step 3: Create `lib/state/recent_matches_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/api/players_api.dart';
import 'package:rally/models/match.dart';

final recentMatchesProvider = FutureProvider<List<MatchOut>>((ref) async {
  final api = ref.watch(playersApiProvider);
  final res = await api.myMatches();
  return res.fold(
    onOk: (m) => m.take(10).toList(),
    onErr: (e) => throw e,
  );
});
```

- [ ] **Step 4: Create `lib/state/leaderboard_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/api/leaderboard_api.dart';
import 'package:rally/models/leaderboard.dart';

final leaderboardFormatProvider = StateProvider<String>((_) => 'S');
final leaderboardGenderProvider = StateProvider<String>((_) => 'All');

final leaderboardProvider = FutureProvider<LeaderboardResponse>((ref) async {
  final api = ref.watch(leaderboardApiProvider);
  final fmt = ref.watch(leaderboardFormatProvider);
  final gen = ref.watch(leaderboardGenderProvider);
  final res = await api.fetch(format: fmt, gender: gen);
  return res.fold(onOk: (r) => r, onErr: (e) => throw e);
});
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/
```

- [ ] **Step 6: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/state/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): Riverpod providers for session/matches/leaderboard"
```

---

## Task 8: Theme + shared widgets

**Files:**
- Create: `mobile/lib/ui/theme.dart`
- Create: `mobile/lib/ui/widgets/async_value_view.dart`
- Create: `mobile/lib/ui/widgets/rating_card.dart`
- Create: `mobile/lib/ui/widgets/sparkline.dart`
- Create: `mobile/lib/ui/widgets/score_stepper.dart`
- Create: `mobile/lib/ui/widgets/match_tile.dart`
- Create: `mobile/lib/ui/widgets/empty_state.dart`
- Create: `mobile/test/widgets/score_stepper_test.dart`

- [ ] **Step 1: Create `lib/ui/theme.dart`**

```dart
import 'package:flutter/material.dart';

class RallyTheme {
  static const seed = Color(0xFF1E88E5);

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `lib/ui/widgets/async_value_view.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(err.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (onRetry != null)
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `lib/ui/widgets/rating_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:rally/models/player.dart';

class RatingCard extends StatelessWidget {
  const RatingCard({super.key, required this.ratings, this.sparklineS, this.sparklineD});

  final List<PlayerRating> ratings;
  final List<double>? sparklineS;
  final List<double>? sparklineD;

  PlayerRating? _ratingFor(RatingFormat fmt) =>
      ratings.where((r) => r.format == fmt).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final s = _ratingFor(RatingFormat.singles);
    final d = _ratingFor(RatingFormat.doubles);
    final theme = Theme.of(context);

    Widget cell(String label, PlayerRating? r) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                r == null ? '—' : r.rating.toStringAsFixed(2),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Text('${r?.matchesPlayed ?? 0} matches',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [cell('Singles', s), cell('Doubles', d)],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
```

- [ ] **Step 4: Create `lib/ui/widgets/sparkline.dart`**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.color, this.height = 40});

  final List<double> values;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);
    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 2,
              color: color ?? Theme.of(context).colorScheme.primary,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create `lib/ui/widgets/score_stepper.dart`**

```dart
import 'package:flutter/material.dart';

class ScoreStepper extends StatelessWidget {
  const ScoreStepper({
    super.key, required this.label, required this.value, required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 36, child: Center(child: Text('$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
        ),
        IconButton(
          onPressed: value < 30 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
```

- [ ] **Step 6: Create `lib/ui/widgets/match_tile.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rally/models/match.dart';

class MatchTile extends StatelessWidget {
  const MatchTile({super.key, required this.match, required this.onTap});

  final MatchOut match;
  final VoidCallback onTap;

  String _scoreSummary() => match.games
      .map((g) => '${g.team1Points}–${g.team2Points}')
      .join(', ');

  Color _statusColor(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (match.status) {
      MatchStatus.pending => cs.tertiary,
      MatchStatus.validated => cs.primary,
      MatchStatus.disputed => cs.error,
      MatchStatus.expired => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(
          '${match.format == MatchFormat.singles ? 'Singles' : 'Doubles'} · ${_scoreSummary()}',
        ),
        subtitle: Text(DateFormat.yMMMd().add_jm().format(match.playedAt.toLocal())),
        trailing: Chip(
          label: Text(match.status.name),
          backgroundColor: _statusColor(context).withOpacity(0.15),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Create `lib/ui/widgets/empty_state.dart`**

```dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.inbox_outlined, size: 48),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Widget test `test/widgets/score_stepper_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/ui/widgets/score_stepper.dart';

void main() {
  testWidgets('increments and decrements', (tester) async {
    int v = 5;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (ctx, setState) {
          return ScoreStepper(
            label: 'Team 1', value: v,
            onChanged: (n) => setState(() => v = n),
          );
        }),
      ),
    ));
    expect(find.text('5'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    expect(find.text('6'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
  });
}
```

- [ ] **Step 9: Run test**

```bash
flutter test test/widgets/
```

Expected: 1 passed.

- [ ] **Step 10: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/ui/ mobile/test/widgets/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): theme + shared widgets"
```

---

## Task 9: Router + app shell

**Files:**
- Create: `mobile/lib/router.dart`
- Create: `mobile/lib/app.dart`
- Modify: `mobile/lib/main.dart`

The router gates routes by auth + by profile existence:

```
/onboarding/phone        (anyone, default if no session)
/onboarding/otp          (anyone, with verificationId+phone in extra)
/onboarding/profile      (authed but no Player row)
/home                    (authed + has profile)
/log                     (authed)
/match/:id               (authed)
/leaderboard             (authed)
/profile                 (authed)
```

- [ ] **Step 1: Create `lib/router.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/auth/auth_controller.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/screens/home/home_screen.dart';
import 'package:rally/ui/screens/leaderboard/leaderboard_screen.dart';
import 'package:rally/ui/screens/log_match/log_match_screen.dart';
import 'package:rally/ui/screens/match_detail/match_detail_screen.dart';
import 'package:rally/ui/screens/onboarding/otp_screen.dart';
import 'package:rally/ui/screens/onboarding/phone_screen.dart';
import 'package:rally/ui/screens/onboarding/profile_screen.dart';
import 'package:rally/ui/screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding/phone',
    redirect: (ctx, state) {
      final auth = ref.read(authControllerProvider).valueOrNull;
      final loggingIn = state.matchedLocation.startsWith('/onboarding');

      if (auth == null) return loggingIn ? null : '/onboarding/phone';

      // Authed. Check if profile exists.
      final player = ref.read(currentPlayerProvider).valueOrNull;
      if (player == null && state.matchedLocation != '/onboarding/profile') {
        // Avoid bouncing if we haven't tried yet.
        if (!ref.read(currentPlayerProvider).hasValue) return null;
        return '/onboarding/profile';
      }
      if (player != null && loggingIn) return '/home';
      return null;
    },
    refreshListenable: GoRouterRefreshNotifier(ref),
    routes: [
      GoRoute(path: '/onboarding/phone', builder: (_, __) => const PhoneScreen()),
      GoRoute(path: '/onboarding/otp', builder: (_, s) {
        final args = s.extra as Map<String, String>;
        return OtpScreen(
          verificationId: args['verificationId']!,
          phoneE164: args['phone']!,
        );
      }),
      GoRoute(path: '/onboarding/profile', builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/log', builder: (_, __) => const LogMatchScreen()),
      GoRoute(path: '/match/:id', builder: (_, s) =>
          MatchDetailScreen(matchId: s.pathParameters['id']!)),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
    ref.listen(currentPlayerProvider, (_, __) => notifyListeners());
  }
}
```

- [ ] **Step 2: Create `lib/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/router.dart';
import 'package:rally/ui/theme.dart';

class RallyApp extends ConsumerWidget {
  const RallyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Rally',
      theme: RallyTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 3: Replace `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/app.dart';
import 'package:rally/core/firebase_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureFirebase();
  runApp(const ProviderScope(child: RallyApp()));
}
```

- [ ] **Step 4: Create empty stub screens so the router compiles**

For each screen path referenced in the router, create a stub file. We fill them in subsequent tasks.

`mobile/lib/ui/screens/onboarding/phone_screen.dart`:
```dart
import 'package:flutter/material.dart';
class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Phone (stub)')));
}
```

`mobile/lib/ui/screens/onboarding/otp_screen.dart`:
```dart
import 'package:flutter/material.dart';
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key, required this.verificationId, required this.phoneE164});
  final String verificationId;
  final String phoneE164;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('OTP $phoneE164 (stub)')));
}
```

`mobile/lib/ui/screens/onboarding/profile_screen.dart`:
```dart
import 'package:flutter/material.dart';
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profile setup (stub)')));
}
```

`mobile/lib/ui/screens/home/home_screen.dart`:
```dart
import 'package:flutter/material.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home (stub)')));
}
```

`mobile/lib/ui/screens/log_match/log_match_screen.dart`:
```dart
import 'package:flutter/material.dart';
class LogMatchScreen extends StatelessWidget {
  const LogMatchScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Log match (stub)')));
}
```

`mobile/lib/ui/screens/match_detail/match_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';
class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.matchId});
  final String matchId;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Match $matchId (stub)')));
}
```

`mobile/lib/ui/screens/leaderboard/leaderboard_screen.dart`:
```dart
import 'package:flutter/material.dart';
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Leaderboard (stub)')));
}
```

`mobile/lib/ui/screens/profile/profile_screen.dart`:
```dart
import 'package:flutter/material.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profile (stub)')));
}
```

- [ ] **Step 5: Build sanity**

```bash
flutter analyze lib/
```

- [ ] **Step 6: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): router + app shell + screen stubs"
```

---

## Task 10: Onboarding — phone + OTP screens

**Files:**
- Modify: `mobile/lib/ui/screens/onboarding/phone_screen.dart`
- Modify: `mobile/lib/ui/screens/onboarding/otp_screen.dart`

- [ ] **Step 1: Replace `phone_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/auth/auth_controller.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});
  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  Future<void> _send() async {
    final raw = _controller.text.trim().replaceAll(RegExp(r'\D'), '');
    if (raw.length != 10) {
      setState(() => _error = 'Enter a 10-digit Indian mobile number');
      return;
    }
    setState(() { _sending = true; _error = null; });
    final phone = '+91$raw';
    try {
      final vid = await ref.read(authControllerProvider.notifier).sendOtp(phone);
      if (!mounted) return;
      context.push('/onboarding/otp', extra: {
        'verificationId': vid, 'phone': phone,
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Text('Welcome to Rally',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Enter your phone number to get started.'),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                  labelText: 'Mobile number',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Replace `otp_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/auth/auth_controller.dart';
import 'package:rally/env.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.verificationId, required this.phoneE164});
  final String verificationId;
  final String phoneE164;
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  bool _verifying = false;
  String? _error;

  Future<void> _verify() async {
    final otp = _controller.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() { _verifying = true; _error = null; });
    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(
        verificationId: widget.verificationId,
        otp: otp, phone: widget.phoneE164,
      );
      if (mounted) context.go('/onboarding/profile');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Verify ${widget.phoneE164}',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(Env.isDev
                ? 'Dev mode: enter 123456'
                : 'Enter the 6-digit code we sent over SMS.'),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'OTP',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _verifying ? null : _verify,
              child: _verifying
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/ui/screens/onboarding/
```

- [ ] **Step 4: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/ui/screens/onboarding/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): phone + OTP onboarding screens"
```

---

## Task 11: Onboarding — profile setup screen

Once authed, if no Player row exists for this Firebase UID, prompt for display name and optional gender/DOB, then `POST /players`.

**Files:**
- Modify: `mobile/lib/ui/screens/onboarding/profile_screen.dart`

- [ ] **Step 1: Replace `profile_screen.dart`**

```dart
import 'package:flutter/material.dart';
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
  String? _gender;
  DateTime? _dob;
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter your name'); return;
    }
    setState(() { _saving = true; _error = null; });
    final res = await ref.read(playersApiProvider).create(
      displayName: _name.text.trim(), gender: _gender, dob: _dob,
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
            DropdownButtonFormField<String>(
              value: _gender,
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
```

- [ ] **Step 2: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/ui/screens/onboarding/profile_screen.dart && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): profile setup screen"
```

---

## Task 12: Home screen — rating card, pending list, recent matches, nav

**Files:**
- Modify: `mobile/lib/ui/screens/home/home_screen.dart`

- [ ] **Step 1: Replace `home_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/state/pending_matches_provider.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';
import 'package:rally/ui/widgets/match_tile.dart';
import 'package:rally/ui/widgets/rating_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final pending = ref.watch(pendingMatchesProvider);
    final recent = ref.watch(recentMatchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rally')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), label: 'Leaderboard'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onDestinationSelected: (i) {
          if (i == 1) context.push('/leaderboard');
          if (i == 2) context.push('/profile');
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/log'),
        icon: const Icon(Icons.add),
        label: const Text('Log a match'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentPlayerProvider);
          ref.invalidate(pendingMatchesProvider);
          ref.invalidate(recentMatchesProvider);
          await ref.read(currentPlayerProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AsyncValueView(
              value: player,
              data: (p) => p == null
                  ? const EmptyState(message: 'No profile yet')
                  : RatingCard(ratings: p.ratings),
            ),
            const SizedBox(height: 16),
            Text('Awaiting your confirmation',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            AsyncValueView(
              value: pending,
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Nothing to confirm.'),
                    )
                  : Column(
                      children: [
                        for (final m in list)
                          MatchTile(match: m, onTap: () => context.push('/match/${m.id}'))
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Text('Recent matches',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            AsyncValueView(
              value: recent,
              data: (list) => list.isEmpty
                  ? const EmptyState(message: 'Log your first match to get started.')
                  : Column(
                      children: [
                        for (final m in list)
                          MatchTile(match: m, onTap: () => context.push('/match/${m.id}'))
                      ],
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/ui/screens/home/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): home screen with rating, pending, recent matches"
```

---

## Task 13: Log-a-match wizard

**Files:**
- Create: `mobile/lib/ui/screens/log_match/log_match_controller.dart`
- Modify: `mobile/lib/ui/screens/log_match/log_match_screen.dart`

The wizard has 4 visible steps in a single `Stepper` widget for MVP simplicity: Format → Players → Scores → Review.

- [ ] **Step 1: Create `log_match_controller.dart`**

```dart
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
```

- [ ] **Step 2: Replace `log_match_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/api/matches_api.dart';
import 'package:rally/models/match.dart';
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
    setState(() { _submitting = true; _error = null; });
    final res = await ref.read(matchesApiProvider).submit(body);
    if (!mounted) return;
    res.fold(
      onOk: (m) {
        ref.invalidate(recentMatchesProvider);
        context.go('/match/${m.id}');
      },
      onErr: (e) => setState(() { _error = e.message; _submitting = false; }),
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
          if (_step < 3) setState(() => _step++);
          else _submit();
        },
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        controlsBuilder: (_, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(children: [
            FilledButton(
              onPressed: _submitting ? null : details.onStepContinue,
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_step == 3 ? 'Submit' : 'Continue'),
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
                Text('${s.format == MatchFormat.singles ? 'Singles' : 'Doubles'}'),
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
```

- [ ] **Step 2: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/ui/screens/log_match/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): log-a-match wizard"
```

---

## Task 14: Match detail screen — score, participants, confirm/dispute, deltas

**Files:**
- Modify: `mobile/lib/ui/screens/match_detail/match_detail_screen.dart`

- [ ] **Step 1: Replace `match_detail_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:rally/api/matches_api.dart';
import 'package:rally/models/match.dart';
import 'package:rally/state/pending_matches_provider.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/widgets/async_value_view.dart';

final _matchProvider = FutureProvider.family<MatchOut, String>((ref, id) async {
  final res = await ref.watch(matchesApiProvider).get(id);
  return res.fold(onOk: (m) => m, onErr: (e) => throw e);
});

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(_matchProvider(matchId));
    final me = ref.watch(currentPlayerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Match')),
      body: AsyncValueView(
        value: match,
        data: (m) => _MatchView(match: m, myPhone: me?.phoneE164, refresh: () {
          ref.invalidate(_matchProvider(matchId));
          ref.invalidate(pendingMatchesProvider);
          ref.invalidate(recentMatchesProvider);
        }),
      ),
    );
  }
}

class _MatchView extends ConsumerStatefulWidget {
  const _MatchView({required this.match, required this.myPhone, required this.refresh});
  final MatchOut match;
  final String? myPhone;
  final VoidCallback refresh;
  @override
  ConsumerState<_MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends ConsumerState<_MatchView> {
  bool _busy = false;
  String? _error;

  bool get _isMine => widget.match.participants.any(
        (p) => p.phoneE164 == widget.myPhone,
      );

  bool get _amSubmitter => widget.match.participants
      .firstWhere(
        (p) => p.phoneE164 == widget.myPhone,
        orElse: () => const Participant(
          phoneE164: '', team: 0, isSubmitter: false, confirmed: false, disputed: false,
        ),
      )
      .isSubmitter;

  Future<void> _do(Future<dynamic> Function() action) async {
    setState(() { _busy = true; _error = null; });
    try {
      await action();
      widget.refresh();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m.format == MatchFormat.singles ? 'Singles' : 'Doubles'} · ${m.status.name}',
                  style: theme.textTheme.titleMedium,
                ),
                Text(DateFormat.yMMMd().add_jm().format(m.playedAt.toLocal())),
                if (m.venue != null) Text('At ${m.venue!}'),
                const SizedBox(height: 12),
                for (final g in m.games)
                  Text('Game ${g.gameNo}: ${g.team1Points} – ${g.team2Points}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Players', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final p in m.participants)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${p.team}')),
                    title: Text(p.displayName ?? '(invited) ${p.phoneE164}'),
                    subtitle: Text([
                      if (p.isSubmitter) 'submitter',
                      if (p.confirmed) 'confirmed',
                      if (p.disputed) 'disputed',
                    ].join(' · ')),
                    trailing: _DeltaText(playerId: p.playerId, deltas: m.ratingDeltas),
                  ),
              ],
            ),
          ),
        ),
        if (_isMine && m.status == MatchStatus.pending && !_amSubmitter) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () =>
                    _do(() => ref.read(matchesApiProvider).confirm(m.id)),
                child: const Text('Confirm'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () =>
                    _do(() => ref.read(matchesApiProvider).dispute(m.id)),
                child: const Text('Dispute'),
              ),
            ),
          ]),
        ] else if (_isMine && m.status == MatchStatus.validated) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : () =>
                _do(() => ref.read(matchesApiProvider).dispute(m.id)),
            child: const Text('Dispute (within 7 days)'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }
}

class _DeltaText extends StatelessWidget {
  const _DeltaText({required this.playerId, required this.deltas});
  final String? playerId;
  final List<RatingDelta> deltas;

  @override
  Widget build(BuildContext context) {
    if (playerId == null) return const SizedBox.shrink();
    final d = deltas.where((e) => e.playerId == playerId).firstOrNull;
    if (d == null) return const SizedBox.shrink();
    final delta = d.ratingAfter - d.ratingBefore;
    final sign = delta >= 0 ? '+' : '';
    final color = delta >= 0
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;
    return Text('$sign${delta.toStringAsFixed(2)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600));
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
```

- [ ] **Step 2: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/ui/screens/match_detail/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): match detail with confirm/dispute"
```

---

## Task 15: Leaderboard screen

**Files:**
- Modify: `mobile/lib/ui/screens/leaderboard/leaderboard_screen.dart`

- [ ] **Step 1: Replace `leaderboard_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rally/state/leaderboard_provider.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(leaderboardFormatProvider);
    final gen = ref.watch(leaderboardGenderProvider);
    final data = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bangalore leaderboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'S', label: Text('Singles')),
                    ButtonSegment(value: 'D', label: Text('Doubles')),
                  ],
                  selected: {fmt},
                  onSelectionChanged: (v) =>
                      ref.read(leaderboardFormatProvider.notifier).state = v.first,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'M', label: Text('Men')),
                    ButtonSegment(value: 'F', label: Text('Women')),
                  ],
                  selected: {gen},
                  onSelectionChanged: (v) =>
                      ref.read(leaderboardGenderProvider.notifier).state = v.first,
                ),
              ],
            ),
          ),
        ),
      ),
      body: AsyncValueView(
        value: data,
        data: (r) => r.entries.isEmpty
            ? const EmptyState(
                message: 'Not enough players with 5+ matches yet. Be the first.',
                icon: Icons.timer_outlined,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: r.entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = r.entries[i];
                  return ListTile(
                    leading: SizedBox(
                      width: 32,
                      child: Text('#${e.rank}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    title: Text(e.displayName),
                    subtitle: Text('${e.matchesPlayed} matches'),
                    trailing: Text(e.rating.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.titleMedium),
                  );
                },
              ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/ui/screens/leaderboard/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): leaderboard screen"
```

---

## Task 16: Profile screen — stats, history graph, match list, sign out

**Files:**
- Modify: `mobile/lib/ui/screens/profile/profile_screen.dart`

- [ ] **Step 1: Replace `profile_screen.dart`**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/api/players_api.dart';
import 'package:rally/auth/auth_controller.dart';
import 'package:rally/models/rating_event.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';
import 'package:rally/ui/widgets/match_tile.dart';

final _historyProvider = FutureProvider<List<RatingHistoryPoint>>((ref) async {
  final res = await ref.watch(playersApiProvider).ratingHistory();
  return res.fold(onOk: (h) => h, onErr: (e) => throw e);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final history = ref.watch(_historyProvider);
    final matches = ref.watch(recentMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/onboarding/phone');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AsyncValueView(
            value: player,
            data: (p) => p == null
                ? const EmptyState(message: 'No profile')
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.displayName,
                              style: Theme.of(context).textTheme.headlineMedium),
                          Text(p.phoneE164),
                          const SizedBox(height: 8),
                          for (final r in p.ratings)
                            Text('${r.format.name}: ${r.rating.toStringAsFixed(2)} '
                                '(${r.matchesPlayed} matches)'),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text('Rating history (last 90 days)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AsyncValueView(
            value: history,
            data: (events) => events.isEmpty
                ? const EmptyState(message: 'No rated matches yet.')
                : _HistoryChart(events: events),
          ),
          const SizedBox(height: 16),
          Text('Match history',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AsyncValueView(
            value: matches,
            data: (list) => list.isEmpty
                ? const EmptyState(message: 'No matches.')
                : Column(
                    children: [
                      for (final m in list)
                        MatchTile(match: m, onTap: () => context.push('/match/${m.id}'))
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.events});
  final List<RatingHistoryPoint> events;

  @override
  Widget build(BuildContext context) {
    final s = events.where((e) => e.format == 'S').toList();
    final d = events.where((e) => e.format == 'D').toList();

    LineChartBarData barFor(List<RatingHistoryPoint> pts, Color color) =>
        LineChartBarData(
          spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i].ratingAfter)],
          color: color, isCurved: true, barWidth: 2,
          dotData: const FlDotData(show: false),
        );

    return SizedBox(
      height: 180,
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (s.isNotEmpty) barFor(s, Theme.of(context).colorScheme.primary),
          if (d.isNotEmpty) barFor(d, Theme.of(context).colorScheme.tertiary),
        ],
      )),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/ui/screens/profile/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): profile screen with rating history graph"
```

---

## Task 17: FCM push registration

**Files:**
- Create: `mobile/lib/push/fcm_service.dart`
- Modify: `mobile/lib/main.dart`

For MVP, push handling is minimal: register the FCM token (no-op in dev), and on foreground push refresh the relevant providers. The backend currently topic-subscribes per-uid; we'll wire device-token registration in Plan 3.

- [ ] **Step 1: Create `lib/push/fcm_service.dart`**

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rally/env.dart';
import 'package:rally/state/pending_matches_provider.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';

class FcmService {
  FcmService(this.ref);
  final Ref ref;

  Future<void> init() async {
    if (Env.isDev) return;
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onMessage.listen((msg) {
      final kind = msg.data['kind'];
      if (kind == 'match_submitted') {
        ref.invalidate(pendingMatchesProvider);
      } else if (kind == 'match_validated' || kind == 'match_auto_validated') {
        ref.invalidate(currentPlayerProvider);
        ref.invalidate(pendingMatchesProvider);
        ref.invalidate(recentMatchesProvider);
      }
    });
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(ref));
```

- [ ] **Step 2: Update `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/app.dart';
import 'package:rally/core/firebase_init.dart';
import 'package:rally/push/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureFirebase();
  final container = ProviderContainer();
  await container.read(fcmServiceProvider).init();
  runApp(UncontrolledProviderScope(
    container: container,
    child: const RallyApp(),
  ));
}
```

- [ ] **Step 3: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/lib/push/ mobile/lib/main.dart && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "feat(mobile): FCM push wiring (dev no-op)"
```

---

## Task 18: Smoke test on dev backend

**Files:**
- Create: `mobile/integration_test/onboarding_smoke_test.dart`

End-to-end check that the app boots, onboarding-OTP-profile creates a player against a running backend, and the home rating card shows 3.50/3.50.

- [ ] **Step 1: Create `integration_test/onboarding_smoke_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rally/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full onboarding to home', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    // Phone screen
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    // OTP screen
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    // Profile setup
    await tester.enterText(find.byType(TextField).first, 'Smoke Tester');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Home
    expect(find.text('Rally'), findsOneWidget);
    expect(find.text('3.50'), findsWidgets); // singles + doubles seed rating
  });
}
```

- [ ] **Step 2: Prerequisites for running**

The backend from Plan 1 must be running:

```bash
cd /Users/davidgarg20/Documents/startup_0/backend && docker compose up -d
```

Either point the app at it, or run on an Android emulator and use `--dart-define=API_BASE_URL=http://10.0.2.2:8000`.

- [ ] **Step 3: Run integration test**

```bash
cd /Users/davidgarg20/Documents/startup_0/mobile && \
flutter test integration_test/onboarding_smoke_test.dart \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Expected: test passes against the running backend.

If running without a backend, skip this step and report it as a known prerequisite for Plan 3.

- [ ] **Step 4: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/integration_test/ && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "test(mobile): onboarding smoke integration test"
```

---

## Task 19: Final analyze + README polish

**Files:**
- Modify: `mobile/README.md`

- [ ] **Step 1: Run analyzer + tests**

```bash
cd /Users/davidgarg20/Documents/startup_0/mobile && \
flutter analyze && flutter test
```

Fix any errors. Acceptable warnings: `invalid_annotation_target` from freezed (already excluded), and `prefer_const_constructors` info-level on screen widgets that take dynamic inputs.

- [ ] **Step 2: Update README**

```markdown
# Rally Mobile

Flutter app for the Rally badminton-rating MVP (iOS + Android).

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Run against local backend

Start the backend (`backend/`) on port 8000, then:

```bash
# iOS simulator (host networking just works)
flutter run --dart-define=API_BASE_URL=http://localhost:8000

# Android emulator (10.0.2.2 maps to host)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Dev mode bypasses real Firebase: enter any 10-digit phone, then OTP `123456`.

## Screens

- Onboarding (phone, OTP, profile setup)
- Home (rating card, pending validations, recent matches)
- Log a match (singles/doubles wizard)
- Match detail (confirm/dispute)
- Leaderboard (Bangalore, singles/doubles, gender filter)
- Profile (stats, rating-history chart, sign out)

## Tests

```bash
flutter test                         # unit + widget
flutter test integration_test/       # against running backend
```
```

- [ ] **Step 3: Commit**

```bash
git -C /Users/davidgarg20/Documents/startup_0 add mobile/README.md && \
git -C /Users/davidgarg20/Documents/startup_0 commit -m "docs(mobile): finalize README"
```

---

## Done criteria for Plan 2

- All 19 tasks complete.
- `flutter analyze` passes with no errors.
- `flutter test` passes (model serialization, widget tests, score-stepper).
- On a connected emulator with the backend running, the user can: enter phone → OTP `123456` → enter display name → see home with rating card showing 3.50 S and 3.50 D, log a singles match against another dev-token user, have that user confirm it, and see rating deltas in the match detail screen.
- Push notifications are wired but only fire against real Firebase (deferred to Plan 3).

Plan 3 (GCP deploy + Firebase wiring + SMS) follows once Plan 2 is green.
