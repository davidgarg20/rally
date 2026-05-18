import uuid
from datetime import date, datetime
from sqlalchemy import (
    CheckConstraint, Date, DateTime, Double, ForeignKey, Integer, String,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.db.base import Base

class Player(Base):
    __tablename__ = "players"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    phone_e164: Mapped[str] = mapped_column(String, unique=True, nullable=False)
    display_name: Mapped[str] = mapped_column(String, nullable=False)
    gender: Mapped[str | None] = mapped_column(String, nullable=True)
    dob: Mapped[date | None] = mapped_column(Date, nullable=True)
    home_city: Mapped[str] = mapped_column(String, nullable=False, default="BLR")
    firebase_uid: Mapped[str] = mapped_column(String, unique=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        CheckConstraint("gender in ('M','F','O') or gender is null", name="player_gender_chk"),
    )

    ratings: Mapped[list["PlayerRating"]] = relationship(back_populates="player")


class PlayerRating(Base):
    __tablename__ = "player_ratings"

    player_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("players.id"), primary_key=True
    )
    format: Mapped[str] = mapped_column(String, primary_key=True)
    rating: Mapped[float] = mapped_column(Double, nullable=False, default=3.5)
    rd: Mapped[float] = mapped_column(Double, nullable=False, default=1.2)
    volatility: Mapped[float] = mapped_column(Double, nullable=False, default=0.06)
    matches_played: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(),
        onupdate=func.now(), nullable=False,
    )

    __table_args__ = (
        CheckConstraint("format in ('S','D')", name="player_rating_format_chk"),
    )

    player: Mapped[Player] = relationship(back_populates="ratings")


class Match(Base):
    __tablename__ = "matches"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    format: Mapped[str] = mapped_column(String, nullable=False)
    played_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    venue: Mapped[str | None] = mapped_column(String, nullable=True)
    submitted_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("players.id"), nullable=False
    )
    status: Mapped[str] = mapped_column(String, nullable=False)
    validation_deadline: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    validated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        CheckConstraint("format in ('S','D')", name="match_format_chk"),
        CheckConstraint(
            "status in ('pending','validated','disputed','expired')",
            name="match_status_chk",
        ),
    )


class MatchParticipant(Base):
    __tablename__ = "match_participants"

    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("matches.id"), primary_key=True
    )
    player_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("players.id"), primary_key=True
    )
    team: Mapped[int] = mapped_column(Integer, nullable=False)
    is_submitter: Mapped[bool] = mapped_column(nullable=False, default=False)
    confirmed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    disputed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    __table_args__ = (
        CheckConstraint("team in (1,2)", name="participant_team_chk"),
    )


class MatchGame(Base):
    __tablename__ = "match_games"

    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("matches.id"), primary_key=True
    )
    game_no: Mapped[int] = mapped_column(Integer, primary_key=True)
    team1_points: Mapped[int] = mapped_column(Integer, nullable=False)
    team2_points: Mapped[int] = mapped_column(Integer, nullable=False)

    __table_args__ = (
        CheckConstraint("game_no between 1 and 5", name="game_no_chk"),
    )


class RatingEvent(Base):
    __tablename__ = "rating_events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    player_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("players.id"), nullable=False
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("matches.id"), nullable=False
    )
    format: Mapped[str] = mapped_column(String, nullable=False)
    rating_before: Mapped[float] = mapped_column(Double, nullable=False)
    rating_after: Mapped[float] = mapped_column(Double, nullable=False)
    rd_before: Mapped[float] = mapped_column(Double, nullable=False)
    rd_after: Mapped[float] = mapped_column(Double, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class MatchInvite(Base):
    __tablename__ = "match_invites"

    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("matches.id"), primary_key=True
    )
    phone_e164: Mapped[str] = mapped_column(String, primary_key=True)
    team: Mapped[int] = mapped_column(Integer, nullable=False)
    invited_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        CheckConstraint("team in (1,2)", name="invite_team_chk"),
    )
