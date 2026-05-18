from datetime import UTC, datetime
from fastapi import APIRouter, Header, HTTPException, status
from sqlalchemy import select

from app.config import settings
from app.db.models import Match
from app.deps import DbSession
from app.matches import service
from app.matches.validators import match_winner
from app.rating.service import apply_match_rating
from app.push import fcm

router = APIRouter(prefix="/internal", tags=["internal"])


@router.post("/expire-matches")
async def expire_matches(
    session: DbSession,
    x_internal_secret: str | None = Header(default=None, alias="X-Internal-Secret"),
) -> dict[str, int]:
    if x_internal_secret != settings.internal_secret:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "bad internal secret")

    now = datetime.now(UTC)
    res = await session.execute(
        select(Match).where(
            (Match.status == "pending") & (Match.validation_deadline < now)
        )
    )
    matches = list(res.scalars().all())
    validated = 0
    for m in matches:
        games_rows = await service.load_games(session, m.id)
        try:
            winning_team = match_winner(
                [(g.team1_points, g.team2_points) for g in games_rows]
            )
        except ValueError:
            continue
        m.status = "validated"
        m.validated_at = now
        await apply_match_rating(session, m, winning_team)
        validated += 1
        parts = await service.load_participants(session, m.id)
        for _mp, p in parts:
            await fcm.send_to_uid(
                p.firebase_uid,
                title="Match auto-validated",
                body="No dispute received in 72 hours. Rating updated.",
                data={"match_id": str(m.id), "kind": "match_auto_validated"},
            )
    await session.commit()
    return {"validated": validated, "considered": len(matches)}
