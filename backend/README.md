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
