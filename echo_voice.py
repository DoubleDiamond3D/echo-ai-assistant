#!/usr/bin/env python3
"""CLI helper to speak text through the Project Echo speech pipeline."""
from __future__ import annotations

import argparse
import sys
import time

from app import create_app


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Speak text using Project Echo")
    parser.add_argument("text", nargs="?", help="Text to speak")
    parser.add_argument("--voice", dest="voice", help="Override TTS voice")
    args = parser.parse_args(argv)

    text = args.text or "Hello! I am Project Echo."

    app = create_app()
    speech = app.extensions["speech_service"]
    task = speech.enqueue(text=text, voice=args.voice)
    try:
        while True:
            status = speech.status()
            active = status.get("active")
            pending = status.get("pending", [])
            if not active and not pending:
                break
            time.sleep(0.2)
    finally:
        speech.stop()
    print(f"Spoken task {task.id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
