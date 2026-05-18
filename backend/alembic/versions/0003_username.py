"""add username column to players

Revision ID: 0003
Revises: 0002
Create Date: 2026-05-19
"""
from alembic import op
import sqlalchemy as sa

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add nullable first, backfill, then add NOT NULL + UNIQUE.
    op.add_column("players", sa.Column("username", sa.String(), nullable=True))
    # Backfill: derive a temp username from firebase_uid suffix for any existing rows.
    # We don't have rows in prod, but this keeps the migration idempotent.
    op.execute(
        "update players set username = 'u_' || substr(replace(firebase_uid, '-', ''), 1, 16) "
        "where username is null"
    )
    op.alter_column("players", "username", nullable=False)
    op.create_unique_constraint("players_username_key", "players", ["username"])
    op.create_check_constraint(
        "player_username_format_chk",
        "players",
        "username ~ '^[a-z][a-z0-9_]{2,19}$'",
    )


def downgrade() -> None:
    op.drop_constraint("player_username_format_chk", "players", type_="check")
    op.drop_constraint("players_username_key", "players", type_="unique")
    op.drop_column("players", "username")
