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
