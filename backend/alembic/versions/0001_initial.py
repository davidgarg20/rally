"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-05-18
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "players",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("phone_e164", sa.String(), nullable=False, unique=True),
        sa.Column("display_name", sa.String(), nullable=False),
        sa.Column("gender", sa.String(), nullable=True),
        sa.Column("dob", sa.Date(), nullable=True),
        sa.Column("home_city", sa.String(), nullable=False, server_default="BLR"),
        sa.Column("firebase_uid", sa.String(), nullable=False, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("gender in ('M','F','O') or gender is null", name="player_gender_chk"),
    )

    op.create_table(
        "player_ratings",
        sa.Column("player_id", UUID(as_uuid=True), sa.ForeignKey("players.id"), primary_key=True),
        sa.Column("format", sa.String(), primary_key=True),
        sa.Column("rating", sa.Double(), nullable=False, server_default="3.5"),
        sa.Column("rd", sa.Double(), nullable=False, server_default="1.2"),
        sa.Column("volatility", sa.Double(), nullable=False, server_default="0.06"),
        sa.Column("matches_played", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("format in ('S','D')", name="player_rating_format_chk"),
    )

    op.create_table(
        "matches",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("format", sa.String(), nullable=False),
        sa.Column("played_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("venue", sa.String(), nullable=True),
        sa.Column("submitted_by", UUID(as_uuid=True), sa.ForeignKey("players.id"), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("validation_deadline", sa.DateTime(timezone=True), nullable=False),
        sa.Column("validated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("format in ('S','D')", name="match_format_chk"),
        sa.CheckConstraint(
            "status in ('pending','validated','disputed','expired')",
            name="match_status_chk",
        ),
    )

    op.create_table(
        "match_participants",
        sa.Column("match_id", UUID(as_uuid=True), sa.ForeignKey("matches.id"), primary_key=True),
        sa.Column("player_id", UUID(as_uuid=True), sa.ForeignKey("players.id"), primary_key=True),
        sa.Column("team", sa.Integer(), nullable=False),
        sa.Column("is_submitter", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("confirmed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("disputed_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("team in (1,2)", name="participant_team_chk"),
    )

    op.create_table(
        "match_games",
        sa.Column("match_id", UUID(as_uuid=True), sa.ForeignKey("matches.id"), primary_key=True),
        sa.Column("game_no", sa.Integer(), primary_key=True),
        sa.Column("team1_points", sa.Integer(), nullable=False),
        sa.Column("team2_points", sa.Integer(), nullable=False),
        sa.CheckConstraint("game_no between 1 and 5", name="game_no_chk"),
    )

    op.create_table(
        "rating_events",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("player_id", UUID(as_uuid=True), sa.ForeignKey("players.id"), nullable=False),
        sa.Column("match_id", UUID(as_uuid=True), sa.ForeignKey("matches.id"), nullable=False),
        sa.Column("format", sa.String(), nullable=False),
        sa.Column("rating_before", sa.Double(), nullable=False),
        sa.Column("rating_after", sa.Double(), nullable=False),
        sa.Column("rd_before", sa.Double(), nullable=False),
        sa.Column("rd_after", sa.Double(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "match_invites",
        sa.Column("match_id", UUID(as_uuid=True), sa.ForeignKey("matches.id"), primary_key=True),
        sa.Column("phone_e164", sa.String(), primary_key=True),
        sa.Column("team", sa.Integer(), nullable=False),
        sa.Column("invited_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("team in (1,2)", name="invite_team_chk"),
    )

    op.create_index(
        "ix_matches_pending_deadline",
        "matches",
        ["validation_deadline"],
        postgresql_where=sa.text("status = 'pending'"),
    )
    op.create_index(
        "ix_rating_events_player_created",
        "rating_events",
        ["player_id", sa.text("created_at desc")],
    )
    op.create_index(
        "ix_match_participants_player",
        "match_participants",
        ["player_id", "match_id"],
    )
    op.create_index("ix_match_invites_phone", "match_invites", ["phone_e164"])
    op.create_index(
        "ix_player_ratings_format_rating",
        "player_ratings",
        ["format", sa.text("rating desc")],
    )


def downgrade() -> None:
    for tbl in [
        "match_invites", "rating_events", "match_games", "match_participants",
        "matches", "player_ratings", "players",
    ]:
        op.drop_table(tbl)
