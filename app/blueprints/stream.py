"""Streaming endpoints (MJPEG + SSE)."""
from __future__ import annotations

import json
import time
from typing import Any, Dict

from flask import Blueprint, Response, current_app, stream_with_context

from app.utils.auth import require_api_key

stream_bp = Blueprint("stream", __name__, url_prefix="/stream")


def _svc(name: str) -> Any:
    return current_app.extensions[name]


def _format_sse(event: Dict[str, Any]) -> str:
    data = json.dumps(event)
    return f"data: {data}\n\n"


@stream_bp.get("/events")
@require_api_key
def events() -> Response:
    state_service = _svc("state_service")
    listener = state_service.add_listener()

    @stream_with_context
    def generate():
        try:
            for event in state_service.history():
                yield _format_sse(event)
            while True:
                event = listener.get()
                yield _format_sse(event)
        finally:
            state_service.remove_listener(listener)

    return Response(generate(), mimetype="text/event-stream")


@stream_bp.get("/camera/<name>")
@require_api_key
def camera(name: str) -> Response:
    camera_service = _svc("camera_service")
    try:
        camera_service.ensure_started(name)
    except KeyError:
        return Response("Unknown camera", status=404)
    except RuntimeError as exc:
        return Response(str(exc), status=500)

    boundary = "frame"

    @stream_with_context
    def generate():
        while True:
            frame = camera_service.frame(name)
            if frame is None:
                time.sleep(0.05)
                continue
            chunk = (
                f"--{boundary}\r\n"
                f"Content-Type: image/jpeg\r\n"
                f"Content-Length: {len(frame)}\r\n\r\n"
            ).encode("ascii") + frame + b"\r\n"
            yield chunk
            time.sleep(0.02)

    headers = {"Cache-Control": "no-cache", "Pragma": "no-cache"}
    return Response(generate(), mimetype=f"multipart/x-mixed-replace; boundary={boundary}", headers=headers)
