"""add player challenges

Revision ID: 0006
Revises: 0005
Create Date: 2026-08-17
"""

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

from alembic import op

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "challenges",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "challenger_id",
            UUID(as_uuid=True),
            sa.ForeignKey("players.id"),
            nullable=False,
        ),
        sa.Column(
            "challenged_id",
            UUID(as_uuid=True),
            sa.ForeignKey("players.id"),
            nullable=False,
        ),
        sa.Column("status", sa.String(), nullable=False, server_default="pending"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint(
            "challenger_id <> challenged_id",
            name="challenge_players_differ_chk",
        ),
        sa.CheckConstraint(
            "status in ('pending','accepted','declined','cancelled')",
            name="challenge_status_chk",
        ),
    )
    op.create_index(
        "ix_challenges_challenger_created",
        "challenges",
        ["challenger_id", "created_at"],
    )
    op.create_index(
        "ix_challenges_challenged_created",
        "challenges",
        ["challenged_id", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_challenges_challenged_created", table_name="challenges")
    op.drop_index("ix_challenges_challenger_created", table_name="challenges")
    op.drop_table("challenges")
