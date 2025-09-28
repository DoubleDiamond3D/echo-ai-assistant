#!/usr/bin/env python3
"""Minimal face renderer driven by the shared state file."""
from __future__ import annotations

import json
import math
import os
import time
from pathlib import Path

import pygame

from app.config import Settings
from app.utils.env import load_first_existing

BASE_DIR = Path(__file__).resolve().parent


def load_state(state_path: Path) -> dict:
    try:
        return json.loads(state_path.read_text(encoding="utf-8"))
    except Exception:
        return {"state": "idle", "last_talk": 0.0, "toggles": {}}


def draw_face(surface: pygame.Surface, mood: str, timestamp: float) -> None:
    surface.fill((5, 5, 12))
    width, height = surface.get_size()
    eye_y = int(height * 0.33)
    eye_dx = int(width * 0.22)
    eye_radius = int(height * 0.12)

    palette = {
        "idle": (0, 170, 255),
        "talking": (0, 220, 255),
        "sleeping": (0, 80, 140),
    }
    color = palette.get(mood, palette["idle"])

    pulse = 0
    if mood == "talking":
        pulse = int(8 * abs(math.sin(timestamp * 6)))
    elif mood == "idle":
        pulse = int(4 * abs(math.sin(timestamp * 3)))

    for direction in (-1, 1):
        center = (width // 2 + direction * eye_dx, eye_y)
        pygame.draw.circle(surface, color, center, eye_radius + pulse, width=4)

    mouth_y = int(height * 0.68)
    mouth_w = int(width * 0.36)
    mouth_h = 60 if mood != "sleeping" else 12
    rect = pygame.Rect(width // 2 - mouth_w // 2, mouth_y - mouth_h // 2, mouth_w, mouth_h)
    start_angle = math.pi * 0.1
    end_angle = math.pi * 0.9
    pygame.draw.arc(surface, (0, 200, 255), rect, start_angle, end_angle, width=6)


def main() -> None:
    load_first_existing([BASE_DIR / ".env", BASE_DIR.parent / ".env"])
    settings = Settings.from_env(BASE_DIR)
    state_path = settings.data_dir / "echo_state.json"
    state_path.parent.mkdir(parents=True, exist_ok=True)

    fullscreen = os.environ.get("ECHO_FACE_FULLSCREEN", "1") == "1"
    pygame.init()
    flags = pygame.FULLSCREEN if fullscreen else 0
    size = (800, 480)
    screen = pygame.display.set_mode(size, flags)
    pygame.display.set_caption("Project Echo Face")
    clock = pygame.time.Clock()

    running = True
    while running:
        now = time.time()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
        state = load_state(state_path)
        draw_face(screen, state.get("state", "idle"), now)
        pygame.display.flip()
        clock.tick(60)

    pygame.quit()


if __name__ == "__main__":
    main()
