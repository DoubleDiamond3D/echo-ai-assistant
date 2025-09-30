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


def load_wallpaper(surface: pygame.Surface) -> pygame.Surface | None:
    """Load wallpaper if it exists"""
    wallpaper_path = "/opt/echo-ai/wallpapers/wallpaper.jpg"
    video_path = "/opt/echo-ai/wallpapers/wallpaper.mp4"
    
    # Try image first
    if os.path.exists(wallpaper_path):
        try:
            wallpaper = pygame.image.load(wallpaper_path)
            # Scale to fit screen while maintaining aspect ratio
            screen_width, screen_height = surface.get_size()
            wallpaper_width, wallpaper_height = wallpaper.get_size()
            
            # Calculate scale to fill screen
            scale_x = screen_width / wallpaper_width
            scale_y = screen_height / wallpaper_height
            scale = max(scale_x, scale_y)  # Use max to fill screen
            
            new_width = int(wallpaper_width * scale)
            new_height = int(wallpaper_height * scale)
            wallpaper = pygame.transform.scale(wallpaper, (new_width, new_height))
            
            return wallpaper
        except Exception as e:
            print(f"Error loading wallpaper image: {e}")
    
    # Try video if image doesn't exist
    elif os.path.exists(video_path):
        try:
            # For video, we'll just return a placeholder for now
            # In a full implementation, you'd use pygame.movie or similar
            print("Video wallpaper detected but not implemented yet")
        except Exception as e:
            print(f"Error loading wallpaper video: {e}")
    
    return None


def draw_face(surface: pygame.Surface, mood: str, timestamp: float) -> None:
    width, height = surface.get_size()
    
    # Try to load and draw wallpaper
    wallpaper = load_wallpaper(surface)
    if wallpaper:
        # Center the wallpaper
        wallpaper_width, wallpaper_height = wallpaper.get_size()
        x = (width - wallpaper_width) // 2
        y = (height - wallpaper_height) // 2
        surface.blit(wallpaper, (x, y))
    else:
        # Default background if no wallpaper
        surface.fill((5, 5, 12))
    
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
