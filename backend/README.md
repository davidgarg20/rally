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
token: `Authorization: Bearer <jwt>`. In `ENV=dev`, use the shortcut
`Authorization: Bearer dev:<uid>:<phone_e164>` for testing.

## Tests

`make test` runs the full suite. Integration tests use testcontainers — Docker
must be running.
