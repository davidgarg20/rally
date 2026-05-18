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
