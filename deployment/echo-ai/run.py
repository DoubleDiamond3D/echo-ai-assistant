#!/usr/bin/env python3
"""Development entrypoint for Project Echo."""
from __future__ import annotations

from app import create_app

app = create_app()

if __name__ == "__main__":
    settings = app.config["settings"]
    app.run(host=settings.host, port=settings.port, debug=settings.debug, threaded=True)
