from __future__ import annotations
import hashlib
import uuid
from datetime import datetime, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Match, MatchParticipant, Player


def normalize_phones(phones: list[str]) -> tuple[str, ...]:
    return tuple(sorted(p.strip() for p in phones))


def dedup_signature(submitter_id: uuid.UUID, played_at: datetime,
                    all_phones: list[str]) -> str:
    norm = normalize_phones(all_phones)
    raw = f"{submitter_id}|{played_at.isoformat()}|{'|'.join(norm)}"
    return hashlib.sha256(raw.encode()).hexdigest()


async def find_duplicate(
    session: AsyncSession,
    submitter_id: uuid.UUID,
    played_at: datetime,
    all_phones: list[str],
    window: timedelta = timedelta(minutes=15),
) -> Match | None:
    norm_target = normalize_phones(all_phones)
    res = await session.execute(
        select(Match).where(
            (Match.submitted_by == submitter_id)
            & (Match.played_at >= played_at - window)
            & (Match.played_at <= played_at + window)
            & (Match.status.in_(("pending", "validated")))
        )
    )
    candidates = list(res.scalars().all())
    for c in candidates:
        parts = (await session.execute(
            select(Player.phone_e164)
            .join(MatchParticipant, MatchParticipant.player_id == Player.id)
            .where(MatchParticipant.match_id == c.id)
        )).scalars().all()
        if normalize_phones(list(parts)) == tuple(p for p in norm_target if p in parts):
            return c
    return None
