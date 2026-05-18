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
