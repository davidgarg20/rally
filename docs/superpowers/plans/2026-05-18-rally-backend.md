# Rally Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a fully tested FastAPI backend for Rally MVP — phone-OTP auth, match submission, opponent validation, Glicko-2 rating engine (singles + doubles), Bangalore city leaderboard. Backend must be runnable locally end-to-end via docker-compose and pass an integration test suite before Plan 2 (Flutter) or Plan 3 (deploy) start.

**Architecture:** Stateless FastAPI service backed by Postgres 16. Firebase Admin SDK verifies ID tokens. FCM push sent server-side via firebase-admin. Glicko-2 lives in a pure-Python module, called synchronously inside validation transactions. No Redis, no queues, no microservices in MVP.

**Tech Stack:** Python 3.12, FastAPI, SQLAlchemy 2.x (async), Alembic, asyncpg, Pydantic v2, firebase-admin, glicko2 (or roll our own), pytest + pytest-asyncio + testcontainers, ruff, mypy. Docker + docker-compose for local dev.

**Repository layout:**

```
backend/
  app/
    __init__.py
    main.py                  -- FastAPI app factory + router mounting
    config.py                -- pydantic-settings, env-driven
    deps.py                  -- shared FastAPI dependencies (db, current_user)
    db/
      __init__.py
      base.py                -- SQLAlchemy Base + engine + session
      models.py              -- ORM models
    auth/
      firebase.py            -- Firebase Admin init + token verification
    rating/
      glicko2.py             -- Pure-Python Glicko-2 (no DB deps)
      doubles.py             -- Carry-weight scaler for doubles
    matches/
      schemas.py             -- Pydantic request/response models
      service.py             -- Submit / confirm / dispute / expire logic
      router.py              -- /matches endpoints
      validators.py          -- Score sanity, dedup, participant rules
    players/
      schemas.py
      service.py
      router.py              -- /players endpoints
    leaderboard/
      service.py
      router.py              -- /leaderboard endpoint
    push/
      fcm.py                 -- FCM send wrapper
    internal/
      router.py              -- /internal/expire-matches
    errors.py                -- Error codes + exception handlers
  alembic/
    env.py
    versions/
  tests/
    conftest.py              -- testcontainers Postgres fixture + app client
    unit/
      test_glicko2.py
      test_doubles_scaler.py
      test_validators.py
    integration/
      test_players.py
      test_matches_submit.py
      test_matches_confirm.py
      test_matches_dispute.py
      test_matches_expire.py
      test_leaderboard.py
  pyproject.toml
  Dockerfile
  docker-compose.yml
  .env.example
  Makefile
  README.md
```

**Conventions across the plan:**

- Every code change starts with a failing test, then minimal implementation, then commit.
- All times stored UTC (`timestamptz`). API returns ISO-8601 with `Z`.
- All money/rating values use `float` (double precision) at the DB; Glicko-2 doesn't need decimal precision.
- All endpoints except `/healthz` and `/internal/*` require a Firebase ID token via `Authorization: Bearer <jwt>`.
- `/internal/*` is authed by a single shared secret in header `X-Internal-Secret`.
- Run tests via `make test` (defined in Task 2). It runs `pytest -x --tb=short`.

---

## Task 1: Bootstrap repo, tooling, and CI-ready scaffolding

**Files:**
- Create: `backend/pyproject.toml`
- Create: `backend/.gitignore`
- Create: `backend/.env.example`
- Create: `backend/Makefile`
- Create: `backend/README.md`

- [ ] **Step 1: Create `backend/pyproject.toml`**

```toml
[project]
name = "rally-backend"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
  "fastapi==0.115.0",
  "uvicorn[standard]==0.32.0",
  "pydantic==2.9.2",
  "pydantic-settings==2.6.0",
  "sqlalchemy[asyncio]==2.0.35",
  "asyncpg==0.30.0",
  "alembic==1.13.3",
  "firebase-admin==6.5.0",
  "httpx==0.27.2",
  "python-dateutil==2.9.0",
]

[project.optional-dependencies]
dev = [
  "pytest==8.3.3",
  "pytest-asyncio==0.24.0",
  "testcontainers[postgres]==4.8.2",
  "ruff==0.6.9",
  "mypy==1.11.2",
  "types-python-dateutil",
]

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP", "SIM", "RUF"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]

[tool.mypy]
python_version = "3.12"
strict = true
plugins = ["pydantic.mypy"]
```

- [ ] **Step 2: Create `backend/.gitignore`**

```
__pycache__/
*.pyc
.venv/
.env
.pytest_cache/
.mypy_cache/
.ruff_cache/
*.egg-info/
dist/
build/
```

- [ ] **Step 3: Create `backend/.env.example`**

```
DATABASE_URL=postgresql+asyncpg://rally:rally@localhost:5432/rally
FIREBASE_CREDENTIALS_PATH=./firebase-service-account.json
INTERNAL_SECRET=dev-internal-secret-change-me
ENV=dev
LOG_LEVEL=INFO
```

- [ ] **Step 4: Create `backend/Makefile`**

```makefile
.PHONY: install fmt lint type test test-unit test-int run migrate

install:
	uv pip install -e ".[dev]"

fmt:
	ruff format app tests
	ruff check --fix app tests

lint:
	ruff check app tests

type:
	mypy app

test:
	pytest -x --tb=short

test-unit:
	pytest tests/unit -x --tb=short

test-int:
	pytest tests/integration -x --tb=short

run:
	uvicorn app.main:app --reload --port 8000

migrate:
	alembic upgrade head
```

- [ ] **Step 5: Create `backend/README.md`**

```markdown
# Rally Backend

FastAPI service for the Rally badminton-rating MVP.

## Quickstart

```bash
cd backend
uv venv && source .venv/bin/activate
make install
cp .env.example .env
docker compose up -d postgres
make migrate
make run
```

## Tests

`make test` runs unit + integration. Integration tests spin up an ephemeral
Postgres via testcontainers — Docker must be running.
```

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat(backend): bootstrap project scaffolding"
```

---

## Task 2: Settings and app factory

**Files:**
- Create: `backend/app/__init__.py` (empty)
- Create: `backend/app/config.py`
- Create: `backend/app/main.py`
- Create: `backend/tests/__init__.py` (empty)
- Create: `backend/tests/unit/__init__.py` (empty)
- Create: `backend/tests/unit/test_healthz.py`

- [ ] **Step 1: Write the failing test `tests/unit/test_healthz.py`**

```python
from httpx import ASGITransport, AsyncClient
from app.main import create_app

async def test_healthz_returns_ok():
    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        resp = await ac.get("/healthz")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}
```

- [ ] **Step 2: Run test, expect ImportError**

Run: `pytest tests/unit/test_healthz.py -v`
Expected: FAIL — module `app.main` not found.

- [ ] **Step 3: Implement `app/config.py`**

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://rally:rally@localhost:5432/rally"
    firebase_credentials_path: str | None = None
    internal_secret: str = "dev-internal-secret-change-me"
    env: str = "dev"
    log_level: str = "INFO"

settings = Settings()
```

- [ ] **Step 4: Implement `app/main.py`**

```python
from fastapi import FastAPI

def create_app() -> FastAPI:
    app = FastAPI(title="Rally API", version="0.1.0")

    @app.get("/healthz")
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    return app

app = create_app()
```

- [ ] **Step 5: Run test, expect PASS**

Run: `pytest tests/unit/test_healthz.py -v`
Expected: 1 passed.

- [ ] **Step 6: Commit**

```bash
git add backend/app/ backend/tests/
git commit -m "feat(backend): app factory + healthz endpoint"
```

---

## Task 3: Local Postgres via docker-compose

**Files:**
- Create: `backend/docker-compose.yml`

- [ ] **Step 1: Create `backend/docker-compose.yml`**

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: rally
      POSTGRES_PASSWORD: rally
      POSTGRES_DB: rally
    ports:
      - "5432:5432"
    volumes:
      - rally_pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U rally -d rally"]
      interval: 2s
      timeout: 5s
      retries: 10

volumes:
  rally_pg:
```

- [ ] **Step 2: Verify Postgres starts**

Run: `cd backend && docker compose up -d postgres && docker compose ps`
Expected: postgres container running, healthy.

- [ ] **Step 3: Commit**

```bash
git add backend/docker-compose.yml
git commit -m "chore(backend): add postgres docker-compose"
```

---

## Task 4: SQLAlchemy base + engine + session

**Files:**
- Create: `backend/app/db/__init__.py` (empty)
- Create: `backend/app/db/base.py`
- Create: `backend/app/deps.py`
- Create: `backend/tests/conftest.py`
- Create: `backend/tests/integration/__init__.py` (empty)
- Create: `backend/tests/integration/test_db_session.py`

- [ ] **Step 1: Create `app/db/base.py`**

```python
from collections.abc import AsyncIterator
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

class Base(DeclarativeBase):
    pass

engine = create_async_engine(settings.database_url, pool_pre_ping=True, future=True)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

async def get_session() -> AsyncIterator[AsyncSession]:
    async with SessionLocal() as session:
        yield session
```

- [ ] **Step 2: Create `app/deps.py`**

```python
from collections.abc import AsyncIterator
from typing import Annotated
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import get_session

DbSession = Annotated[AsyncSession, Depends(get_session)]
```

- [ ] **Step 3: Create `tests/conftest.py`**

```python
import os
from collections.abc import AsyncIterator
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="session")
def postgres_container() -> AsyncIterator[PostgresContainer]:
    with PostgresContainer("postgres:16", driver="asyncpg") as pg:
        os.environ["DATABASE_URL"] = pg.get_connection_url()
        yield pg

@pytest.fixture(scope="session")
async def engine(postgres_container):
    eng = create_async_engine(os.environ["DATABASE_URL"], future=True)
    yield eng
    await eng.dispose()

@pytest.fixture
async def session(engine) -> AsyncIterator[AsyncSession]:
    Session = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    async with Session() as s:
        yield s
        await s.rollback()
```

- [ ] **Step 4: Write `tests/integration/test_db_session.py`**

```python
from sqlalchemy import text

async def test_session_can_query(session):
    result = await session.execute(text("select 1"))
    assert result.scalar_one() == 1
```

- [ ] **Step 5: Run test, expect PASS**

Run: `pytest tests/integration/test_db_session.py -v`
Expected: 1 passed (testcontainers will spin up Postgres).

- [ ] **Step 6: Commit**

```bash
git add backend/app/db/ backend/app/deps.py backend/tests/
git commit -m "feat(backend): sqlalchemy session + testcontainers fixture"
```

---

## Task 5: ORM models — players + ratings

**Files:**
- Create: `backend/app/db/models.py`
- Create: `backend/tests/integration/test_models_players.py`

- [ ] **Step 1: Create `app/db/models.py` with players + player_ratings**

```python
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
```

- [ ] **Step 2: Write `tests/integration/test_models_players.py`**

```python
import uuid
from sqlalchemy import text
from app.db.base import Base
from app.db.models import Player, PlayerRating

async def test_player_round_trip(engine, session):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    player = Player(
        phone_e164="+919800000001",
        display_name="Asha",
        firebase_uid="fb-uid-001",
    )
    session.add(player)
    await session.flush()
    session.add(PlayerRating(player_id=player.id, format="S"))
    session.add(PlayerRating(player_id=player.id, format="D"))
    await session.commit()

    got = (await session.execute(
        text("select display_name from players where phone_e164=:p"),
        {"p": "+919800000001"},
    )).scalar_one()
    assert got == "Asha"
```

- [ ] **Step 3: Run test, expect PASS**

Run: `pytest tests/integration/test_models_players.py -v`
Expected: 1 passed.

- [ ] **Step 4: Commit**

```bash
git add backend/app/db/models.py backend/tests/integration/test_models_players.py
git commit -m "feat(backend): Player + PlayerRating models"
```

---

## Task 6: ORM models — matches, participants, games, rating events, invites

**Files:**
- Modify: `backend/app/db/models.py` (append)
- Create: `backend/tests/integration/test_models_matches.py`

- [ ] **Step 1: Append to `app/db/models.py`**

```python
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
```

- [ ] **Step 2: Write `tests/integration/test_models_matches.py`**

```python
import uuid
from datetime import UTC, datetime, timedelta
from app.db.base import Base
from app.db.models import Match, MatchGame, MatchParticipant, Player

async def test_match_with_participants_and_games(engine, session):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    p1 = Player(phone_e164="+919800000010", display_name="A", firebase_uid="u-10")
    p2 = Player(phone_e164="+919800000011", display_name="B", firebase_uid="u-11")
    session.add_all([p1, p2])
    await session.flush()

    now = datetime.now(UTC)
    match = Match(
        format="S",
        played_at=now,
        submitted_by=p1.id,
        status="pending",
        validation_deadline=now + timedelta(hours=72),
    )
    session.add(match)
    await session.flush()

    session.add_all([
        MatchParticipant(match_id=match.id, player_id=p1.id, team=1, is_submitter=True, confirmed_at=now),
        MatchParticipant(match_id=match.id, player_id=p2.id, team=2),
        MatchGame(match_id=match.id, game_no=1, team1_points=21, team2_points=18),
        MatchGame(match_id=match.id, game_no=2, team1_points=21, team2_points=15),
    ])
    await session.commit()
```

- [ ] **Step 3: Run test, expect PASS**

Run: `pytest tests/integration/test_models_matches.py -v`
Expected: 1 passed.

- [ ] **Step 4: Commit**

```bash
git add backend/app/db/models.py backend/tests/integration/test_models_matches.py
git commit -m "feat(backend): Match, Participant, Game, RatingEvent, Invite models"
```

---

## Task 7: Alembic baseline migration

**Files:**
- Create: `backend/alembic.ini`
- Create: `backend/alembic/env.py`
- Create: `backend/alembic/script.py.mako`
- Create: `backend/alembic/versions/0001_initial.py`

- [ ] **Step 1: Create `backend/alembic.ini`**

```ini
[alembic]
script_location = alembic
sqlalchemy.url = postgresql+asyncpg://rally:rally@localhost:5432/rally
```

- [ ] **Step 2: Create `backend/alembic/script.py.mako`**

```python
"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}
"""
from alembic import op
import sqlalchemy as sa

revision = ${repr(up_revision)}
down_revision = ${repr(down_revision)}
branch_labels = ${repr(branch_labels)}
depends_on = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
```

- [ ] **Step 3: Create `backend/alembic/env.py`**

```python
import asyncio
from logging.config import fileConfig
from alembic import context
from sqlalchemy.ext.asyncio import async_engine_from_config
from sqlalchemy import pool

from app.config import settings
from app.db.base import Base
from app.db import models  # noqa: F401 -- register models

config = context.config
config.set_main_option("sqlalchemy.url", settings.database_url)
if config.config_file_name:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online():
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


asyncio.run(run_migrations_online())
```

- [ ] **Step 4: Create `backend/alembic/versions/0001_initial.py`**

```python
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
```

- [ ] **Step 5: Run migration against local Postgres**

Run: `cd backend && docker compose up -d postgres && sleep 3 && alembic upgrade head`
Expected: `INFO [alembic.runtime.migration] Running upgrade -> 0001`.

- [ ] **Step 6: Commit**

```bash
git add backend/alembic.ini backend/alembic/
git commit -m "feat(backend): initial alembic migration"
```

---

## Task 8: Glicko-2 pure function — failing test

**Files:**
- Create: `backend/app/rating/__init__.py` (empty)
- Create: `backend/tests/unit/test_glicko2.py`

The published Glicko-2 reference example (Glickman, "Example calculation",
http://www.glicko.net/glicko/glicko2.pdf):

- Player: rating=1500, RD=200, vol=0.06.
- Three opponents:
  - r=1400, RD=30, score=1 (win)
  - r=1550, RD=100, score=0 (loss)
  - r=1700, RD=300, score=0 (loss)
- Tau = 0.5.
- Expected after update: rating ≈ 1464.06, RD ≈ 151.52, vol ≈ 0.05999.

We use the **public Glicko-2 scale (1500/350)** inside the math module. The
1.0–7.0 display scale is a separate concern; we convert at the boundary
(Task 12).

- [ ] **Step 1: Create `tests/unit/test_glicko2.py`**

```python
import pytest
from app.rating.glicko2 import Rating, update

def test_glickman_reference_example():
    player = Rating(rating=1500.0, rd=200.0, volatility=0.06)
    opponents = [
        Rating(rating=1400.0, rd=30.0, volatility=0.06),
        Rating(rating=1550.0, rd=100.0, volatility=0.06),
        Rating(rating=1700.0, rd=300.0, volatility=0.06),
    ]
    scores = [1.0, 0.0, 0.0]

    result = update(player, opponents, scores, tau=0.5)

    assert result.rating == pytest.approx(1464.06, abs=0.05)
    assert result.rd == pytest.approx(151.52, abs=0.5)
    assert result.volatility == pytest.approx(0.05999, abs=0.0005)


def test_no_matches_increases_rd_only():
    player = Rating(rating=1500.0, rd=200.0, volatility=0.06)
    result = update(player, [], [], tau=0.5)
    assert result.rating == pytest.approx(1500.0, abs=0.001)
    assert result.rd > 200.0
    assert result.volatility == pytest.approx(0.06, abs=0.0005)
```

- [ ] **Step 2: Run test, expect ImportError**

Run: `pytest tests/unit/test_glicko2.py -v`
Expected: FAIL — module `app.rating.glicko2` not found.

- [ ] **Step 3: Commit the failing test**

```bash
git add backend/app/rating/__init__.py backend/tests/unit/test_glicko2.py
git commit -m "test(backend): failing Glicko-2 reference test"
```

---

## Task 9: Glicko-2 implementation

**Files:**
- Create: `backend/app/rating/glicko2.py`

- [ ] **Step 1: Implement `app/rating/glicko2.py`**

```python
"""Pure Glicko-2 update.

Implements Glickman's algorithm exactly as described in
http://www.glicko.net/glicko/glicko2.pdf .

Inputs/outputs are on the standard Glicko-2 scale (1500 mean, 350 max RD).
Convert to/from display scale at the boundary.
"""
from __future__ import annotations
import math
from dataclasses import dataclass

GLICKO2_CONST = 173.7178


@dataclass(frozen=True)
class Rating:
    rating: float        # display-equivalent on Glicko scale (e.g. 1500)
    rd: float            # rating deviation on Glicko scale
    volatility: float


def _g(phi: float) -> float:
    return 1.0 / math.sqrt(1.0 + 3.0 * phi * phi / (math.pi * math.pi))


def _e(mu: float, mu_j: float, phi_j: float) -> float:
    return 1.0 / (1.0 + math.exp(-_g(phi_j) * (mu - mu_j)))


def update(
    player: Rating,
    opponents: list[Rating],
    scores: list[float],
    tau: float = 0.5,
    epsilon: float = 1e-6,
) -> Rating:
    if len(opponents) != len(scores):
        raise ValueError("opponents and scores must be the same length")

    mu = (player.rating - 1500.0) / GLICKO2_CONST
    phi = player.rd / GLICKO2_CONST
    sigma = player.volatility

    if not opponents:
        # Step 6 only: inflate RD by volatility.
        phi_star = math.sqrt(phi * phi + sigma * sigma)
        new_rd = phi_star * GLICKO2_CONST
        return Rating(player.rating, new_rd, sigma)

    mu_js = [(o.rating - 1500.0) / GLICKO2_CONST for o in opponents]
    phi_js = [o.rd / GLICKO2_CONST for o in opponents]

    v_inv = 0.0
    delta_sum = 0.0
    for mu_j, phi_j, s in zip(mu_js, phi_js, scores, strict=True):
        g = _g(phi_j)
        e = _e(mu, mu_j, phi_j)
        v_inv += g * g * e * (1.0 - e)
        delta_sum += g * (s - e)
    v = 1.0 / v_inv
    delta = v * delta_sum

    a = math.log(sigma * sigma)

    def f(x: float) -> float:
        ex = math.exp(x)
        num = ex * (delta * delta - phi * phi - v - ex)
        den = 2.0 * (phi * phi + v + ex) ** 2
        return num / den - (x - a) / (tau * tau)

    A = a
    if delta * delta > phi * phi + v:
        B = math.log(delta * delta - phi * phi - v)
    else:
        k = 1
        while f(a - k * tau) < 0:
            k += 1
        B = a - k * tau

    fA = f(A)
    fB = f(B)
    while abs(B - A) > epsilon:
        C = A + (A - B) * fA / (fB - fA)
        fC = f(C)
        if fC * fB <= 0:
            A, fA = B, fB
        else:
            fA = fA / 2.0
        B, fB = C, fC

    new_sigma = math.exp(A / 2.0)
    phi_star = math.sqrt(phi * phi + new_sigma * new_sigma)
    new_phi = 1.0 / math.sqrt(1.0 / (phi_star * phi_star) + 1.0 / v)
    new_mu = mu + new_phi * new_phi * delta_sum

    return Rating(
        rating=new_mu * GLICKO2_CONST + 1500.0,
        rd=new_phi * GLICKO2_CONST,
        volatility=new_sigma,
    )
```

- [ ] **Step 2: Run tests, expect PASS**

Run: `pytest tests/unit/test_glicko2.py -v`
Expected: 2 passed.

- [ ] **Step 3: Commit**

```bash
git add backend/app/rating/glicko2.py
git commit -m "feat(backend): Glicko-2 update against Glickman reference"
```

---

## Task 10: Display-scale conversion

The DB and API expose rating on a **1.0–7.0 display scale**. Internally we
run Glicko-2 on the standard 1500/350 scale. Define an explicit conversion.

- Display 1.0 ↔ Glicko 800
- Display 7.0 ↔ Glicko 2400
- Linear: `display = 1.0 + (glicko - 800) * (6.0 / 1600)`
- RD scales by the same factor: `display_rd = glicko_rd * (6.0 / 1600)`
- Volatility is unitless — stored as-is.

**Files:**
- Create: `backend/app/rating/scale.py`
- Create: `backend/tests/unit/test_scale.py`

- [ ] **Step 1: Write `tests/unit/test_scale.py`**

```python
import pytest
from app.rating.scale import to_display, from_display

def test_seed_round_trip():
    g = from_display(rating=3.5, rd=1.2)
    assert g.rating == pytest.approx(1500.0, abs=0.001)
    assert g.rd == pytest.approx(320.0, abs=0.001)

def test_endpoints():
    assert to_display(800.0, 0.0)[0] == pytest.approx(1.0)
    assert to_display(2400.0, 0.0)[0] == pytest.approx(7.0)
```

- [ ] **Step 2: Implement `app/rating/scale.py`**

```python
from app.rating.glicko2 import Rating

DISPLAY_MIN, DISPLAY_MAX = 1.0, 7.0
GLICKO_MIN, GLICKO_MAX = 800.0, 2400.0
DISPLAY_SPAN = DISPLAY_MAX - DISPLAY_MIN              # 6.0
GLICKO_SPAN = GLICKO_MAX - GLICKO_MIN                 # 1600.0
FACTOR = DISPLAY_SPAN / GLICKO_SPAN                   # 0.00375


def from_display(rating: float, rd: float, volatility: float = 0.06) -> Rating:
    g_rating = GLICKO_MIN + (rating - DISPLAY_MIN) / FACTOR
    g_rd = rd / FACTOR
    return Rating(rating=g_rating, rd=g_rd, volatility=volatility)


def to_display(g_rating: float, g_rd: float) -> tuple[float, float]:
    rating = DISPLAY_MIN + (g_rating - GLICKO_MIN) * FACTOR
    rd = g_rd * FACTOR
    return rating, rd
```

- [ ] **Step 3: Run tests, expect PASS**

Run: `pytest tests/unit/test_scale.py -v`
Expected: 2 passed.

- [ ] **Step 4: Commit**

```bash
git add backend/app/rating/scale.py backend/tests/unit/test_scale.py
git commit -m "feat(backend): display ↔ Glicko-2 scale conversion"
```

---

## Task 11: Doubles carry-weight scaler

**Files:**
- Create: `backend/app/rating/doubles.py`
- Create: `backend/tests/unit/test_doubles_scaler.py`

- [ ] **Step 1: Write `tests/unit/test_doubles_scaler.py`**

```python
import pytest
from app.rating.doubles import carry_scaler

def test_equal_teammates_scaler_is_one():
    assert carry_scaler(player_rating=3.5, team_avg=3.5) == pytest.approx(1.0)

def test_lower_rated_teammate_scales_up():
    assert carry_scaler(player_rating=3.0, team_avg=4.0) > 1.0

def test_higher_rated_teammate_scales_down():
    assert carry_scaler(player_rating=5.0, team_avg=4.0) < 1.0

def test_clamped_lower_bound():
    assert carry_scaler(player_rating=6.5, team_avg=3.0) == pytest.approx(0.5)

def test_clamped_upper_bound():
    assert carry_scaler(player_rating=1.5, team_avg=6.0) == pytest.approx(1.5)
```

- [ ] **Step 2: Implement `app/rating/doubles.py`**

```python
def carry_scaler(player_rating: float, team_avg: float,
                 lo: float = 0.5, hi: float = 1.5) -> float:
    raw = team_avg / player_rating
    return max(lo, min(hi, raw))
```

- [ ] **Step 3: Run tests, expect PASS**

Run: `pytest tests/unit/test_doubles_scaler.py -v`
Expected: 5 passed.

- [ ] **Step 4: Commit**

```bash
git add backend/app/rating/doubles.py backend/tests/unit/test_doubles_scaler.py
git commit -m "feat(backend): doubles carry-weight scaler"
```

---

## Task 12: Rating service — singles update against the DB

**Files:**
- Create: `backend/app/rating/service.py`
- Create: `backend/tests/integration/test_rating_service.py`

The service reads `player_ratings`, runs the Glicko update, writes a
`rating_events` row per player, updates `player_ratings`.

- [ ] **Step 1: Write `tests/integration/test_rating_service.py`**

```python
import uuid
from datetime import UTC, datetime, timedelta
from sqlalchemy import select
from app.db.base import Base
from app.db.models import (
    Match, MatchParticipant, Player, PlayerRating, RatingEvent,
)
from app.rating.service import apply_singles_update


async def _setup(session, engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    p1 = Player(phone_e164="+919800000020", display_name="A", firebase_uid="u-20")
    p2 = Player(phone_e164="+919800000021", display_name="B", firebase_uid="u-21")
    session.add_all([p1, p2])
    await session.flush()
    session.add_all([
        PlayerRating(player_id=p1.id, format="S"),
        PlayerRating(player_id=p1.id, format="D"),
        PlayerRating(player_id=p2.id, format="S"),
        PlayerRating(player_id=p2.id, format="D"),
    ])
    now = datetime.now(UTC)
    m = Match(format="S", played_at=now, submitted_by=p1.id,
              status="pending", validation_deadline=now + timedelta(hours=72))
    session.add(m); await session.flush()
    session.add_all([
        MatchParticipant(match_id=m.id, player_id=p1.id, team=1, is_submitter=True, confirmed_at=now),
        MatchParticipant(match_id=m.id, player_id=p2.id, team=2),
    ])
    await session.commit()
    return p1, p2, m


async def test_singles_update_changes_ratings_and_emits_events(engine, session):
    p1, p2, m = await _setup(session, engine)

    # team 1 wins
    await apply_singles_update(session, match_id=m.id, winning_team=1)
    await session.commit()

    r1 = (await session.execute(
        select(PlayerRating).where(
            (PlayerRating.player_id == p1.id) & (PlayerRating.format == "S"))
    )).scalar_one()
    r2 = (await session.execute(
        select(PlayerRating).where(
            (PlayerRating.player_id == p2.id) & (PlayerRating.format == "S"))
    )).scalar_one()

    assert r1.rating > 3.5
    assert r2.rating < 3.5
    assert r1.matches_played == 1
    assert r2.matches_played == 1

    events = (await session.execute(select(RatingEvent))).scalars().all()
    assert len(events) == 2
    assert {e.player_id for e in events} == {p1.id, p2.id}
```

- [ ] **Step 2: Implement `app/rating/service.py`**

```python
from __future__ import annotations
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import (
    Match, MatchParticipant, PlayerRating, RatingEvent,
)
from app.rating.glicko2 import update as glicko_update
from app.rating.scale import from_display, to_display
from app.rating.doubles import carry_scaler


async def _load_participants(
    session: AsyncSession, match_id: uuid.UUID
) -> list[MatchParticipant]:
    res = await session.execute(
        select(MatchParticipant).where(MatchParticipant.match_id == match_id)
    )
    return list(res.scalars().all())


async def _load_rating(
    session: AsyncSession, player_id: uuid.UUID, fmt: str
) -> PlayerRating:
    res = await session.execute(
        select(PlayerRating).where(
            (PlayerRating.player_id == player_id) & (PlayerRating.format == fmt)
        )
    )
    return res.scalar_one()


async def apply_singles_update(
    session: AsyncSession, match_id: uuid.UUID, winning_team: int
) -> None:
    parts = await _load_participants(session, match_id)
    assert len(parts) == 2, "singles must have exactly 2 participants"

    by_team = {p.team: p for p in parts}
    ratings = {
        p.player_id: await _load_rating(session, p.player_id, "S")
        for p in parts
    }

    for me_team, opp_team in [(1, 2), (2, 1)]:
        me = by_team[me_team]
        opp = by_team[opp_team]
        r_me = ratings[me.player_id]
        r_opp = ratings[opp.player_id]
        score = 1.0 if winning_team == me_team else 0.0

        g_me = from_display(r_me.rating, r_me.rd, r_me.volatility)
        g_opp = from_display(r_opp.rating, r_opp.rd, r_opp.volatility)
        new = glicko_update(g_me, [g_opp], [score])
        new_rating, new_rd = to_display(new.rating, new.rd)

        session.add(RatingEvent(
            player_id=me.player_id, match_id=match_id, format="S",
            rating_before=r_me.rating, rating_after=new_rating,
            rd_before=r_me.rd, rd_after=new_rd,
        ))
        r_me.rating = new_rating
        r_me.rd = new_rd
        r_me.volatility = new.volatility
        r_me.matches_played += 1


async def apply_doubles_update(
    session: AsyncSession, match_id: uuid.UUID, winning_team: int
) -> None:
    parts = await _load_participants(session, match_id)
    assert len(parts) == 4, "doubles must have exactly 4 participants"

    teams: dict[int, list[MatchParticipant]] = {1: [], 2: []}
    for p in parts:
        teams[p.team].append(p)
    assert len(teams[1]) == 2 and len(teams[2]) == 2

    ratings = {
        p.player_id: await _load_rating(session, p.player_id, "D")
        for p in parts
    }

    team_avg = {
        t: sum(ratings[p.player_id].rating for p in teams[t]) / 2.0
        for t in (1, 2)
    }
    team_rd = {
        t: ( (ratings[teams[t][0].player_id].rd ** 2
              + ratings[teams[t][1].player_id].rd ** 2) / 2.0 ) ** 0.5
        for t in (1, 2)
    }

    for t, opp_t in [(1, 2), (2, 1)]:
        score = 1.0 if winning_team == t else 0.0
        for p in teams[t]:
            r = ratings[p.player_id]
            g_me = from_display(r.rating, r.rd, r.volatility)
            g_opp = from_display(team_avg[opp_t], team_rd[opp_t], 0.06)
            new = glicko_update(g_me, [g_opp], [score])
            new_rating, new_rd = to_display(new.rating, new.rd)

            base_delta = new_rating - r.rating
            scaler = carry_scaler(r.rating, team_avg[t])
            final_rating = r.rating + base_delta * scaler

            session.add(RatingEvent(
                player_id=p.player_id, match_id=match_id, format="D",
                rating_before=r.rating, rating_after=final_rating,
                rd_before=r.rd, rd_after=new_rd,
            ))
            r.rating = final_rating
            r.rd = new_rd
            r.volatility = new.volatility
            r.matches_played += 1


async def apply_match_rating(
    session: AsyncSession, match: Match, winning_team: int
) -> None:
    if match.format == "S":
        await apply_singles_update(session, match.id, winning_team)
    else:
        await apply_doubles_update(session, match.id, winning_team)
```

- [ ] **Step 3: Run tests, expect PASS**

Run: `pytest tests/integration/test_rating_service.py -v`
Expected: 1 passed.

- [ ] **Step 4: Commit**

```bash
git add backend/app/rating/service.py backend/tests/integration/test_rating_service.py
git commit -m "feat(backend): rating service for singles + doubles"
```

---

## Task 13: Doubles rating service — integration test for carry behavior

**Files:**
- Create: `backend/tests/integration/test_doubles_rating.py`

- [ ] **Step 1: Write `tests/integration/test_doubles_rating.py`**

```python
from datetime import UTC, datetime, timedelta
from sqlalchemy import select
from app.db.base import Base
from app.db.models import (
    Match, MatchParticipant, Player, PlayerRating,
)
from app.rating.service import apply_doubles_update


async def test_lower_rated_teammate_gains_more(engine, session):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Team 1: rating 3.0 + rating 5.0. Team 2: 4.0 + 4.0. Team 1 wins.
    names = ["A", "B", "C", "D"]
    ratings = [3.0, 5.0, 4.0, 4.0]
    players = []
    for i, (n, r) in enumerate(zip(names, ratings, strict=True)):
        p = Player(phone_e164=f"+9198000300{i}", display_name=n, firebase_uid=f"u-30{i}")
        session.add(p); await session.flush()
        session.add_all([
            PlayerRating(player_id=p.id, format="S"),
            PlayerRating(player_id=p.id, format="D", rating=r),
        ])
        players.append(p)
    await session.flush()

    now = datetime.now(UTC)
    m = Match(format="D", played_at=now, submitted_by=players[0].id,
              status="pending", validation_deadline=now + timedelta(hours=72))
    session.add(m); await session.flush()
    for idx, team in enumerate([1, 1, 2, 2]):
        session.add(MatchParticipant(
            match_id=m.id, player_id=players[idx].id, team=team,
            is_submitter=(idx == 0),
            confirmed_at=(now if idx == 0 else None),
        ))
    await session.commit()

    await apply_doubles_update(session, match_id=m.id, winning_team=1)
    await session.commit()

    new_ratings = {
        p.display_name: (await session.execute(
            select(PlayerRating).where(
                (PlayerRating.player_id == p.id) & (PlayerRating.format == "D"))
        )).scalar_one().rating
        for p in players
    }
    delta_a = new_ratings["A"] - 3.0
    delta_b = new_ratings["B"] - 5.0
    assert delta_a > 0 and delta_b > 0
    assert delta_a > delta_b      # lower-rated teammate gains more
    assert new_ratings["C"] < 4.0
    assert new_ratings["D"] < 4.0
```

- [ ] **Step 2: Run test, expect PASS**

Run: `pytest tests/integration/test_doubles_rating.py -v`
Expected: 1 passed.

- [ ] **Step 3: Commit**

```bash
git add backend/tests/integration/test_doubles_rating.py
git commit -m "test(backend): doubles carry-weight integration test"
```

---

## Task 14: Score validators

**Files:**
- Create: `backend/app/matches/__init__.py` (empty)
- Create: `backend/app/matches/validators.py`
- Create: `backend/tests/unit/test_validators.py`

Rules (from spec §5.5):
- Each game: a winner reaches ≥21 with a 2-point lead, capped at 30.
- The same team must win all recorded games' max in best-of: NOT enforced (we
  allow any number of games 1..5; we just compute the winner per match by who
  won more games).
- A match must have at least one game.

- [ ] **Step 1: Write `tests/unit/test_validators.py`**

```python
import pytest
from app.matches.validators import (
    game_winner, match_winner, GameScoreError, MatchScoreError,
)

def test_normal_21_18():
    assert game_winner(21, 18) == 1

def test_deuce_30_29():
    assert game_winner(29, 30) == 2

def test_under_21_no_winner():
    with pytest.raises(GameScoreError):
        game_winner(20, 18)

def test_winner_must_lead_by_2():
    with pytest.raises(GameScoreError):
        game_winner(22, 21)

def test_cap_at_30():
    with pytest.raises(GameScoreError):
        game_winner(31, 29)

def test_match_winner_two_one():
    assert match_winner([(21, 18), (18, 21), (21, 19)]) == 1

def test_match_winner_two_zero():
    assert match_winner([(21, 15), (21, 12)]) == 1

def test_match_winner_no_games():
    with pytest.raises(MatchScoreError):
        match_winner([])

def test_match_winner_tied_rejected():
    # Equal game wins is impossible if all games have a winner — but if it
    # ever happens, we reject as a data-shape error.
    with pytest.raises(MatchScoreError):
        match_winner([(21, 18), (18, 21)])
```

- [ ] **Step 2: Implement `app/matches/validators.py`**

```python
class GameScoreError(ValueError):
    pass

class MatchScoreError(ValueError):
    pass


def game_winner(t1: int, t2: int) -> int:
    if t1 < 0 or t2 < 0:
        raise GameScoreError("negative score")
    hi, lo = max(t1, t2), min(t1, t2)
    if hi > 30 or lo > 30:
        raise GameScoreError("score above cap of 30")
    if hi < 21:
        raise GameScoreError("no winner: max score below 21")
    if hi == 30:
        if lo != 29:
            raise GameScoreError("score of 30 must be paired with 29")
    elif hi - lo < 2:
        raise GameScoreError("winner must lead by 2")
    return 1 if t1 > t2 else 2


def match_winner(games: list[tuple[int, int]]) -> int:
    if not games:
        raise MatchScoreError("no games recorded")
    wins = {1: 0, 2: 0}
    for t1, t2 in games:
        wins[game_winner(t1, t2)] += 1
    if wins[1] == wins[2]:
        raise MatchScoreError("game wins are tied")
    return 1 if wins[1] > wins[2] else 2
```

- [ ] **Step 3: Run tests, expect PASS**

Run: `pytest tests/unit/test_validators.py -v`
Expected: 9 passed.

- [ ] **Step 4: Commit**

```bash
git add backend/app/matches/__init__.py backend/app/matches/validators.py backend/tests/unit/test_validators.py
git commit -m "feat(backend): match + game score validators"
```

---

## Task 15: Firebase auth dependency (with test override)

**Files:**
- Create: `backend/app/auth/__init__.py` (empty)
- Create: `backend/app/auth/firebase.py`
- Modify: `backend/app/main.py`
- Modify: `backend/app/deps.py`
- Create: `backend/tests/integration/test_auth.py`

The Firebase Admin SDK verifies ID tokens. In tests we override the
dependency to return a stub identity. In dev with no credentials, we use a
stub identity from the bearer token literal `dev:<uid>:<phone>`.

- [ ] **Step 1: Implement `app/auth/firebase.py`**

```python
from __future__ import annotations
from dataclasses import dataclass
from fastapi import Header, HTTPException, status

from app.config import settings

@dataclass(frozen=True)
class FirebaseIdentity:
    uid: str
    phone_e164: str


_initialized = False

def _init_admin_once() -> None:
    global _initialized
    if _initialized:
        return
    if not settings.firebase_credentials_path:
        _initialized = True
        return
    import firebase_admin
    from firebase_admin import credentials
    cred = credentials.Certificate(settings.firebase_credentials_path)
    firebase_admin.initialize_app(cred)
    _initialized = True


async def verify_id_token(
    authorization: str | None = Header(default=None),
) -> FirebaseIdentity:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing bearer token")
    token = authorization.split(" ", 1)[1].strip()

    if settings.env == "dev" and token.startswith("dev:"):
        # Format: dev:<uid>:<phone>
        parts = token.split(":")
        if len(parts) != 3:
            raise HTTPException(status.HTTP_401_UNAUTHORIZED, "bad dev token")
        return FirebaseIdentity(uid=parts[1], phone_e164=parts[2])

    _init_admin_once()
    if not settings.firebase_credentials_path:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "firebase not configured")

    from firebase_admin import auth as fb_auth
    try:
        decoded = fb_auth.verify_id_token(token)
    except Exception as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, f"invalid token: {e}") from e

    phone = decoded.get("phone_number")
    if not phone:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "token has no phone_number")
    return FirebaseIdentity(uid=decoded["uid"], phone_e164=phone)
```

- [ ] **Step 2: Update `app/deps.py`**

```python
from collections.abc import AsyncIterator
from typing import Annotated
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.firebase import FirebaseIdentity, verify_id_token
from app.db.base import get_session

DbSession = Annotated[AsyncSession, Depends(get_session)]
CurrentIdentity = Annotated[FirebaseIdentity, Depends(verify_id_token)]
```

- [ ] **Step 3: Add a `/me/identity` debug endpoint in `app/main.py` for testing**

Replace `app/main.py` with:

```python
from fastapi import FastAPI
from app.deps import CurrentIdentity

def create_app() -> FastAPI:
    app = FastAPI(title="Rally API", version="0.1.0")

    @app.get("/healthz")
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/_debug/identity")
    async def debug_identity(ident: CurrentIdentity) -> dict[str, str]:
        return {"uid": ident.uid, "phone_e164": ident.phone_e164}

    return app

app = create_app()
```

- [ ] **Step 4: Write `tests/integration/test_auth.py`**

```python
from httpx import ASGITransport, AsyncClient
from app.main import create_app

async def test_missing_token_rejected():
    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://t") as ac:
        resp = await ac.get("/_debug/identity")
    assert resp.status_code == 401

async def test_dev_token_accepted(monkeypatch):
    monkeypatch.setenv("ENV", "dev")
    from app.config import settings
    settings.env = "dev"
    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://t") as ac:
        resp = await ac.get(
            "/_debug/identity",
            headers={"Authorization": "Bearer dev:uid-1:+919800009999"},
        )
    assert resp.status_code == 200
    assert resp.json() == {"uid": "uid-1", "phone_e164": "+919800009999"}
```

- [ ] **Step 5: Run tests, expect PASS**

Run: `pytest tests/integration/test_auth.py -v`
Expected: 2 passed.

- [ ] **Step 6: Commit**

```bash
git add backend/app/auth/ backend/app/main.py backend/app/deps.py backend/tests/integration/test_auth.py
git commit -m "feat(backend): Firebase ID token auth + dev token shortcut"
```

---

## Task 16: Error model + exception handlers

**Files:**
- Create: `backend/app/errors.py`
- Modify: `backend/app/main.py`

- [ ] **Step 1: Create `app/errors.py`**

```python
from __future__ import annotations
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class AppError(Exception):
    code: str = "app_error"
    http_status: int = 400

    def __init__(self, message: str, *, code: str | None = None,
                 http_status: int | None = None):
        super().__init__(message)
        self.message = message
        if code:
            self.code = code
        if http_status:
            self.http_status = http_status


class NotFound(AppError):
    code = "not_found"
    http_status = 404

class Conflict(AppError):
    code = "conflict"
    http_status = 409

class Forbidden(AppError):
    code = "forbidden"
    http_status = 403

class BadRequest(AppError):
    code = "bad_request"
    http_status = 400


def install_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def _app_error_handler(_req: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.http_status,
            content={"code": exc.code, "message": exc.message},
        )
```

- [ ] **Step 2: Update `app/main.py` to install handlers**

```python
from fastapi import FastAPI
from app.deps import CurrentIdentity
from app.errors import install_handlers

def create_app() -> FastAPI:
    app = FastAPI(title="Rally API", version="0.1.0")
    install_handlers(app)

    @app.get("/healthz")
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/_debug/identity")
    async def debug_identity(ident: CurrentIdentity) -> dict[str, str]:
        return {"uid": ident.uid, "phone_e164": ident.phone_e164}

    return app

app = create_app()
```

- [ ] **Step 3: Commit**

```bash
git add backend/app/errors.py backend/app/main.py
git commit -m "feat(backend): app error model + exception handlers"
```

---

## Task 17: Players router — create + get me + patch me

**Files:**
- Create: `backend/app/players/__init__.py` (empty)
- Create: `backend/app/players/schemas.py`
- Create: `backend/app/players/service.py`
- Create: `backend/app/players/router.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/integration/test_players.py`

- [ ] **Step 1: Implement `app/players/schemas.py`**

```python
from __future__ import annotations
from datetime import date
from pydantic import BaseModel, Field

class PlayerCreate(BaseModel):
    display_name: str = Field(min_length=1, max_length=80)
    gender: str | None = Field(default=None, pattern="^[MFO]$")
    dob: date | None = None
    home_city: str = "BLR"

class PlayerUpdate(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=80)
    gender: str | None = Field(default=None, pattern="^[MFO]$")
    dob: date | None = None
    home_city: str | None = None

class RatingOut(BaseModel):
    format: str
    rating: float
    rd: float
    matches_played: int

class PlayerOut(BaseModel):
    id: str
    phone_e164: str
    display_name: str
    gender: str | None
    dob: date | None
    home_city: str
    ratings: list[RatingOut]
```

- [ ] **Step 2: Implement `app/players/service.py`**

```python
from __future__ import annotations
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.firebase import FirebaseIdentity
from app.db.models import Player, PlayerRating
from app.errors import Conflict, NotFound
from app.players.schemas import PlayerCreate, PlayerUpdate


async def get_by_firebase_uid(
    session: AsyncSession, firebase_uid: str
) -> Player | None:
    res = await session.execute(
        select(Player).where(Player.firebase_uid == firebase_uid)
    )
    return res.scalar_one_or_none()


async def create_player(
    session: AsyncSession, ident: FirebaseIdentity, data: PlayerCreate
) -> Player:
    existing = await get_by_firebase_uid(session, ident.uid)
    if existing:
        raise Conflict("player already exists", code="player_exists")

    p = Player(
        phone_e164=ident.phone_e164,
        display_name=data.display_name,
        gender=data.gender,
        dob=data.dob,
        home_city=data.home_city,
        firebase_uid=ident.uid,
    )
    session.add(p)
    await session.flush()
    session.add_all([
        PlayerRating(player_id=p.id, format="S"),
        PlayerRating(player_id=p.id, format="D"),
    ])
    await session.commit()
    await session.refresh(p)
    return p


async def update_me(
    session: AsyncSession, player: Player, data: PlayerUpdate
) -> Player:
    if data.display_name is not None:
        player.display_name = data.display_name
    if data.gender is not None:
        player.gender = data.gender
    if data.dob is not None:
        player.dob = data.dob
    if data.home_city is not None:
        player.home_city = data.home_city
    await session.commit()
    return player


async def get_me_or_404(
    session: AsyncSession, ident: FirebaseIdentity
) -> Player:
    p = await get_by_firebase_uid(session, ident.uid)
    if not p:
        raise NotFound("player not found", code="player_not_found")
    return p


async def load_ratings(
    session: AsyncSession, player_id: uuid.UUID
) -> list[PlayerRating]:
    res = await session.execute(
        select(PlayerRating).where(PlayerRating.player_id == player_id)
    )
    return list(res.scalars().all())
```

- [ ] **Step 3: Implement `app/players/router.py`**

```python
from fastapi import APIRouter

from app.deps import CurrentIdentity, DbSession
from app.players import service
from app.players.schemas import PlayerCreate, PlayerOut, PlayerUpdate, RatingOut

router = APIRouter(prefix="/players", tags=["players"])


def _serialize(player, ratings) -> PlayerOut:
    return PlayerOut(
        id=str(player.id),
        phone_e164=player.phone_e164,
        display_name=player.display_name,
        gender=player.gender,
        dob=player.dob,
        home_city=player.home_city,
        ratings=[
            RatingOut(format=r.format, rating=r.rating, rd=r.rd,
                      matches_played=r.matches_played)
            for r in ratings
        ],
    )


@router.post("", response_model=PlayerOut, status_code=201)
async def create(
    body: PlayerCreate, session: DbSession, ident: CurrentIdentity,
) -> PlayerOut:
    p = await service.create_player(session, ident, body)
    ratings = await service.load_ratings(session, p.id)
    return _serialize(p, ratings)


@router.get("/me", response_model=PlayerOut)
async def get_me(session: DbSession, ident: CurrentIdentity) -> PlayerOut:
    p = await service.get_me_or_404(session, ident)
    ratings = await service.load_ratings(session, p.id)
    return _serialize(p, ratings)


@router.patch("/me", response_model=PlayerOut)
async def patch_me(
    body: PlayerUpdate, session: DbSession, ident: CurrentIdentity,
) -> PlayerOut:
    p = await service.get_me_or_404(session, ident)
    p = await service.update_me(session, p, body)
    ratings = await service.load_ratings(session, p.id)
    return _serialize(p, ratings)
```

- [ ] **Step 4: Mount router in `app/main.py`**

```python
from fastapi import FastAPI
from app.deps import CurrentIdentity
from app.errors import install_handlers
from app.players.router import router as players_router

def create_app() -> FastAPI:
    app = FastAPI(title="Rally API", version="0.1.0")
    install_handlers(app)
    app.include_router(players_router)

    @app.get("/healthz")
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/_debug/identity")
    async def debug_identity(ident: CurrentIdentity) -> dict[str, str]:
        return {"uid": ident.uid, "phone_e164": ident.phone_e164}

    return app

app = create_app()
```

- [ ] **Step 5: Write `tests/integration/test_players.py`**

```python
import os
from httpx import ASGITransport, AsyncClient
from app.db.base import Base
from app.main import create_app


async def _client(engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return AsyncClient(transport=ASGITransport(app=create_app()), base_url="http://t")


async def test_create_then_get_me(engine, monkeypatch):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        h = {"Authorization": "Bearer dev:uid-100:+919800001000"}
        r = await ac.post("/players", json={"display_name": "Asha"}, headers=h)
        assert r.status_code == 201, r.text
        body = r.json()
        assert body["display_name"] == "Asha"
        assert body["phone_e164"] == "+919800001000"
        assert {x["format"] for x in body["ratings"]} == {"S", "D"}
        assert all(x["rating"] == 3.5 for x in body["ratings"])

        r2 = await ac.get("/players/me", headers=h)
        assert r2.status_code == 200
        assert r2.json()["id"] == body["id"]


async def test_create_twice_is_conflict(engine):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        h = {"Authorization": "Bearer dev:uid-101:+919800001001"}
        r = await ac.post("/players", json={"display_name": "B"}, headers=h)
        assert r.status_code == 201
        r2 = await ac.post("/players", json={"display_name": "B"}, headers=h)
        assert r2.status_code == 409
        assert r2.json()["code"] == "player_exists"


async def test_patch_me_updates_name(engine):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        h = {"Authorization": "Bearer dev:uid-102:+919800001002"}
        await ac.post("/players", json={"display_name": "C"}, headers=h)
        r = await ac.patch("/players/me", json={"display_name": "Cara"}, headers=h)
        assert r.status_code == 200
        assert r.json()["display_name"] == "Cara"
```

- [ ] **Step 6: Run tests, expect PASS**

Run: `pytest tests/integration/test_players.py -v`
Expected: 3 passed.

- [ ] **Step 7: Commit**

```bash
git add backend/app/players/ backend/app/main.py backend/tests/integration/test_players.py
git commit -m "feat(backend): /players endpoints (create, get me, patch me)"
```

---

## Task 18: FCM push wrapper (with a no-op test mode)

**Files:**
- Create: `backend/app/push/__init__.py` (empty)
- Create: `backend/app/push/fcm.py`

In tests and `ENV=dev` without credentials, FCM calls are no-ops and just
append to an in-memory list we can introspect. In prod, we use
`firebase_admin.messaging`.

- [ ] **Step 1: Implement `app/push/fcm.py`**

```python
from __future__ import annotations
from dataclasses import dataclass

from app.config import settings


@dataclass
class PushMessage:
    firebase_uid: str
    title: str
    body: str
    data: dict[str, str]


# Test/dev capture. Cleared by tests via clear_sent_messages().
_sent: list[PushMessage] = []


def sent_messages() -> list[PushMessage]:
    return list(_sent)


def clear_sent_messages() -> None:
    _sent.clear()


async def send_to_uid(uid: str, title: str, body: str,
                     data: dict[str, str] | None = None) -> None:
    msg = PushMessage(firebase_uid=uid, title=title, body=body, data=data or {})

    if settings.env == "dev" or not settings.firebase_credentials_path:
        _sent.append(msg)
        return

    # Production path: send via FCM. The user's FCM token must be looked up
    # from their player record (added in a later task / v1.1 — for now we
    # send a `data` message via topic per-uid, which the Flutter app
    # subscribes to on login).
    import firebase_admin
    from firebase_admin import credentials, messaging
    if not firebase_admin._apps:
        cred = credentials.Certificate(settings.firebase_credentials_path)
        firebase_admin.initialize_app(cred)
    fcm_msg = messaging.Message(
        topic=f"user-{uid}",
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
    )
    messaging.send(fcm_msg)
```

- [ ] **Step 2: Commit**

```bash
git add backend/app/push/
git commit -m "feat(backend): FCM send wrapper with dev no-op mode"
```

---

## Task 19: Match submission — service core

**Files:**
- Create: `backend/app/matches/schemas.py`
- Create: `backend/app/matches/service.py`
- Create: `backend/app/matches/dedup.py`
- Create: `backend/tests/unit/test_dedup.py`

Submission rules:
- Submitter must appear on exactly one team.
- For singles: 1 player per team. For doubles: 2 players per team.
- No phone appears on both teams.
- Score sanity passes (`match_winner` returns a winner).
- Dedup key: `(submitted_by, played_at ± 15min, sorted set of all phones)`.
- For each non-registered phone → `match_invites` + SMS-send placeholder.
  In MVP, SMS = log line. Real SMS hooked up in deploy plan.
- For each registered phone → `match_participants` row + push.
- Submitter row: `is_submitter=True`, `confirmed_at=now()`.
- `status='pending'`, `validation_deadline=now()+72h`.

- [ ] **Step 1: Implement `app/matches/schemas.py`**

```python
from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel, Field


class GameIn(BaseModel):
    game_no: int = Field(ge=1, le=5)
    team1_points: int = Field(ge=0, le=30)
    team2_points: int = Field(ge=0, le=30)


class MatchSubmit(BaseModel):
    format: str = Field(pattern="^[SD]$")
    played_at: datetime
    venue: str | None = None
    team1_phones: list[str]
    team2_phones: list[str]
    games: list[GameIn]


class ParticipantOut(BaseModel):
    player_id: str | None
    phone_e164: str
    display_name: str | None
    team: int
    is_submitter: bool
    confirmed: bool
    disputed: bool


class GameOut(BaseModel):
    game_no: int
    team1_points: int
    team2_points: int


class RatingDeltaOut(BaseModel):
    player_id: str
    rating_before: float
    rating_after: float


class MatchOut(BaseModel):
    id: str
    format: str
    played_at: datetime
    venue: str | None
    status: str
    validation_deadline: datetime
    validated_at: datetime | None
    participants: list[ParticipantOut]
    games: list[GameOut]
    rating_deltas: list[RatingDeltaOut]
```

- [ ] **Step 2: Implement `app/matches/dedup.py`**

```python
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
    """Return a matching pending/validated match within ±window minutes."""
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
        # Note: invited (non-registered) phones aren't here; for MVP dedup,
        # registered-participant phone set match within window is sufficient
        # signal to flag a duplicate.
        if normalize_phones(list(parts)) == tuple(p for p in norm_target if p in parts):
            return c
    return None
```

- [ ] **Step 3: Write `tests/unit/test_dedup.py`**

```python
import uuid
from datetime import datetime, UTC
from app.matches.dedup import dedup_signature, normalize_phones

def test_signature_order_invariant():
    sid = uuid.uuid4()
    t = datetime(2026, 5, 18, 12, 0, tzinfo=UTC)
    a = dedup_signature(sid, t, ["+91A", "+91B", "+91C"])
    b = dedup_signature(sid, t, ["+91C", "+91A", "+91B"])
    assert a == b

def test_normalize_phones_sorts_and_strips():
    assert normalize_phones([" +91B ", "+91A"]) == ("+91A", "+91B")
```

- [ ] **Step 4: Run unit tests, expect PASS**

Run: `pytest tests/unit/test_dedup.py -v`
Expected: 2 passed.

- [ ] **Step 5: Implement `app/matches/service.py`**

```python
from __future__ import annotations
import logging
import uuid
from datetime import UTC, datetime, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.firebase import FirebaseIdentity
from app.db.models import (
    Match, MatchGame, MatchInvite, MatchParticipant, Player,
)
from app.errors import BadRequest, Conflict, Forbidden, NotFound
from app.matches.dedup import find_duplicate
from app.matches.schemas import MatchSubmit
from app.matches.validators import match_winner
from app.players.service import get_by_firebase_uid
from app.push import fcm

log = logging.getLogger(__name__)

VALIDATION_WINDOW = timedelta(hours=72)


def _check_team_shape(fmt: str, t1: list[str], t2: list[str]) -> None:
    required = 1 if fmt == "S" else 2
    if len(t1) != required or len(t2) != required:
        raise BadRequest(
            f"{fmt} requires {required} player(s) per team",
            code="invalid_team_size",
        )
    overlap = set(t1) & set(t2)
    if overlap:
        raise BadRequest(
            f"player(s) on both teams: {sorted(overlap)}",
            code="player_on_both_teams",
        )


async def submit_match(
    session: AsyncSession, ident: FirebaseIdentity, body: MatchSubmit
) -> Match:
    submitter = await get_by_firebase_uid(session, ident.uid)
    if not submitter:
        raise NotFound("submitter player not found", code="player_not_found")

    _check_team_shape(body.format, body.team1_phones, body.team2_phones)

    if submitter.phone_e164 not in body.team1_phones + body.team2_phones:
        raise Forbidden(
            "submitter must be a participant",
            code="submitter_not_participant",
        )

    games = [(g.team1_points, g.team2_points) for g in
             sorted(body.games, key=lambda g: g.game_no)]
    try:
        _winner = match_winner(games)
    except ValueError as e:
        raise BadRequest(str(e), code="invalid_score") from e

    all_phones = body.team1_phones + body.team2_phones
    dup = await find_duplicate(session, submitter.id, body.played_at, all_phones)
    if dup:
        raise Conflict("duplicate match", code="duplicate_match")

    # Resolve which phones are registered.
    res = await session.execute(
        select(Player).where(Player.phone_e164.in_(all_phones))
    )
    registered = {p.phone_e164: p for p in res.scalars().all()}

    now = datetime.now(UTC)
    match = Match(
        format=body.format,
        played_at=body.played_at,
        venue=body.venue,
        submitted_by=submitter.id,
        status="pending",
        validation_deadline=now + VALIDATION_WINDOW,
    )
    session.add(match)
    await session.flush()

    for team, phones in [(1, body.team1_phones), (2, body.team2_phones)]:
        for phone in phones:
            if phone in registered:
                player = registered[phone]
                is_sub = (player.id == submitter.id)
                session.add(MatchParticipant(
                    match_id=match.id,
                    player_id=player.id,
                    team=team,
                    is_submitter=is_sub,
                    confirmed_at=(now if is_sub else None),
                ))
            else:
                session.add(MatchInvite(
                    match_id=match.id, phone_e164=phone, team=team,
                ))
                log.info("SMS invite to %s for match %s", phone, match.id)

    for g in body.games:
        session.add(MatchGame(
            match_id=match.id, game_no=g.game_no,
            team1_points=g.team1_points, team2_points=g.team2_points,
        ))

    await session.commit()
    await session.refresh(match)

    # Push to opposing team members (registered only).
    submitter_team = 1 if submitter.phone_e164 in body.team1_phones else 2
    opposing_team = 2 if submitter_team == 1 else 1
    opp_phones = body.team1_phones if opposing_team == 1 else body.team2_phones
    for phone in opp_phones:
        if phone in registered:
            await fcm.send_to_uid(
                registered[phone].firebase_uid,
                title="New match to confirm",
                body=f"{submitter.display_name} logged a match against you. Tap to confirm.",
                data={"match_id": str(match.id), "kind": "match_submitted"},
            )

    return match


async def load_match(session: AsyncSession, match_id: uuid.UUID) -> Match:
    res = await session.execute(select(Match).where(Match.id == match_id))
    m = res.scalar_one_or_none()
    if not m:
        raise NotFound("match not found", code="match_not_found")
    return m


async def load_participants(
    session: AsyncSession, match_id: uuid.UUID
) -> list[tuple[MatchParticipant, Player]]:
    res = await session.execute(
        select(MatchParticipant, Player)
        .join(Player, MatchParticipant.player_id == Player.id)
        .where(MatchParticipant.match_id == match_id)
    )
    return [(mp, p) for mp, p in res.all()]


async def load_invites(
    session: AsyncSession, match_id: uuid.UUID
) -> list[MatchInvite]:
    res = await session.execute(
        select(MatchInvite).where(MatchInvite.match_id == match_id)
    )
    return list(res.scalars().all())


async def load_games(
    session: AsyncSession, match_id: uuid.UUID
) -> list[MatchGame]:
    res = await session.execute(
        select(MatchGame).where(MatchGame.match_id == match_id)
        .order_by(MatchGame.game_no)
    )
    return list(res.scalars().all())
```

- [ ] **Step 6: Commit**

```bash
git add backend/app/matches/schemas.py backend/app/matches/dedup.py backend/app/matches/service.py backend/tests/unit/test_dedup.py
git commit -m "feat(backend): match submission service core"
```

---

## Task 20: Match router — POST /matches + GET /matches/{id}

**Files:**
- Create: `backend/app/matches/router.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/integration/test_matches_submit.py`

- [ ] **Step 1: Implement `app/matches/router.py`**

```python
from __future__ import annotations
import uuid
from sqlalchemy import select
from fastapi import APIRouter

from app.deps import CurrentIdentity, DbSession
from app.db.models import RatingEvent
from app.matches import service
from app.matches.schemas import (
    GameOut, MatchOut, MatchSubmit, ParticipantOut, RatingDeltaOut,
)

router = APIRouter(prefix="/matches", tags=["matches"])


async def _serialize(session, match) -> MatchOut:
    parts = await service.load_participants(session, match.id)
    invites = await service.load_invites(session, match.id)
    games = await service.load_games(session, match.id)
    evt_res = await session.execute(
        select(RatingEvent).where(RatingEvent.match_id == match.id)
    )
    events = list(evt_res.scalars().all())

    participants: list[ParticipantOut] = []
    for mp, p in parts:
        participants.append(ParticipantOut(
            player_id=str(p.id),
            phone_e164=p.phone_e164,
            display_name=p.display_name,
            team=mp.team,
            is_submitter=mp.is_submitter,
            confirmed=mp.confirmed_at is not None,
            disputed=mp.disputed_at is not None,
        ))
    for inv in invites:
        participants.append(ParticipantOut(
            player_id=None,
            phone_e164=inv.phone_e164,
            display_name=None,
            team=inv.team,
            is_submitter=False,
            confirmed=False,
            disputed=False,
        ))

    return MatchOut(
        id=str(match.id),
        format=match.format,
        played_at=match.played_at,
        venue=match.venue,
        status=match.status,
        validation_deadline=match.validation_deadline,
        validated_at=match.validated_at,
        participants=participants,
        games=[GameOut(game_no=g.game_no, team1_points=g.team1_points,
                       team2_points=g.team2_points) for g in games],
        rating_deltas=[RatingDeltaOut(
            player_id=str(e.player_id),
            rating_before=e.rating_before,
            rating_after=e.rating_after,
        ) for e in events],
    )


@router.post("", response_model=MatchOut, status_code=201)
async def submit(body: MatchSubmit, session: DbSession,
                 ident: CurrentIdentity) -> MatchOut:
    m = await service.submit_match(session, ident, body)
    return await _serialize(session, m)


@router.get("/{match_id}", response_model=MatchOut)
async def get(match_id: uuid.UUID, session: DbSession,
              _ident: CurrentIdentity) -> MatchOut:
    m = await service.load_match(session, match_id)
    return await _serialize(session, m)
```

- [ ] **Step 2: Mount in `app/main.py`**

Replace `app/main.py` body so it also includes the matches router:

```python
from fastapi import FastAPI
from app.deps import CurrentIdentity
from app.errors import install_handlers
from app.matches.router import router as matches_router
from app.players.router import router as players_router


def create_app() -> FastAPI:
    app = FastAPI(title="Rally API", version="0.1.0")
    install_handlers(app)
    app.include_router(players_router)
    app.include_router(matches_router)

    @app.get("/healthz")
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/_debug/identity")
    async def debug_identity(ident: CurrentIdentity) -> dict[str, str]:
        return {"uid": ident.uid, "phone_e164": ident.phone_e164}

    return app

app = create_app()
```

- [ ] **Step 3: Write `tests/integration/test_matches_submit.py`**

```python
from datetime import UTC, datetime
from httpx import ASGITransport, AsyncClient
from app.db.base import Base
from app.main import create_app
from app.push import fcm


async def _client(engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return AsyncClient(transport=ASGITransport(app=create_app()), base_url="http://t")


async def _signup(ac, uid, phone, name="P"):
    return await ac.post(
        "/players", json={"display_name": name},
        headers={"Authorization": f"Bearer dev:{uid}:{phone}"},
    )


def _h(uid, phone):
    return {"Authorization": f"Bearer dev:{uid}:{phone}"}


async def test_submit_singles_both_registered(engine):
    from app.config import settings
    settings.env = "dev"
    fcm.clear_sent_messages()
    async with await _client(engine) as ac:
        await _signup(ac, "uS1", "+91980020S001", "Alice")
        await _signup(ac, "uS2", "+91980020S002", "Bob")

        body = {
            "format": "S",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980020S001"],
            "team2_phones": ["+91980020S002"],
            "games": [
                {"game_no": 1, "team1_points": 21, "team2_points": 18},
                {"game_no": 2, "team1_points": 21, "team2_points": 15},
            ],
        }
        r = await ac.post("/matches", json=body, headers=_h("uS1", "+91980020S001"))
        assert r.status_code == 201, r.text
        m = r.json()
        assert m["status"] == "pending"
        assert len(m["participants"]) == 2
        assert [g["game_no"] for g in m["games"]] == [1, 2]

        # FCM message went to Bob, not Alice.
        sent = fcm.sent_messages()
        assert len(sent) == 1
        assert sent[0].firebase_uid == "uS2"


async def test_submit_with_invited_opponent(engine):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        await _signup(ac, "uS3", "+91980020S003", "Alice")
        # Bob is NOT registered.
        body = {
            "format": "S",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980020S003"],
            "team2_phones": ["+91980020S999"],
            "games": [{"game_no": 1, "team1_points": 21, "team2_points": 12}],
        }
        r = await ac.post("/matches", json=body, headers=_h("uS3", "+91980020S003"))
        assert r.status_code == 201, r.text
        m = r.json()
        phones = {p["phone_e164"] for p in m["participants"]}
        assert "+91980020S999" in phones
        invited = [p for p in m["participants"] if p["phone_e164"] == "+91980020S999"][0]
        assert invited["player_id"] is None


async def test_submit_rejects_invalid_score(engine):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        await _signup(ac, "uS4", "+91980020S004")
        await _signup(ac, "uS5", "+91980020S005")
        body = {
            "format": "S",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980020S004"],
            "team2_phones": ["+91980020S005"],
            "games": [{"game_no": 1, "team1_points": 20, "team2_points": 18}],
        }
        r = await ac.post("/matches", json=body, headers=_h("uS4", "+91980020S004"))
        assert r.status_code == 400
        assert r.json()["code"] == "invalid_score"


async def test_submit_rejects_non_participant_submitter(engine):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        await _signup(ac, "uS6", "+91980020S006")
        await _signup(ac, "uS7", "+91980020S007")
        await _signup(ac, "uS8", "+91980020S008")
        body = {
            "format": "S",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980020S007"],
            "team2_phones": ["+91980020S008"],
            "games": [{"game_no": 1, "team1_points": 21, "team2_points": 12}],
        }
        # uS6 submits but isn't on either team.
        r = await ac.post("/matches", json=body, headers=_h("uS6", "+91980020S006"))
        assert r.status_code == 403
        assert r.json()["code"] == "submitter_not_participant"
```

- [ ] **Step 4: Run tests, expect PASS**

Run: `pytest tests/integration/test_matches_submit.py -v`
Expected: 4 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/app/matches/router.py backend/app/main.py backend/tests/integration/test_matches_submit.py
git commit -m "feat(backend): POST /matches + GET /matches/{id}"
```

---

## Task 21: Confirm match — service + endpoint + rating update

**Files:**
- Modify: `backend/app/matches/service.py` (add `confirm_match`)
- Modify: `backend/app/matches/router.py` (add confirm endpoint)
- Create: `backend/tests/integration/test_matches_confirm.py`

- [ ] **Step 1: Append `confirm_match` to `app/matches/service.py`**

```python
from app.rating.service import apply_match_rating
from app.matches.validators import match_winner


async def confirm_match(
    session: AsyncSession, ident: FirebaseIdentity, match_id: uuid.UUID
) -> Match:
    me = await get_by_firebase_uid(session, ident.uid)
    if not me:
        raise NotFound("player not found", code="player_not_found")

    match = await load_match(session, match_id)
    if match.status not in ("pending",):
        raise Conflict(f"match is {match.status}", code="not_pending")

    parts = await load_participants(session, match.id)
    my_row = next((mp for mp, p in parts if p.id == me.id), None)
    if my_row is None:
        raise Forbidden("not a participant", code="not_a_participant")

    submitter_team = next(mp.team for mp, p in parts if mp.is_submitter)
    if my_row.team == submitter_team:
        # Same-team confirmation just records the timestamp; doesn't validate.
        my_row.confirmed_at = my_row.confirmed_at or datetime.now(UTC)
        await session.commit()
        return match

    my_row.confirmed_at = my_row.confirmed_at or datetime.now(UTC)

    games_rows = await load_games(session, match.id)
    games = [(g.team1_points, g.team2_points) for g in games_rows]
    winning_team = match_winner(games)

    match.status = "validated"
    match.validated_at = datetime.now(UTC)
    await apply_match_rating(session, match, winning_team)
    await session.commit()

    # Push to all participants.
    for mp, p in parts:
        await fcm.send_to_uid(
            p.firebase_uid,
            title="Match validated",
            body="Your rating has been updated.",
            data={"match_id": str(match.id), "kind": "match_validated"},
        )

    return match
```

- [ ] **Step 2: Add confirm endpoint to `app/matches/router.py`**

Append:

```python
@router.post("/{match_id}/confirm", response_model=MatchOut)
async def confirm(match_id: uuid.UUID, session: DbSession,
                  ident: CurrentIdentity) -> MatchOut:
    m = await service.confirm_match(session, ident, match_id)
    return await _serialize(session, m)
```

- [ ] **Step 3: Write `tests/integration/test_matches_confirm.py`**

```python
from datetime import UTC, datetime
from httpx import ASGITransport, AsyncClient
from app.db.base import Base
from app.main import create_app


async def _client(engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return AsyncClient(transport=ASGITransport(app=create_app()), base_url="http://t")


def _h(uid, phone):
    return {"Authorization": f"Bearer dev:{uid}:{phone}"}


async def _signup(ac, uid, phone, name="P"):
    return await ac.post("/players", json={"display_name": name},
                          headers=_h(uid, phone))


async def test_opposing_confirm_validates_and_updates_ratings(engine):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        await _signup(ac, "uC1", "+91980030C001", "Alice")
        await _signup(ac, "uC2", "+91980030C002", "Bob")

        body = {
            "format": "S",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980030C001"],
            "team2_phones": ["+91980030C002"],
            "games": [
                {"game_no": 1, "team1_points": 21, "team2_points": 18},
                {"game_no": 2, "team1_points": 21, "team2_points": 12},
            ],
        }
        r = await ac.post("/matches", json=body, headers=_h("uC1", "+91980030C001"))
        match_id = r.json()["id"]

        r2 = await ac.post(f"/matches/{match_id}/confirm",
                            headers=_h("uC2", "+91980030C002"))
        assert r2.status_code == 200
        m = r2.json()
        assert m["status"] == "validated"
        # Two rating deltas, Alice up, Bob down.
        deltas = m["rating_deltas"]
        assert len(deltas) == 2
        before = {d["player_id"]: d["rating_before"] for d in deltas}
        after = {d["player_id"]: d["rating_after"] for d in deltas}
        assert all(v == 3.5 for v in before.values())
        # One after > 3.5, one < 3.5.
        assert sum(1 for v in after.values() if v > 3.5) == 1
        assert sum(1 for v in after.values() if v < 3.5) == 1


async def test_confirm_by_non_participant_forbidden(engine):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        await _signup(ac, "uC3", "+91980030C003", "A")
        await _signup(ac, "uC4", "+91980030C004", "B")
        await _signup(ac, "uC5", "+91980030C005", "C")

        body = {
            "format": "S",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980030C003"],
            "team2_phones": ["+91980030C004"],
            "games": [{"game_no": 1, "team1_points": 21, "team2_points": 10}],
        }
        r = await ac.post("/matches", json=body, headers=_h("uC3", "+91980030C003"))
        mid = r.json()["id"]
        r2 = await ac.post(f"/matches/{mid}/confirm",
                            headers=_h("uC5", "+91980030C005"))
        assert r2.status_code == 403


async def test_confirm_by_same_team_does_not_validate(engine):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        # Doubles to give same-team scenario.
        names = ["A", "B", "C", "D"]
        for i, n in enumerate(names):
            await _signup(ac, f"uD{i}", f"+9198003D00{i}", n)

        body = {
            "format": "D",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+9198003D000", "+9198003D001"],
            "team2_phones": ["+9198003D002", "+9198003D003"],
            "games": [{"game_no": 1, "team1_points": 21, "team2_points": 15}],
        }
        r = await ac.post("/matches", json=body, headers=_h("uD0", "+9198003D000"))
        mid = r.json()["id"]
        # Submitter's teammate confirms — does not validate.
        r2 = await ac.post(f"/matches/{mid}/confirm",
                            headers=_h("uD1", "+9198003D001"))
        assert r2.status_code == 200
        assert r2.json()["status"] == "pending"
```

- [ ] **Step 4: Run tests, expect PASS**

Run: `pytest tests/integration/test_matches_confirm.py -v`
Expected: 3 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/app/matches/service.py backend/app/matches/router.py backend/tests/integration/test_matches_confirm.py
git commit -m "feat(backend): confirm match + rating update on validation"
```

---

## Task 22: Dispute match — rollback rating events

**Files:**
- Modify: `backend/app/matches/service.py` (add `dispute_match`)
- Modify: `backend/app/matches/router.py` (add dispute endpoint)
- Create: `backend/tests/integration/test_matches_dispute.py`

- [ ] **Step 1: Append to `app/matches/service.py`**

```python
async def dispute_match(
    session: AsyncSession, ident: FirebaseIdentity, match_id: uuid.UUID
) -> Match:
    from app.db.models import RatingEvent, PlayerRating
    from sqlalchemy import delete

    me = await get_by_firebase_uid(session, ident.uid)
    if not me:
        raise NotFound("player not found", code="player_not_found")

    match = await load_match(session, match_id)
    if match.status == "disputed":
        return match
    if match.status not in ("pending", "validated"):
        raise Conflict(f"cannot dispute {match.status} match", code="cannot_dispute")

    parts = await load_participants(session, match.id)
    my_row = next((mp for mp, p in parts if p.id == me.id), None)
    if my_row is None:
        raise Forbidden("not a participant", code="not_a_participant")

    if match.status == "validated":
        # Reverse rating_events for this match.
        events_res = await session.execute(
            select(RatingEvent).where(RatingEvent.match_id == match.id)
        )
        events = list(events_res.scalars().all())
        for ev in events:
            res = await session.execute(
                select(PlayerRating).where(
                    (PlayerRating.player_id == ev.player_id)
                    & (PlayerRating.format == ev.format)
                )
            )
            pr = res.scalar_one()
            delta = ev.rating_after - ev.rating_before
            rd_delta = ev.rd_after - ev.rd_before
            pr.rating = pr.rating - delta
            pr.rd = pr.rd - rd_delta
            pr.matches_played = max(0, pr.matches_played - 1)
        await session.execute(
            delete(RatingEvent).where(RatingEvent.match_id == match.id)
        )

    my_row.disputed_at = datetime.now(UTC)
    match.status = "disputed"
    await session.commit()
    return match
```

- [ ] **Step 2: Add endpoint to `app/matches/router.py`**

Append:

```python
@router.post("/{match_id}/dispute", response_model=MatchOut)
async def dispute(match_id: uuid.UUID, session: DbSession,
                  ident: CurrentIdentity) -> MatchOut:
    m = await service.dispute_match(session, ident, match_id)
    return await _serialize(session, m)
```

- [ ] **Step 3: Write `tests/integration/test_matches_dispute.py`**

```python
from datetime import UTC, datetime
from httpx import ASGITransport, AsyncClient
from app.db.base import Base
from app.main import create_app


async def _client(engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return AsyncClient(transport=ASGITransport(app=create_app()), base_url="http://t")


def _h(uid, phone):
    return {"Authorization": f"Bearer dev:{uid}:{phone}"}


async def _signup(ac, uid, phone, name="P"):
    return await ac.post("/players", json={"display_name": name},
                          headers=_h(uid, phone))


async def test_dispute_pending_just_marks(engine):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        await _signup(ac, "uX1", "+91980040X001")
        await _signup(ac, "uX2", "+91980040X002")
        body = {
            "format": "S",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980040X001"],
            "team2_phones": ["+91980040X002"],
            "games": [{"game_no": 1, "team1_points": 21, "team2_points": 10}],
        }
        r = await ac.post("/matches", json=body, headers=_h("uX1", "+91980040X001"))
        mid = r.json()["id"]
        d = await ac.post(f"/matches/{mid}/dispute", headers=_h("uX2", "+91980040X002"))
        assert d.status_code == 200
        assert d.json()["status"] == "disputed"


async def test_dispute_validated_rolls_back_ratings(engine):
    from app.config import settings
    settings.env = "dev"
    async with await _client(engine) as ac:
        await _signup(ac, "uX3", "+91980040X003", "Alice")
        await _signup(ac, "uX4", "+91980040X004", "Bob")
        body = {
            "format": "S",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980040X003"],
            "team2_phones": ["+91980040X004"],
            "games": [{"game_no": 1, "team1_points": 21, "team2_points": 12},
                      {"game_no": 2, "team1_points": 21, "team2_points": 15}],
        }
        r = await ac.post("/matches", json=body, headers=_h("uX3", "+91980040X003"))
        mid = r.json()["id"]
        await ac.post(f"/matches/{mid}/confirm", headers=_h("uX4", "+91980040X004"))

        me_alice = (await ac.get("/players/me", headers=_h("uX3", "+91980040X003"))).json()
        alice_after_validate = next(r["rating"] for r in me_alice["ratings"] if r["format"] == "S")
        assert alice_after_validate > 3.5

        await ac.post(f"/matches/{mid}/dispute", headers=_h("uX4", "+91980040X004"))

        me_alice2 = (await ac.get("/players/me", headers=_h("uX3", "+91980040X003"))).json()
        alice_after_dispute = next(r["rating"] for r in me_alice2["ratings"] if r["format"] == "S")
        assert abs(alice_after_dispute - 3.5) < 1e-6
```

- [ ] **Step 4: Run tests, expect PASS**

Run: `pytest tests/integration/test_matches_dispute.py -v`
Expected: 2 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/app/matches/service.py backend/app/matches/router.py backend/tests/integration/test_matches_dispute.py
git commit -m "feat(backend): dispute match with rating rollback"
```

---

## Task 23: Expire-matches internal endpoint

**Files:**
- Create: `backend/app/internal/__init__.py` (empty)
- Create: `backend/app/internal/router.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/integration/test_matches_expire.py`

The endpoint is invoked by Cloud Scheduler every 10 minutes. It finds
pending matches past their deadline and validates them.

- [ ] **Step 1: Implement `app/internal/router.py`**

```python
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
            # Malformed scores — leave as pending; admin will handle.
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
```

- [ ] **Step 2: Mount in `app/main.py`**

Update the import block + include:

```python
from app.internal.router import router as internal_router
# ...
    app.include_router(internal_router)
```

The final `app/main.py`:

```python
from fastapi import FastAPI
from app.deps import CurrentIdentity
from app.errors import install_handlers
from app.internal.router import router as internal_router
from app.matches.router import router as matches_router
from app.players.router import router as players_router


def create_app() -> FastAPI:
    app = FastAPI(title="Rally API", version="0.1.0")
    install_handlers(app)
    app.include_router(players_router)
    app.include_router(matches_router)
    app.include_router(internal_router)

    @app.get("/healthz")
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/_debug/identity")
    async def debug_identity(ident: CurrentIdentity) -> dict[str, str]:
        return {"uid": ident.uid, "phone_e164": ident.phone_e164}

    return app

app = create_app()
```

- [ ] **Step 3: Write `tests/integration/test_matches_expire.py`**

```python
from datetime import UTC, datetime, timedelta
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select, update
from app.config import settings
from app.db.base import Base
from app.db.models import Match
from app.main import create_app


async def _client(engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return AsyncClient(transport=ASGITransport(app=create_app()), base_url="http://t")


def _h(uid, phone):
    return {"Authorization": f"Bearer dev:{uid}:{phone}"}


async def _signup(ac, uid, phone, name="P"):
    return await ac.post("/players", json={"display_name": name},
                          headers=_h(uid, phone))


async def test_expire_validates_old_pending(engine, session):
    settings.env = "dev"
    async with await _client(engine) as ac:
        await _signup(ac, "uE1", "+91980050E001", "Alice")
        await _signup(ac, "uE2", "+91980050E002", "Bob")
        body = {
            "format": "S",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980050E001"],
            "team2_phones": ["+91980050E002"],
            "games": [{"game_no": 1, "team1_points": 21, "team2_points": 12}],
        }
        r = await ac.post("/matches", json=body, headers=_h("uE1", "+91980050E001"))
        mid = r.json()["id"]

        # Backdate the deadline.
        await session.execute(
            update(Match).where(Match.id == r.json()["id"])
            .values(validation_deadline=datetime.now(UTC) - timedelta(minutes=1))
        )
        await session.commit()

        r2 = await ac.post(
            "/internal/expire-matches",
            headers={"X-Internal-Secret": settings.internal_secret},
        )
        assert r2.status_code == 200
        assert r2.json()["validated"] >= 1

        m = (await ac.get(f"/matches/{mid}", headers=_h("uE1", "+91980050E001"))).json()
        assert m["status"] == "validated"


async def test_expire_rejects_bad_secret(engine):
    settings.env = "dev"
    async with await _client(engine) as ac:
        r = await ac.post("/internal/expire-matches",
                          headers={"X-Internal-Secret": "wrong"})
        assert r.status_code == 401
```

- [ ] **Step 4: Run tests, expect PASS**

Run: `pytest tests/integration/test_matches_expire.py -v`
Expected: 2 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/app/internal/ backend/app/main.py backend/tests/integration/test_matches_expire.py
git commit -m "feat(backend): /internal/expire-matches"
```

---

## Task 24: Leaderboard endpoint

**Files:**
- Create: `backend/app/leaderboard/__init__.py` (empty)
- Create: `backend/app/leaderboard/router.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/integration/test_leaderboard.py`

Query: players with `home_city='BLR'`, joined to `player_ratings` filtered by
format, with `matches_played >= 5`, ordered by rating desc, limit N.
Optional `gender` filter.

- [ ] **Step 1: Implement `app/leaderboard/router.py`**

```python
from __future__ import annotations
from typing import Literal
from fastapi import APIRouter, Query
from pydantic import BaseModel
from sqlalchemy import select

from app.db.models import Player, PlayerRating
from app.deps import CurrentIdentity, DbSession

router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])

MIN_MATCHES = 5


class LeaderboardEntry(BaseModel):
    rank: int
    player_id: str
    display_name: str
    rating: float
    matches_played: int


class LeaderboardResponse(BaseModel):
    format: str
    city: str
    gender: str
    entries: list[LeaderboardEntry]


@router.get("", response_model=LeaderboardResponse)
async def get_leaderboard(
    session: DbSession,
    _ident: CurrentIdentity,
    format: Literal["S", "D"] = Query("S"),
    gender: Literal["All", "M", "F"] = Query("All"),
    limit: int = Query(100, ge=1, le=500),
    city: str = Query("BLR"),
) -> LeaderboardResponse:
    stmt = (
        select(Player.id, Player.display_name, PlayerRating.rating,
               PlayerRating.matches_played)
        .join(PlayerRating, PlayerRating.player_id == Player.id)
        .where(
            (PlayerRating.format == format)
            & (Player.home_city == city)
            & (PlayerRating.matches_played >= MIN_MATCHES)
        )
        .order_by(PlayerRating.rating.desc())
        .limit(limit)
    )
    if gender in ("M", "F"):
        stmt = stmt.where(Player.gender == gender)

    rows = (await session.execute(stmt)).all()
    entries = [
        LeaderboardEntry(
            rank=i + 1,
            player_id=str(pid),
            display_name=name,
            rating=rating,
            matches_played=mp,
        )
        for i, (pid, name, rating, mp) in enumerate(rows)
    ]
    return LeaderboardResponse(format=format, city=city, gender=gender, entries=entries)
```

- [ ] **Step 2: Mount in `app/main.py`**

```python
from app.leaderboard.router import router as leaderboard_router
# ...
    app.include_router(leaderboard_router)
```

Updated `app/main.py`:

```python
from fastapi import FastAPI
from app.deps import CurrentIdentity
from app.errors import install_handlers
from app.internal.router import router as internal_router
from app.leaderboard.router import router as leaderboard_router
from app.matches.router import router as matches_router
from app.players.router import router as players_router


def create_app() -> FastAPI:
    app = FastAPI(title="Rally API", version="0.1.0")
    install_handlers(app)
    app.include_router(players_router)
    app.include_router(matches_router)
    app.include_router(leaderboard_router)
    app.include_router(internal_router)

    @app.get("/healthz")
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/_debug/identity")
    async def debug_identity(ident: CurrentIdentity) -> dict[str, str]:
        return {"uid": ident.uid, "phone_e164": ident.phone_e164}

    return app

app = create_app()
```

- [ ] **Step 3: Write `tests/integration/test_leaderboard.py`**

```python
from datetime import UTC, datetime
from httpx import ASGITransport, AsyncClient
from sqlalchemy import update
from app.config import settings
from app.db.base import Base
from app.db.models import PlayerRating
from app.main import create_app


async def _client(engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return AsyncClient(transport=ASGITransport(app=create_app()), base_url="http://t")


def _h(uid, phone):
    return {"Authorization": f"Bearer dev:{uid}:{phone}"}


async def test_leaderboard_excludes_under_minimum_matches(engine, session):
    settings.env = "dev"
    async with await _client(engine) as ac:
        await ac.post("/players", json={"display_name": "Alice"},
                      headers=_h("uL1", "+91980060L001"))
        # Manually bump her matches_played and rating in DB to qualify.
        await session.execute(
            update(PlayerRating)
            .where(PlayerRating.format == "S")
            .values(matches_played=5, rating=4.2)
        )
        await session.commit()

        r = await ac.get("/leaderboard?format=S",
                         headers=_h("uL1", "+91980060L001"))
        assert r.status_code == 200
        entries = r.json()["entries"]
        assert len(entries) == 1
        assert entries[0]["rank"] == 1
        assert entries[0]["rating"] == 4.2


async def test_leaderboard_gender_filter(engine, session):
    settings.env = "dev"
    async with await _client(engine) as ac:
        await ac.post("/players", json={"display_name": "A", "gender": "M"},
                      headers=_h("uL2", "+91980060L002"))
        await ac.post("/players", json={"display_name": "B", "gender": "F"},
                      headers=_h("uL3", "+91980060L003"))
        await session.execute(
            update(PlayerRating)
            .where(PlayerRating.format == "S")
            .values(matches_played=5, rating=4.0)
        )
        await session.commit()

        r_all = await ac.get("/leaderboard?format=S&gender=All",
                              headers=_h("uL2", "+91980060L002"))
        r_m = await ac.get("/leaderboard?format=S&gender=M",
                            headers=_h("uL2", "+91980060L002"))
        assert len(r_all.json()["entries"]) >= 2
        assert all(True for _ in r_m.json()["entries"])
        assert len(r_m.json()["entries"]) == 1
```

- [ ] **Step 4: Run tests, expect PASS**

Run: `pytest tests/integration/test_leaderboard.py -v`
Expected: 2 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/app/leaderboard/ backend/app/main.py backend/tests/integration/test_leaderboard.py
git commit -m "feat(backend): GET /leaderboard"
```

---

## Task 25: My matches + rating history endpoints

**Files:**
- Modify: `backend/app/players/router.py` (add 2 endpoints)
- Modify: `backend/app/players/service.py` (add helpers)
- Create: `backend/tests/integration/test_players_extras.py`

- [ ] **Step 1: Append to `app/players/service.py`**

```python
from datetime import datetime, timedelta, UTC
from app.db.models import Match, MatchParticipant, RatingEvent

async def list_my_matches(
    session: AsyncSession, player_id: uuid.UUID, status: str | None = None
) -> list[Match]:
    stmt = (
        select(Match)
        .join(MatchParticipant, MatchParticipant.match_id == Match.id)
        .where(MatchParticipant.player_id == player_id)
        .order_by(Match.played_at.desc())
    )
    if status:
        stmt = stmt.where(Match.status == status)
    res = await session.execute(stmt)
    return list(res.scalars().all())


async def rating_history(
    session: AsyncSession, player_id: uuid.UUID, days: int = 90
) -> list[RatingEvent]:
    since = datetime.now(UTC) - timedelta(days=days)
    res = await session.execute(
        select(RatingEvent)
        .where(
            (RatingEvent.player_id == player_id)
            & (RatingEvent.created_at >= since)
        )
        .order_by(RatingEvent.created_at.asc())
    )
    return list(res.scalars().all())
```

- [ ] **Step 2: Append to `app/players/router.py`**

```python
from datetime import datetime
from pydantic import BaseModel
from app.matches.router import _serialize as _serialize_match
from app.matches.schemas import MatchOut


class RatingHistoryPoint(BaseModel):
    match_id: str
    format: str
    rating_after: float
    created_at: datetime


@router.get("/me/matches", response_model=list[MatchOut])
async def my_matches(session: DbSession, ident: CurrentIdentity,
                     status: str | None = None) -> list[MatchOut]:
    me = await service.get_me_or_404(session, ident)
    matches = await service.list_my_matches(session, me.id, status)
    return [await _serialize_match(session, m) for m in matches]


@router.get("/me/rating-history", response_model=list[RatingHistoryPoint])
async def my_rating_history(session: DbSession, ident: CurrentIdentity,
                            days: int = 90) -> list[RatingHistoryPoint]:
    me = await service.get_me_or_404(session, ident)
    events = await service.rating_history(session, me.id, days)
    return [RatingHistoryPoint(
        match_id=str(e.match_id),
        format=e.format,
        rating_after=e.rating_after,
        created_at=e.created_at,
    ) for e in events]
```

- [ ] **Step 3: Write `tests/integration/test_players_extras.py`**

```python
from datetime import UTC, datetime
from httpx import ASGITransport, AsyncClient
from app.config import settings
from app.db.base import Base
from app.main import create_app


async def _client(engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return AsyncClient(transport=ASGITransport(app=create_app()), base_url="http://t")


def _h(uid, phone):
    return {"Authorization": f"Bearer dev:{uid}:{phone}"}


async def test_my_matches_and_rating_history(engine):
    settings.env = "dev"
    async with await _client(engine) as ac:
        await ac.post("/players", json={"display_name": "A"},
                      headers=_h("uH1", "+91980070H001"))
        await ac.post("/players", json={"display_name": "B"},
                      headers=_h("uH2", "+91980070H002"))
        body = {
            "format": "S",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980070H001"],
            "team2_phones": ["+91980070H002"],
            "games": [{"game_no": 1, "team1_points": 21, "team2_points": 12}],
        }
        r = await ac.post("/matches", json=body, headers=_h("uH1", "+91980070H001"))
        mid = r.json()["id"]
        await ac.post(f"/matches/{mid}/confirm", headers=_h("uH2", "+91980070H002"))

        mm = await ac.get("/players/me/matches", headers=_h("uH1", "+91980070H001"))
        assert mm.status_code == 200
        assert len(mm.json()) == 1
        assert mm.json()[0]["status"] == "validated"

        rh = await ac.get("/players/me/rating-history", headers=_h("uH1", "+91980070H001"))
        assert rh.status_code == 200
        events = rh.json()
        assert len(events) == 1
        assert events[0]["format"] == "S"
```

- [ ] **Step 4: Run tests, expect PASS**

Run: `pytest tests/integration/test_players_extras.py -v`
Expected: 1 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/app/players/ backend/tests/integration/test_players_extras.py
git commit -m "feat(backend): GET /players/me/matches + /rating-history"
```

---

## Task 26: Dockerfile + end-to-end smoke test

**Files:**
- Create: `backend/Dockerfile`
- Modify: `backend/docker-compose.yml`
- Create: `backend/tests/integration/test_full_suite.py`

- [ ] **Step 1: Create `backend/Dockerfile`**

```dockerfile
FROM python:3.12-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
RUN pip install --no-cache-dir -e ".[dev]"

COPY app ./app
COPY alembic ./alembic
COPY alembic.ini ./

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 2: Add API service to `docker-compose.yml`**

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: rally
      POSTGRES_PASSWORD: rally
      POSTGRES_DB: rally
    ports:
      - "5432:5432"
    volumes:
      - rally_pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U rally -d rally"]
      interval: 2s
      timeout: 5s
      retries: 10

  api:
    build: .
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql+asyncpg://rally:rally@postgres:5432/rally
      ENV: dev
      INTERNAL_SECRET: dev-internal-secret-change-me
    ports:
      - "8000:8000"
    command: >
      sh -c "alembic upgrade head &&
             uvicorn app.main:app --host 0.0.0.0 --port 8000"

volumes:
  rally_pg:
```

- [ ] **Step 3: Write `tests/integration/test_full_suite.py`**

This is the round-trip test that exercises every endpoint in order.

```python
from datetime import UTC, datetime
from httpx import ASGITransport, AsyncClient
from app.config import settings
from app.db.base import Base
from app.main import create_app


def _h(uid, phone):
    return {"Authorization": f"Bearer dev:{uid}:{phone}"}


async def test_full_match_lifecycle(engine):
    settings.env = "dev"
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncClient(transport=ASGITransport(app=create_app()),
                            base_url="http://t") as ac:
        # 1. signup
        for i, phone in enumerate([
            "+91980080F001", "+91980080F002", "+91980080F003", "+91980080F004",
        ]):
            r = await ac.post("/players",
                              json={"display_name": f"P{i}", "gender": "M"},
                              headers=_h(f"uF{i}", phone))
            assert r.status_code == 201

        # 2. submit doubles match
        body = {
            "format": "D",
            "played_at": datetime.now(UTC).isoformat(),
            "team1_phones": ["+91980080F001", "+91980080F002"],
            "team2_phones": ["+91980080F003", "+91980080F004"],
            "games": [
                {"game_no": 1, "team1_points": 21, "team2_points": 18},
                {"game_no": 2, "team1_points": 19, "team2_points": 21},
                {"game_no": 3, "team1_points": 21, "team2_points": 17},
            ],
        }
        r = await ac.post("/matches", json=body, headers=_h("uF0", "+91980080F001"))
        assert r.status_code == 201
        mid = r.json()["id"]

        # 3. opponent confirms → validated, ratings updated
        r2 = await ac.post(f"/matches/{mid}/confirm",
                          headers=_h("uF2", "+91980080F003"))
        assert r2.status_code == 200
        assert r2.json()["status"] == "validated"

        # 4. leaderboard requires 5 matches; we just check the endpoint runs
        lb = await ac.get("/leaderboard?format=D",
                          headers=_h("uF0", "+91980080F001"))
        assert lb.status_code == 200

        # 5. rating history present for all 4
        for i, phone in enumerate([
            "+91980080F001", "+91980080F002", "+91980080F003", "+91980080F004",
        ]):
            rh = await ac.get("/players/me/rating-history",
                              headers=_h(f"uF{i}", phone))
            assert rh.status_code == 200
            assert len(rh.json()) == 1
```

- [ ] **Step 4: Run all tests, expect PASS**

Run: `pytest -x --tb=short`
Expected: full suite green.

- [ ] **Step 5: Commit**

```bash
git add backend/Dockerfile backend/docker-compose.yml backend/tests/integration/test_full_suite.py
git commit -m "feat(backend): Dockerfile + full lifecycle integration test"
```

---

## Task 27: Final tidy — lint, types, README polish

**Files:**
- Modify: `backend/README.md`

- [ ] **Step 1: Run formatter and linter**

Run: `cd backend && make fmt && make lint`
Expected: clean exit.

- [ ] **Step 2: Run mypy**

Run: `make type`
Expected: clean exit. Fix any complaints inline; common ones are missing
return annotations on test functions (annotate as `-> None`).

- [ ] **Step 3: Update `backend/README.md` to reflect the final API surface**

```markdown
# Rally Backend

FastAPI service for the Rally badminton-rating MVP.

## Quickstart

```bash
cd backend
uv venv && source .venv/bin/activate
make install
cp .env.example .env
docker compose up -d postgres
make migrate
make run
```

API runs on http://localhost:8000. Healthcheck: `GET /healthz`.

## Endpoints

| Method | Path                              | Description                          |
|-------:|-----------------------------------|--------------------------------------|
| POST   | /players                          | Create the current user's profile    |
| GET    | /players/me                       | My profile + ratings                 |
| PATCH  | /players/me                       | Update my profile                    |
| GET    | /players/me/matches               | My matches (filter by status)        |
| GET    | /players/me/rating-history        | My rating events                     |
| POST   | /matches                          | Submit a match                       |
| GET    | /matches/{id}                     | Match detail                         |
| POST   | /matches/{id}/confirm             | Confirm participation                |
| POST   | /matches/{id}/dispute             | Dispute a match                      |
| GET    | /leaderboard                      | Bangalore city leaderboard           |
| POST   | /internal/expire-matches          | Cron-only; shared-secret auth        |
| GET    | /healthz                          | Liveness                             |

## Auth

All endpoints except `/healthz` and `/internal/*` require a Firebase ID
token: `Authorization: Bearer <jwt>`. In `ENV=dev`, you can use the shortcut
`Authorization: Bearer dev:<uid>:<phone_e164>` for testing.

## Tests

`make test` runs the full suite. Integration tests use testcontainers — Docker
must be running.
```

- [ ] **Step 4: Commit**

```bash
git add backend/README.md
git commit -m "docs(backend): finalize README with endpoint table"
```

---

## Done criteria for Plan 1

- All 27 tasks complete.
- `make test` passes locally.
- `docker compose up` produces a working API on `:8000` with healthcheck OK.
- A doubles match can be submitted via cURL with a `dev:` token, confirmed by
  an opposing player, and ratings update on both teams with the carry-weight
  effect visible.

Once this plan is green, Plan 2 (Flutter app) and Plan 3 (GCP deploy +
Firebase wiring + SMS provider) follow.
