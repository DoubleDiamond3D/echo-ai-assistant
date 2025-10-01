#!/usr/bin/env python3
"""Standalone face renderer that avoids app imports until after SDL setup."""
from __future__ import annotations

import os
import sys
import json
import math
import time
from pathlib import Path

# CRITICAL: Set SDL environment variables BEFORE any imports
os.environ['SDL_VIDEODRIVER'] = 'dummy'
os.environ['SDL_AUDIODRIVER'] = 'dummy'
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'

print(f"🔧 Set SDL_VIDEODRIVER to: {os.environ['SDL_VIDEODRIVER']}")

# Now import pygame
import pygame

print(f"🎮 Pygame version: {pygame.version.ver}")

BASE_DIR = Path(__file__).resolve().parent


def load_env_file(env_path: Path) -> dict:
    """Load .env file manually without using app utilities."""
    env_vars = {}
    if env_path.exists():
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip()
    return env_vars


def load_state(state_path: Path) -> dict:
    """Load robot state from JSON file."""
    try:
        if state_path.exists():
            return json.loads(state_path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"Warning: Could not load state from {state_path}: {e}")
    return {"state": "idle", "last_talk": 0.0, "toggles": {}}


def draw_face(surface: pygame.Surface, mood: str, timestamp: float) -> None:
    """Draw the Echo face on the surface."""
    width, height = surface.get_size()
    surface.fill((5, 5, 12))  # Dark background
    
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

    # Draw eyes
    for direction in (-1, 1):
        center = (width // 2 + direction * eye_dx, eye_y)
        pygame.draw.circle(surface, color, center, eye_radius + pulse, width=4)

    # Draw mouth
    mouth_y = int(height * 0.68)
    mouth_w = int(width * 0.36)
    mouth_h = 60 if mood != "sleeping" else 12
    rect = pygame.Rect(width // 2 - mouth_w // 2, mouth_y - mouth_h // 2, mouth_w, mouth_h)
    start_angle = math.pi * 0.1
    end_angle = math.pi * 0.9
    pygame.draw.arc(surface, (0, 200, 255), rect, start_angle, end_angle, width=6)


def main() -> None:
    print("🚀 Starting Echo Face Renderer (Standalone)")
    
    # Load environment manually
    env_files = [
        BASE_DIR / ".env",
        BASE_DIR.parent / ".env",
        Path("/opt/echo-ai/.env")
    ]
    
    env_vars = {}
    for env_file in env_files:
        if env_file.exists():
            env_vars.update(load_env_file(env_file))
            print(f"📄 Loaded environment from: {env_file}")
            break
    
    # Set up data directory
    data_dir = Path(env_vars.get("ECHO_DATA_DIR", "/opt/echo-ai/data"))
    data_dir.mkdir(parents=True, exist_ok=True)
    state_path = data_dir / "echo_state.json"

    try:
        # Initialize pygame
        pygame.init()
        print("✅ Pygame initialized")
        
        # Check what driver we actually got
        driver = pygame.display.get_driver()
        print(f"🎮 Actual SDL driver: {driver}")
        
        # Create display
        size = (800, 480)
        screen = pygame.display.set_mode(size)
        print(f"✅ Display created: {size}")
        
        pygame.display.set_caption("Echo Face (Standalone)")
        clock = pygame.time.Clock()

        print("🎯 Starting main loop...")
        frame_count = 0
        running = True
        
        while running:
            now = time.time()
            
            # Handle events
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
            
            # Load state every 10 frames
            if frame_count % 10 == 0:
                state = load_state(state_path)
                current_mood = state.get("state", "idle")
            else:
                current_mood = "idle"
            
            # Draw face
            draw_face(screen, current_mood, now)
            pygame.display.flip()
            
            clock.tick(30)
            frame_count += 1
            
            # Log progress every 30 frames (1 second)
            if frame_count % 30 == 0:
                print(f"📊 Frame {frame_count}, Mood: {current_mood}, Driver: {driver}")
            
            # Safety timeout after 1 hour
            if frame_count > 30 * 60 * 60:
                print("⏰ Safety timeout reached. Restarting...")
                running = False
        
        print("✅ Face renderer completed normally")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        pygame.quit()
        print("🧹 Pygame cleaned up")


if __name__ == "__main__":
    main()