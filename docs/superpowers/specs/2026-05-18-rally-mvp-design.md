# Rally MVP — Design Spec

**Date:** 2026-05-18
**Status:** Draft, pending user review
**Owner:** John Doe

## 1. Goal

Ship a cross-platform mobile app (iOS + Android) that lets amateur badminton players in Bangalore log singles or doubles matches, get an opponent-validated Glicko-2 rating on a 1.0–7.0 scale, and see a city-wide leaderboard. Target: 3 months, built solo.

This MVP is the "player core" slice. Tournament software, organizer dashboard, matchmaking, video analysis, and premium features are explicitly out of scope.

## 2. Success criteria

A user can:

1. Sign up via phone OTP in under 60 seconds and land on a home screen showing their starting rating.
2. Log a singles or doubles match against an opponent identified by phone number, including opponents who are not yet on the app.
3. Have an opposing player confirm the match via push notification (or auto-validate after 72 hours).
4. See their Glicko-2 rating change immediately upon validation, with a delta animation.
5. View the Bangalore city leaderboard for singles and doubles, filterable by gender.
6. Open any past match and see the score, participants, and per-player rating deltas.

Quality bar: cold-start to home screen under 2 seconds on a mid-range Android. Match submission round-trip under 1 second.

## 3. Architecture

```
┌──────────────────┐                ┌────────────────────────────┐
│  Flutter app     │   HTTPS/JSON   │  FastAPI on Cloud Run      │
│  (iOS + Android) │ ─────────────▶ │  (stateless, autoscale)    │
│                  │   Firebase     │                            │
│  Firebase SDK    │   ID token     │  - Auth: verify Firebase   │
│  (auth, push)    │                │    JWT on every request    │
└──────────────────┘                │  - Match domain logic      │
        ▲                           │  - Glicko-2 update (sync)  │
        │ FCM push                  │  - Leaderboard read API    │
        │                           └──────┬─────────────┬───────┘
        │                                  │             │
        │                          ┌───────▼─────┐  ┌────▼─────────┐
        └──────────────────────────┤ Cloud SQL   │  │ Cloud        │
                                   │ Postgres 16 │  │ Scheduler    │
                                   │ (private IP)│  │ (10-min job) │
                                   └─────────────┘  └──────────────┘
```

### 3.1 Components

- **Flutter app** — single codebase for iOS and Android. Firebase SDK for phone OTP auth and FCM push. All domain data fetched from FastAPI.
- **FastAPI service on Cloud Run** — stateless, autoscaling 0..N. Verifies the Firebase ID token on every authenticated request. Owns all domain logic including Glicko-2.
- **Cloud SQL Postgres 16** — single primary, private IP, daily backups. Source of truth for all domain state.
- **Firebase project** — phone OTP, FCM push delivery, optional analytics. No Firestore.
- **Cloud Scheduler** — invokes `POST /internal/expire-matches` every 10 minutes to auto-validate pending matches past their 72h deadline. Single shared secret for auth.

### 3.2 Why this shape

A monolithic Cloud Run service is the right unit of deployment for a solo developer building a 3-month MVP. Scales to zero when idle (~$5–20/mo at MVP traffic), scales horizontally during tournaments. Firebase handles the parts that are tedious to roll yourself (OTP, push). Postgres owns truth because the queries we need (sorted leaderboards, multi-player match invariants) are relational. No Redis or queues in v1 — Postgres handles the load until ~10K DAU.

## 4. Data model

### 4.1 Tables

```sql
players (
  id              uuid pk,
  phone_e164      text unique not null,        -- +919876543210
  display_name    text not null,
  gender          text check (gender in ('M','F','O')) null,
  dob             date null,
  home_city       text not null default 'BLR',
  firebase_uid    text unique not null,
  created_at      timestamptz default now()
)

player_ratings (
  player_id       uuid references players(id),
  format          text check (format in ('S','D')),  -- singles/doubles
  rating          double precision not null default 3.5,
  rd              double precision not null default 1.2,
  volatility      double precision not null default 0.06,
  matches_played  int not null default 0,
  updated_at      timestamptz default now(),
  primary key (player_id, format)
)

matches (
  id                    uuid pk,
  format                text check (format in ('S','D')) not null,
  played_at             timestamptz not null,
  venue                 text null,
  submitted_by          uuid references players(id),
  status                text check (status in
                          ('pending','validated','disputed','expired'))
                        not null,
  validation_deadline   timestamptz not null,         -- submitted_at + 72h
  validated_at          timestamptz null,
  created_at            timestamptz default now()
)

match_participants (
  match_id        uuid references matches(id),
  player_id       uuid references players(id),
  team            smallint check (team in (1,2)) not null,
  is_submitter    boolean not null default false,
  confirmed_at    timestamptz null,
  disputed_at     timestamptz null,
  primary key (match_id, player_id)
)

match_games (
  match_id        uuid references matches(id),
  game_no         smallint check (game_no between 1 and 5),
  team1_points    smallint not null,
  team2_points    smallint not null,
  primary key (match_id, game_no)
)

rating_events (
  id              bigserial pk,
  player_id       uuid not null references players(id),
  match_id        uuid not null references matches(id),
  format          text not null,
  rating_before   double precision not null,
  rating_after    double precision not null,
  rd_before       double precision not null,
  rd_after        double precision not null,
  created_at      timestamptz default now()
)

match_invites (
  match_id        uuid references matches(id),
  phone_e164      text not null,
  team            smallint check (team in (1,2)) not null,
  invited_at      timestamptz default now(),
  primary key (match_id, phone_e164)
)
```

### 4.2 Indexes

- `player_ratings (format, rating desc)` filtered by joining on `players.home_city='BLR'` and `matches_played >= 5` — for the city leaderboard.
- `matches (status, validation_deadline)` partial index where `status='pending'` — for the expiry job.
- `rating_events (player_id, created_at desc)` — for the profile rating-history graph.
- `match_participants (player_id, match_id)` — for "matches I'm in".
- `match_invites (phone_e164)` — for invite lookup on new signup.

### 4.3 Design notes

- **Two ratings per player.** Singles and doubles ability diverge; one rating would lie.
- **`match_participants` is the relationship table** with per-participant `confirmed_at` and `disputed_at`. Singles has 2 rows, doubles has 4. Uniform handling downstream.
- **`rating_events`** is append-only and immutable except via dispute rollback. Powers the rating history graph and dispute recomputation.
- **`match_invites`** holds opponents named by phone but not yet on the app. On new signup, we look up invites by phone and surface them in the home screen as pending validations.
- **Venue** is free text in MVP. We will model venues as entities in v1.1 when partnerships warrant it.

## 5. Match lifecycle

### 5.1 Submit

`POST /matches` with format, played_at, venue, games[], team1[phones], team2[phones].

- The submitter must appear in exactly one team.
- No phone may appear on both teams.
- For each non-registered phone, create a `match_invites` row and send an SMS deeplink ("X logged a match against you on Rally — tap to confirm").
- For each registered phone, create a `match_participants` row and send an FCM push.
- Mark `is_submitter=true` and `confirmed_at=now()` on the submitter's row (implicit confirmation from the submitter's side).
- `matches.status = 'pending'`; `validation_deadline = now() + 72h`.

### 5.2 Validate

A match becomes `validated` when **at least one player on the team opposite the submitter** taps Confirm, or when the 72h deadline elapses with no dispute.

`POST /matches/{id}/confirm` (from a participant):

1. Set `match_participants.confirmed_at = now()` for the confirmer.
2. If confirmer is on opposing team AND `matches.status = 'pending'`, run validation inside a single transaction:
   - Set `matches.status = 'validated'`, `validated_at = now()`.
   - Compute Glicko-2 update for all participants (see §6).
   - Insert one `rating_events` row per participant.
   - Update `player_ratings` (rating, rd, volatility, matches_played += 1).
3. Send FCM push to all participants with the new rating and delta.

### 5.3 Dispute

`POST /matches/{id}/dispute` (from any participant) within 72h of submission OR within 7 days of validation:

- If status is `pending`: set `disputed_at`, set `status = 'disputed'`. No rating impact (none yet).
- If status is `validated`: roll back by reversing the `rating_events` rows for this match (subtract deltas from current `player_ratings`), set `status = 'disputed'`.
- MVP has no arbitration UI. Disputed matches are excluded from ratings and surfaced in an admin console for manual handling.

### 5.4 Expire

Cloud Scheduler invokes `POST /internal/expire-matches` every 10 minutes:

- For each `matches` row where `status='pending'` AND `validation_deadline < now()`:
  - Treat as silently-accepted by opposing team. Run the validation transaction in §5.2.
- Idempotent: the query and transaction together guarantee single processing.

### 5.5 Edge cases handled explicitly

- **Same match submitted twice.** Dedup on `(submitted_by, played_at ± 15min, sorted set of participant phones)`. Reject second submission with 409.
- **Score sanity.** Each game must have a winner reaching ≥21 with a 2-point lead, capped at 30. Best-of-N is not enforced.
- **Doubles with mixed registered/unregistered opponents.** Validation requires either a registered opposing-team confirmation or the 72h timeout. Unregistered opponents who never sign up are treated as "no objection".
- **Submitter on losing team.** Their implicit confirmation still counts; opposing-team confirmation still required.
- **New signup with pending invites.** On signup, scan `match_invites` by phone. Insert `match_participants` rows for each, surface as "pending matches" in home.

## 6. Rating math

### 6.1 Singles

Textbook Glicko-2 update with one opponent and outcome 0 or 1 (no draws in badminton). Step size τ = 0.5. Rating, RD, and volatility updated using the standard Glassman formulas, scaled to our 1.0–7.0 display range.

Implementation: a pure Python module `rating/glicko2.py` with one function `update(player, opponents, scores) -> (rating, rd, volatility)`. Stateless and unit-testable in isolation against the published Glicko-2 reference values.

### 6.2 Doubles

Each player is updated using a single virtual opponent:

- `team_rating_self = (p1.rating + p2.rating) / 2`
- `team_rating_opp = (q1.rating + q2.rating) / 2`
- `team_rd_opp = sqrt((q1.rd² + q2.rd²) / 2)` — quadrature of opposing RDs.
- Run standard Glicko-2 update for each player vs that single virtual opponent with the team's win outcome.

Then apply a **carry-weight scaler** so the lower-rated teammate moves more:

```
scaler = clamp(team_rating_self / player.rating, 0.5, 1.5)
final_delta = base_delta * scaler
```

- Lower-rated teammate has `player.rating < team_avg`, so `scaler > 1` — bigger swing.
- Higher-rated teammate has `player.rating > team_avg`, so `scaler < 1` — smaller swing.
- Clamp at [0.5, 1.5] prevents extreme behavior at large rating gaps.

The scaler is applied to the rating delta only, not to RD or volatility (those follow standard Glicko-2 evolution).

### 6.3 Seeding

Every new player starts at `rating=3.5, rd=1.2, volatility=0.06` in both formats. High RD ensures rapid convergence over the first 5–10 matches. No self-declared level questionnaire in MVP.

## 7. API surface

All endpoints require Firebase ID token in `Authorization: Bearer <jwt>` except `/internal/*` (shared secret) and `/healthz`.

```
POST   /players                       Create on first sign-in (idempotent on firebase_uid)
GET    /players/me                    Profile + current ratings
PATCH  /players/me                    Update display_name, gender, dob, home_city
GET    /players/me/matches?status=    List my matches
GET    /players/me/rating-history     Rating events for graph (last 90d default)

POST   /matches                       Submit a new match
GET    /matches/{id}                  Match detail
POST   /matches/{id}/confirm          Confirm participation
POST   /matches/{id}/dispute          Dispute a match

GET    /leaderboard?format=S|D&gender=All|M|F&limit=100
                                      City leaderboard (BLR only in MVP)

POST   /internal/expire-matches       Cron-only; shared-secret auth
GET    /healthz                       Liveness
```

Errors return `{code, message}` with stable codes (`auth_required`, `duplicate_match`, `not_a_participant`, `invalid_score`, etc.).

## 8. App surface (Flutter)

Six screens:

1. **Onboarding** — phone OTP → display name → optional gender/DOB → city defaults to BLR.
2. **Home** — rating card (S + D, sparkline), Log-a-match CTA, pending validations list, recent matches, bottom nav.
3. **Log a match** — wizard: format → teammate (D) → opponents → scores → date/venue → submit.
4. **Match detail** — score, participants, status, per-player rating deltas, Confirm/Dispute buttons when applicable.
5. **Leaderboard** — Bangalore, tabs for Singles/Doubles, gender filter, min 5 matches to appear.
6. **Profile** — stats, rating history graph, match history, edit profile, sign out.

Out of MVP: matchmaking, friends/follows, club entities, tournaments, settings beyond edit-profile, push preferences screen, premium features.

Push notifications: (1) "X logged a match against you" on submit, (2) "Match validated — rating updated" on validation, (3) "<24h to confirm" reminder.

## 9. Testing strategy

- **Unit tests** for `rating/glicko2.py` against published Glicko-2 reference values, plus golden tests for the doubles scaler edge cases (equal teammates, large gap, RD propagation).
- **API contract tests** for each endpoint with a real ephemeral Postgres (testcontainers).
- **End-to-end match lifecycle tests:** submit → confirm → validated; submit → no-action → expired-validated; submit → dispute → rolled back. All against a real DB.
- **Flutter widget tests** for the match-log wizard form validation and the home rating card rendering.
- **Manual smoke** on a real Android and iOS device before each deploy.

## 10. Out of scope for MVP

Listed here so we don't drift:

- Matchmaking / find-a-partner within 5km
- Friends graph, social feed, follows
- Clubs and venues as first-class entities
- Tournament brackets and organizer dashboard
- Corporate league software
- Video shot analysis, training plans
- Web app (organizer dashboard is Phase 2)
- Multi-city beyond Bangalore
- Premium subscription / billing
- Coaching marketplace, equipment affiliate

## 11. Open questions

None blocking. Decisions punted to v1.1 where flagged. Admin console for handling disputes will be a thin internal tool, not part of MVP scope but needed before public launch — tracked separately.
