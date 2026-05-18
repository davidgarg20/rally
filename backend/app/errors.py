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
