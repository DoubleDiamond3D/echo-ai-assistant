#!/usr/bin/env python3
"""Fixed face renderer that properly handles SDL driver selection."""
from __future__ import annotations

import json
import math
import os
import time
from pathlib import Path

# IMPORTANT: Set SDL driver BEFORE importing pygame
preferred_driver = os.environ.get("SDL_VIDEODRIVER", "fbcon")
os.environ['SDL_VIDEODRIVER'] = preferred_driver
print(f"🎮 Forcing SDL driver to: {preferred_driver}")

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

    print(f"🔧 Environment SDL_VIDEODRIVER: {os.environ.get('SDL_VIDEODRIVER', 'not set')}")
    print(f"🔧 Environment SDL_FBDEV: {os.environ.get('SDL_FBDEV', 'not set')}")
    print(f"🔧 Environment XDG_RUNTIME_DIR: {os.environ.get('XDG_RUNTIME_DIR', 'not set')}")

    # Initialize pygame with error handling
    try:
        pygame.init()
        print("✅ Pygame initialized successfully")
        
        # Show what driver pygame is actually using
        driver = pygame.display.get_driver()
        print(f"🎮 Pygame is using SDL driver: {driver}")
        
    except Exception as e:
        print(f"❌ Failed to initialize pygame: {e}")
        return

    # Try to set display mode
    fullscreen = os.environ.get("ECHO_FACE_FULLSCREEN", "0") == "1"
    size = (800, 480)
    
    try:
        if fullscreen:
            screen = pygame.display.set_mode(size, pygame.FULLSCREEN)
            print(f"✅ Fullscreen display mode set: {size}")
        else:
            screen = pygame.display.set_mode(size)
            print(f"✅ Windowed display mode set: {size}")
    except Exception as e:
        print(f"❌ Failed to set display mode: {e}")
        print("🔧 Trying smaller resolution...")
        try:
            screen = pygame.display.set_mode((640, 480))
            print("✅ Fallback display mode set: (640, 480)")
        except Exception as e2:
            print(f"❌ Fallback also failed: {e2}")
            pygame.quit()
            return
    
    pygame.display.set_caption("Project Echo Face (Fixed)")
    clock = pygame.time.Clock()

    running = True
    frame_count = 0
    
    print("🚀 Starting face renderer main loop...")
    
    try:
        while running:
            now = time.time()
            
            # Handle events
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
            
            # Update state every 10 frames
            if frame_count % 10 == 0:
                state = load_state(state_path)
                current_mood = state.get("state", "idle")
            else:
                current_mood = "idle"
            
            # Draw the face
            draw_face(screen, current_mood, now)
            pygame.display.flip()
            
            # Limit to 30 FPS
            clock.tick(30)
            frame_count += 1
            
            # Safety timeout after 1 hour
            if frame_count > 30 * 60 * 60:
                print("⏰ Safety timeout reached. Exiting...")
                running = False
                
    except Exception as e:
        print(f"❌ Error in main loop: {e}")
    finally:
        print("🧹 Cleaning up pygame...")
        pygame.quit()


if __name__ == "__main__":
    main()