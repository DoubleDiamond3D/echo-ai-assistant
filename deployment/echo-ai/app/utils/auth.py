"""API key helpers."""
from __future__ import annotations

from functools import wraps
from typing import Callable, TypeVar

from flask import Response, current_app, request

F = TypeVar("F", bound=Callable)


def require_api_key(func: F) -> F:
    @wraps(func)
    def wrapper(*args, **kwargs):
        settings = current_app.config.get("settings")
        token = getattr(settings, "api_token", "")
        if token and token != "change-me":
            provided = request.headers.get("X-API-Key") or request.args.get("api_key")
            if not provided or provided != token:
                return Response("Forbidden", status=403)
        return func(*args, **kwargs)

    return wrapper  # type: ignore[return-value]
