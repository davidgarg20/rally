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
