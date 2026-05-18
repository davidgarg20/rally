"""switch ratings to Glicko-native scale (1500/350) and reset existing rows

Revision ID: 0002
Revises: 0001
Create Date: 2026-05-19
"""
from alembic import op
import sqlalchemy as sa

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # New defaults
    op.alter_column(
        "player_ratings", "rating",
        server_default=sa.text("1500"), existing_type=sa.Double(),
    )
    op.alter_column(
        "player_ratings", "rd",
        server_default=sa.text("350"), existing_type=sa.Double(),
    )
    # Reset existing rows — we have no real users yet.
    op.execute("update player_ratings set rating = 1500, rd = 350, volatility = 0.06")
    # Wipe rating_events because the deltas are on the old (1.0–7.0) scale
    # and meaningless now. Same reason: no real data to preserve.
    op.execute("delete from rating_events")
    # Reset matches_played so leaderboards aren't polluted by stale counters.
    op.execute("update player_ratings set matches_played = 0")


def downgrade() -> None:
    op.alter_column(
        "player_ratings", "rating",
        server_default=sa.text("3.5"), existing_type=sa.Double(),
    )
    op.alter_column(
        "player_ratings", "rd",
        server_default=sa.text("1.2"), existing_type=sa.Double(),
    )
