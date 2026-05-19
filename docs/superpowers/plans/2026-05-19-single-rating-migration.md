# Single Rating Migration Plan

> Collapse the two-format (S + D) rating system into a single rating per
> player. Singles and doubles both update the same rating; the format
> distinction becomes purely cosmetic metadata on each match.

**Goal:** One rating per player. Simpler engine, simpler UI, simpler share
cards. Cross-format matches mix into the same rating naturally.

**Scope:** Backend engine + database + API + Flutter app + seed script.

---

## Confirmed design decisions

1. **Single rating per player.** No singles/doubles split.
2. **Margin amplification stays.** `(winner − loser) / winner` × `BETA_MARGIN=0.7`.
3. **No length factor.** `match_format` was removed; every match acts like a
   "21-point" match; the length factor would always be 1.0. Drop it from
   the engine for clarity.
4. **Doubles uses team-average opponent + equal per-partner share.** Both
   partners get the same delta. (We previously had asymmetric — lower-rated
   wins more credit. Dropping that to match the snippet's simpler design.)
5. **Floor at 100.** No rating below 100.
6. **Initial state:** rating=1500, rd=350, vol=0.06.
7. **No self-rating prior.** Skip the `player_with_self_rating()` path; we
   already decided beginners just earn their position over the first 5–10
   matches.
8. **Wrap our existing Glicko-2 implementation.** No new dependency.
9. **Fix the `*2` → `**2` arithmetic bugs in the snippet.**

## Open questions before execution

- Do we drop the per-format rating storage entirely, or keep
  `player_ratings` rows as historical/analytics? **Recommended: drop them
  in a migration; keep `rating_events.format` for analytics.**
- Existing rating data: do we reset all ratings on migration, or backfill
  from the weighted overall? **Recommended: backfill from overall** so
  existing demo data stays useful.

---

## Architecture sketch

### Database

**Add to `players` table:**
- `rating DOUBLE NOT NULL DEFAULT 1500`
- `rd DOUBLE NOT NULL DEFAULT 350`
- `volatility DOUBLE NOT NULL DEFAULT 0.06`
- `matches_played INTEGER NOT NULL DEFAULT 0`

**Drop:**
- `player_ratings` table (after backfill into `players`)
- `rating_events.format` column (or keep nullable for backward compat)

**Backfill:**
For each existing player, compute the match-count-weighted overall from
their current `player_ratings` rows, and use it as the new `players.rating`.
RD and volatility take whichever format had the lower RD (most confident).

### Engine

`app/rating/engine.py` becomes:

```python
def update_singles(winner: Player, loser: Player,
                   w_score: int, l_score: int) -> (snap_w, snap_l):
    # Standard Glicko-2 update with margin amplification.

def update_doubles(winners: (Player, Player),
                   losers: (Player, Player),
                   w_score: int, l_score: int) -> tuple of 4 snaps:
    # Each player updated as if they played 1v1 vs opposing team average.
    # Team average rating: arithmetic mean.
    # Team average RD: quadrature mean sqrt((a.rd**2 + b.rd**2) / 2).
    # Equal share — no asymmetric split.

def age_rating(player: Player, periods_inactive: int):
    # Glicko-2 step 6: phi' = sqrt(phi**2 + N * sigma**2)
```

All format references drop from public API. `Player` class stays mutable
(stateful wrapper around our pure Glicko-2 update function).

### Service layer

`app/rating/service.py`:
- Loads `players` row (not `player_ratings`)
- Calls engine
- Writes `rating_events` row per participant (now: 2 for singles, 4 for doubles)
- Updates `players.rating`, `.rd`, `.volatility`, `.matches_played` in place

### API surface

**`Player` response (current):**
```json
{
  "id": "...",
  "phone_e164": "...",
  "username": "...",
  "display_name": "...",
  "ratings": [
    {"format": "S", "rating": 1547, "rd": 282, "matches_played": 5},
    {"format": "D", "rating": 1481, "rd": 320, "matches_played": 3}
  ],
  "overall": {"rating": 1521, "matches_played": 8}
}
```

**`Player` response (new):**
```json
{
  "id": "...",
  "phone_e164": "...",
  "username": "...",
  "display_name": "...",
  "rating": 1521,
  "rd": 282,
  "volatility": 0.06,
  "matches_played": 8
}
```

`PublicPlayer`, `LeaderboardEntry`, `RatingHistoryPoint` all drop `format`.

### Mobile app

- `Player` model: drop `ratings: List<PlayerRating>`, drop `overall: Overall`;
  add direct `rating, rd, matchesPlayed` fields. Regen freezed.
- Rating card: just `player.rating.round()`, no weighted blend.
- Share cards: simpler — no overall vs format ambiguity.
- Profile screen: no per-format display.
- Match detail rating delta: same player_id → before/after, unchanged.
- Leaderboard: same shape, just one number per player.

---

## Tasks (granular, in order)

### Task 1: Backend — add new columns + migration script
- Alembic migration 0004:
  - Add `rating`, `rd`, `volatility`, `matches_played` columns to `players`.
  - Backfill via raw SQL: `players.rating = sum(rating × matches) / sum(matches)`
    from `player_ratings`. Same for RD using min-RD pick. `matches_played`
    = sum across formats.
  - Drop `player_ratings` table.
  - Keep `rating_events.format` for now (drop in a follow-up after a few
    weeks of confidence).

**Test:** Verify all players have non-null rating after migration; compare
top-5 leaderboard before/after.

### Task 2: Backend — rewrite engine.py
- Replace `_apply_weighted` etc. with the snippet's algorithm
- Fix `*2` → `**2` in `update_doubles` (RD quadrature) and `age_rating` (phi/sigma squaring)
- Equal per-partner share in doubles (remove asymmetric split)
- Drop `length_factor`. Just `margin_factor` × the Glicko delta.

### Task 3: Backend — rewrite service.py
- Load player directly (no `_load_rating(player_id, format)`)
- Persist to `players.rating` etc.
- Write 2 (singles) or 4 (doubles) `rating_events` rows per match, all
  pointing to the same player's single rating timeline.
- `age_rd_for_inactivity` takes (session, player_id, periods) — no format.

### Task 4: Backend — update models + schemas + routers
- `Player` ORM: add the four new columns; drop the `ratings` relationship
  to `player_ratings`.
- `PlayerOut`: flatten — `rating`, `rd`, `matches_played` direct.
- `PublicPlayerOut`: same.
- `LeaderboardEntry`: drop format-related fields; query becomes a single
  `ORDER BY players.rating DESC`.
- `_compute_overall()` deleted.
- Players router: remove `OverallOut` references.
- Leaderboard router: simpler query.

### Task 5: Backend — drop preview endpoint complexity
- `/matches/{id}/preview` should still work but now returns a single delta
  per participant (the player's overall rating change).
- Same code path, just simpler.

### Task 6: Mobile — regenerate models
- Flutter `Player` model: drop `ratings`, `overall`; add direct
  `rating, rd, matchesPlayed`.
- `PublicPlayer`: same.
- `LeaderboardEntry`: drop format.
- `RatingHistoryPoint`: drop format.
- Run `build_runner build`.

### Task 7: Mobile — simplify UI
- `RatingCard`: just shows `player.rating.round()` + matches + delta. No
  per-format chips, no weighted-average explanation needed.
- `ProfileScreen` and `PlayerProfileScreen`: same simplification.
- `RatingHistoryChart`: no longer needs the per-format running-average
  logic. Just plot rating_after over time.
- Share cards:
  - `RatingShareCard`: just one big number.
  - `ResultCard`: rating delta now unambiguous.
  - `HeadToHeadCard`: unchanged (already uses W/L count, not rating).

### Task 8: Seed script
- `seed_demo_data.py`: drop format-specific seeding. Each match still
  has a format field on `Match` (for cosmetic display "Singles" / "Doubles"),
  but rating updates flow to the single per-player rating.

### Task 9: Smoke test
- Wipe DB, reseed.
- Sign in on phone, log a singles + doubles match, verify rating moves on
  both, single number in UI.
- Curl `/players/by-username/karthik_r` → flat shape.
- Curl `/leaderboard` → flat shape.

### Task 10: Commit + APK rebuild
- Split into 2 commits:
  1. Backend: schema + engine + service + routes
  2. Mobile: models + UI
- Build release APK as v0.5.

---

## What stays the same

- Margin amplification (`BETA_MARGIN = 0.7`)
- `Match.format` column ("S" / "D") — still useful for cosmetic display
  ("you played a singles match"), match tile, share cards. Just doesn't
  affect rating math.
- Match validation flow (submit → opposing player confirms → engine runs)
- All other features: profiles, H2H, leaderboard, autocomplete, streak
  badges, share cards.

## What gets removed

- `Overall` model + `_compute_overall()`
- `player_ratings` table
- The per-format split everywhere in the API + UI
- Length factor in the engine
- Asymmetric doubles split (becomes equal share)

## Risks

1. **Backfill mishap on existing seeded data.** Test on Docker first; if
   the migration is wrong, nuke + reseed.
2. **The "doubles dilutes singles signal" critique we discussed earlier.**
   Players who are 1900 in singles but 1400 in doubles will average to
   ~1600 — slightly off for both contexts. Accepted as part of the
   simplification.
3. **Existing share cards in the wild.** Old APKs (v0.4) point at the
   same backend but expect the old `ratings` + `overall` JSON shape. They'll
   crash on response parsing. **Mitigation:** the change is breaking. Any
   v0.4 APK already shared needs to be replaced with v0.5. List who has
   v0.4 and rebuild for them, or expose old shape behind a query param
   `?v=1` (uglier).

## Estimated time

- Backend (tasks 1–5): ~45 min
- Mobile (tasks 6–7): ~45 min
- Seed + smoke (8–9): ~20 min
- Commit + APK (10): ~15 min

Total: ~2 hours.
