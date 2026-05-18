"""Seed the prod DB with realistic demo data.

What it does:
1. Creates 14 fake Bangalore players via the real /players API.
2. Has them play 60 matches against each other AND against the existing user.
3. Matches are submitted + confirmed via the real flow, so ratings update
   through the actual Glicko-2 + margin/length engine.
4. Leaves a few matches in "pending" state so the home screen has things
   awaiting confirmation for the real user.

Idempotent-ish: re-running will fail player creation for already-existing
phone numbers, then continue with match submission. To start fresh, run:
    delete from match_invites; delete from match_games;
    delete from match_participants; delete from rating_events;
    delete from matches; delete from player_ratings where player_id != '<your-id>';
    delete from players where firebase_uid != '<your-firebase-uid>';

Usage:
    cd backend
    REAL_USER_PHONE=+918059976498 \\
    API_BASE=https://rally-api-24880069901.asia-south1.run.app \\
    python seed_demo_data.py
"""
import os
import random
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

import httpx

API_BASE = os.environ.get(
    "API_BASE", "https://rally-api-24880069901.asia-south1.run.app"
)
REAL_USER_PHONE = os.environ.get("REAL_USER_PHONE", "+918059976498")

# Deterministic seed so re-runs produce the same matches.
random.seed(42)


@dataclass
class FakePlayer:
    name: str
    username: str
    phone: str
    gender: str
    # "tier" is just for picking who wins more often. Not stored anywhere.
    tier: int  # 1=beginner ... 4=competitive


# 14 plausible Bangalore badminton-club names, distributed across 4 skill tiers.
FAKE_PLAYERS = [
    FakePlayer("Asha Iyer", "asha_i", "+919900100101", "F", 3),
    FakePlayer("Rohan Kulkarni", "rohan_k", "+919900100102", "M", 4),
    FakePlayer("Meera Nair", "meera_n", "+919900100103", "F", 2),
    FakePlayer("Karthik Reddy", "karthik_r", "+919900100104", "M", 3),
    FakePlayer("Sneha Bhat", "sneha_b", "+919900100105", "F", 4),
    FakePlayer("Arjun Menon", "arjun_m", "+919900100106", "M", 2),
    FakePlayer("Priya Sharma", "priya_s", "+919900100107", "F", 3),
    FakePlayer("Vikram Rao", "vikram_r", "+919900100108", "M", 4),
    FakePlayer("Divya Krishnan", "divya_k", "+919900100109", "F", 2),
    FakePlayer("Anand Pillai", "anand_p", "+919900100110", "M", 3),
    FakePlayer("Lakshmi Gowda", "lakshmi_g", "+919900100111", "F", 1),
    FakePlayer("Suresh Hegde", "suresh_h", "+919900100112", "M", 2),
    FakePlayer("Neha Joshi", "neha_j", "+919900100113", "F", 3),
    FakePlayer("Aditya Shetty", "aditya_s", "+919900100114", "M", 4),
]


def dev_token(phone: str) -> str:
    """Mirrors backend/app/auth/dev_token logic from the Flutter side."""
    h = 7
    for c in phone.encode():
        h = (h * 31 + c) & 0x7FFFFFFF
    uid = f"u-{h:x}"
    return f"dev:{uid}:{phone}"


def auth_for(phone: str) -> dict:
    return {"Authorization": f"Bearer {dev_token(phone)}"}


def realistic_score(winner_tier: int, loser_tier: int) -> tuple[int, int]:
    """Return (winner, loser) scores reflecting the tier gap.

    Bigger tier gap → more lopsided score. Equal tiers → close games.
    """
    gap = winner_tier - loser_tier
    if gap <= -1:
        # Upset! The lower-tier player won. Should be close.
        return (21, random.randint(17, 20))
    if gap == 0:
        # Same tier. 60% close game, 40% comfortable win.
        if random.random() < 0.6:
            return (21, random.randint(15, 19))
        return (21, random.randint(10, 14))
    if gap == 1:
        return (21, random.randint(13, 18))
    if gap == 2:
        return (21, random.randint(8, 14))
    # gap >= 3, blowout
    return (21, random.randint(3, 10))


def pick_winner_by_tier(p1: FakePlayer, p2: FakePlayer) -> tuple[FakePlayer, FakePlayer]:
    """Higher-tier wins more often, but ~25% upset rate per tier gap."""
    if p1.tier == p2.tier:
        winner = random.choice([p1, p2])
    else:
        # P(higher wins) = 0.5 + 0.15 * gap, capped at 0.95.
        gap = abs(p1.tier - p2.tier)
        p_higher_wins = min(0.95, 0.5 + 0.15 * gap)
        higher, lower = (p1, p2) if p1.tier > p2.tier else (p2, p1)
        winner = higher if random.random() < p_higher_wins else lower

    loser = p1 if winner is p2 else p2
    return winner, loser


def signup_player(client: httpx.Client, fp: FakePlayer) -> bool:
    """Create a player. Returns True on success or already-exists."""
    r = client.post(
        "/players",
        json={
            "username": fp.username,
            "display_name": fp.name,
            "gender": fp.gender,
            "home_city": "BLR",
        },
        headers=auth_for(fp.phone),
    )
    if r.status_code == 201:
        print(f"  + signed up {fp.name}")
        return True
    if r.status_code == 409:
        print(f"  · {fp.name} already exists")
        return True
    print(f"  ! {fp.name} failed ({r.status_code}): {r.text[:200]}")
    return False


def submit_singles(
    client: httpx.Client,
    submitter: FakePlayer,
    opponent: FakePlayer,
    winner_score: int,
    loser_score: int,
    submitter_won: bool,
    played_at: datetime,
) -> str | None:
    """Returns match_id on success."""
    sub_pts = winner_score if submitter_won else loser_score
    opp_pts = loser_score if submitter_won else winner_score
    r = client.post(
        "/matches",
        json={
            "format": "S",
            "played_at": played_at.isoformat(),
            "venue": "Padukone-Dravid Centre",
            "team1_phones": [submitter.phone],
            "team2_phones": [opponent.phone],
            "games": [{"game_no": 1, "team1_points": sub_pts, "team2_points": opp_pts}],
        },
        headers=auth_for(submitter.phone),
    )
    if r.status_code != 201:
        print(f"  ! submit failed ({r.status_code}): {r.text[:200]}")
        return None
    return r.json()["id"]


def submit_doubles(
    client: httpx.Client,
    submitter: FakePlayer,
    teammate: FakePlayer,
    opp1: FakePlayer,
    opp2: FakePlayer,
    winner_score: int,
    loser_score: int,
    submitter_team_won: bool,
    played_at: datetime,
) -> str | None:
    sub_pts = winner_score if submitter_team_won else loser_score
    opp_pts = loser_score if submitter_team_won else winner_score
    r = client.post(
        "/matches",
        json={
            "format": "D",
            "played_at": played_at.isoformat(),
            "venue": "Indiranagar Club",
            "team1_phones": [submitter.phone, teammate.phone],
            "team2_phones": [opp1.phone, opp2.phone],
            "games": [{"game_no": 1, "team1_points": sub_pts, "team2_points": opp_pts}],
        },
        headers=auth_for(submitter.phone),
    )
    if r.status_code != 201:
        print(f"  ! doubles submit failed ({r.status_code}): {r.text[:200]}")
        return None
    return r.json()["id"]


def confirm_match(client: httpx.Client, match_id: str, confirmer: FakePlayer) -> bool:
    r = client.post(f"/matches/{match_id}/confirm", headers=auth_for(confirmer.phone))
    return r.status_code == 200


def main() -> None:
    # Real user, with their tier set so matches against them are realistic.
    real_user = FakePlayer("David Garg", "david", REAL_USER_PHONE, "M", 3)

    with httpx.Client(base_url=API_BASE, timeout=15.0) as client:
        print(f"\n→ API: {API_BASE}")
        print(f"→ Real user: {REAL_USER_PHONE}\n")

        print("Signing up fake players...")
        for fp in FAKE_PLAYERS:
            if not signup_player(client, fp):
                sys.exit(1)
            time.sleep(0.05)

        # Pool of everyone available for matches, including the real user.
        all_players = [real_user, *FAKE_PLAYERS]

        # === Round 1: 35 singles matches, all confirmed ===
        # Spread played_at over the last 30 days for a believable history.
        print("\nSubmitting 35 confirmed singles matches...")
        now = datetime.now(timezone.utc)
        for i in range(35):
            p1, p2 = random.sample(all_players, 2)
            winner, loser = pick_winner_by_tier(p1, p2)
            w_score, l_score = realistic_score(winner.tier, loser.tier)
            submitter = winner if random.random() < 0.7 else loser
            submitter_won = submitter is winner
            opponent = loser if submitter is winner else winner
            played_at = now - timedelta(
                days=random.randint(1, 30),
                hours=random.randint(0, 23),
            )
            mid = submit_singles(
                client, submitter, opponent, w_score, l_score, submitter_won, played_at
            )
            if not mid:
                continue
            # Opponent confirms.
            if confirm_match(client, mid, opponent):
                print(
                    f"  ✓ {winner.name} d. {loser.name} {w_score}-{l_score} "
                    f"({played_at.strftime('%b %d')})"
                )
            else:
                print(f"  ! confirm failed for {mid}")
            time.sleep(0.05)

        # === Round 2: 20 confirmed doubles matches ===
        print("\nSubmitting 20 confirmed doubles matches...")
        for i in range(20):
            four = random.sample(all_players, 4)
            t1, t2 = (four[0], four[1]), (four[2], four[3])
            t1_avg = (t1[0].tier + t1[1].tier) / 2
            t2_avg = (t2[0].tier + t2[1].tier) / 2
            # Probability team 1 wins, given tier averages.
            if t1_avg == t2_avg:
                t1_wins = random.random() < 0.5
            else:
                gap = t1_avg - t2_avg
                p_t1 = min(0.92, max(0.08, 0.5 + 0.18 * gap))
                t1_wins = random.random() < p_t1
            winner_tier = max(t1_avg, t2_avg) if t1_wins == (t1_avg >= t2_avg) else min(t1_avg, t2_avg)
            loser_tier = min(t1_avg, t2_avg) if t1_wins == (t1_avg >= t2_avg) else max(t1_avg, t2_avg)
            w_score, l_score = realistic_score(int(winner_tier), int(loser_tier))
            submitter = t1[0]
            submitter_team_won = t1_wins
            played_at = now - timedelta(
                days=random.randint(1, 30),
                hours=random.randint(0, 23),
            )
            mid = submit_doubles(
                client, submitter, t1[1], t2[0], t2[1],
                w_score, l_score, submitter_team_won, played_at,
            )
            if not mid:
                continue
            # An opposing player confirms.
            confirmer = random.choice([t2[0], t2[1]])
            if confirm_match(client, mid, confirmer):
                print(
                    f"  ✓ {t1[0].name}/{t1[1].name} vs {t2[0].name}/{t2[1].name} "
                    f"{w_score}-{l_score}"
                )
            time.sleep(0.05)

        # === Round 3: 5 pending matches AGAINST the real user ===
        # These need real-user confirmation. They show up on home screen.
        print("\nSubmitting 5 PENDING matches against the real user...")
        opponents = random.sample(FAKE_PLAYERS, 5)
        for opp in opponents:
            winner, loser = pick_winner_by_tier(opp, real_user)
            w_score, l_score = realistic_score(winner.tier, loser.tier)
            # opp is the submitter so the match is pending on real user's side.
            played_at = now - timedelta(hours=random.randint(1, 36))
            opp_won = winner is opp
            mid = submit_singles(
                client, opp, real_user, w_score, l_score, opp_won, played_at
            )
            if mid:
                print(f"  ⏳ {opp.name} -> awaiting your confirmation")
            time.sleep(0.05)

        print("\n✅ Seed complete.")


if __name__ == "__main__":
    main()
