"""single rating per player: drop player_ratings, add rating/rd/vol/matches to players

Revision ID: 0004
Revises: 0003
Create Date: 2026-05-19
"""
from alembic import op
import sqlalchemy as sa


revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add new columns to players. server_default lets existing rows
    # (if any) take the cold-start values; matches_played starts at 0.
    op.add_column(
        "players",
        sa.Column("rating", sa.Double(), nullable=False, server_default="1500"),
    )
    op.add_column(
        "players",
        sa.Column("rd", sa.Double(), nullable=False, server_default="350"),
    )
    op.add_column(
        "players",
        sa.Column("volatility", sa.Double(), nullable=False, server_default="0.06"),
    )
    op.add_column(
        "players",
        sa.Column("matches_played", sa.Integer(), nullable=False, server_default="0"),
    )

    # Backfill from player_ratings: match-count-weighted overall rating;
    # pick the lower (more confident) RD across formats; sum matches.
    op.execute(
        """
        update players p set
            rating = coalesce(sub.weighted, 1500),
            rd = coalesce(sub.min_rd, 350),
            volatility = coalesce(sub.avg_vol, 0.06),
            matches_played = coalesce(sub.total_matches, 0)
        from (
            select pr.player_id,
                   sum(pr.rating * pr.matches_played)
                     / nullif(sum(pr.matches_played), 0) as weighted,
                   min(pr.rd) as min_rd,
                   avg(pr.volatility) as avg_vol,
                   sum(pr.matches_played) as total_matches
            from player_ratings pr
            group by pr.player_id
        ) sub
        where p.id = sub.player_id
        """
    )

    # Drop the old per-format table.
    op.drop_table("player_ratings")


def downgrade() -> None:
    # Recreate player_ratings with a single row at the per-player rating,
    # treating it as "singles" (arbitrary). Lossy — the per-format split
    # is gone once this migration ran.
    op.create_table(
        "player_ratings",
        sa.Column("player_id", sa.UUID(as_uuid=True), sa.ForeignKey("players.id"),
                  primary_key=True),
        sa.Column("format", sa.String(), primary_key=True),
        sa.Column("rating", sa.Double(), nullable=False, server_default="1500"),
        sa.Column("rd", sa.Double(), nullable=False, server_default="350"),
        sa.Column("volatility", sa.Double(), nullable=False, server_default="0.06"),
        sa.Column("matches_played", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("format in ('S','D')", name="player_rating_format_chk"),
    )
    op.execute(
        """
        insert into player_ratings (player_id, format, rating, rd, volatility, matches_played)
        select id, 'S', rating, rd, volatility, matches_played from players
        """
    )
    for col in ("matches_played", "volatility", "rd", "rating"):
        op.drop_column("players", col)
