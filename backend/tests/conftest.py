import os
from collections.abc import AsyncIterator
import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import NullPool
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="session")
def postgres_container() -> AsyncIterator[PostgresContainer]:
    with PostgresContainer("postgres:16", driver="asyncpg") as pg:
        os.environ["DATABASE_URL"] = pg.get_connection_url()
        yield pg

@pytest_asyncio.fixture(scope="session", loop_scope="session")
async def engine(postgres_container):
    eng = create_async_engine(
        os.environ["DATABASE_URL"],
        future=True,
        poolclass=NullPool,
    )
    yield eng
    await eng.dispose()

@pytest_asyncio.fixture(loop_scope="session")
async def session(engine) -> AsyncIterator[AsyncSession]:
    Session = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    async with Session() as s:
        yield s
        try:
            await s.rollback()
        except Exception:
            pass
