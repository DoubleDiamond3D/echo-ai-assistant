#!/usr/bin/env python3
"""Minimal face renderer that bypasses SDL driver issues."""
from __future__ import annotations

import os
import sys

# Try to force dummy driver first to test pygame
os.environ['SDL_VIDEODRIVER'] = 'dummy'
os.environ['SDL_AUDIODRIVER'] = 'dummy'

print(f"🔧 Using SDL_VIDEODRIVER: {os.environ['SDL_VIDEODRIVER']}")

import pygame
import json
import math
import time
from pathlib import Path

from app.config import Settings
from app.utils.env import load_first_existing

BASE_DIR = Path(__file__).resolve().parent


def load_state(state_path: Path) -> dict:
    try:
        return json.loads(state_path.read_text(encoding="utf-8"))
    except Exception:
        return {"state": "idle", "last_talk": 0.0, "toggles": {}}


def main() -> None:
    print("🚀 Starting Minimal Echo Face Renderer")
    
    # Load settings
    load_first_existing([BASE_DIR / ".env", BASE_DIR.parent / ".env"])
    settings = Settings.from_env(BASE_DIR)
    state_path = settings.data_dir / "echo_state.json"
    state_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        # Initialize pygame with dummy driver
        pygame.init()
        print("✅ Pygame initialized")
        
        # Check driver
        driver = pygame.display.get_driver()
        print(f"🎮 SDL driver: {driver}")
        
        # Create a small surface for testing
        size = (320, 240)
        screen = pygame.display.set_mode(size)
        print(f"✅ Display created: {size}")
        
        # Simple test - just fill screen with colors
        colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)]
        
        for i in range(20):  # Run for a few seconds
            color = colors[i % len(colors)]
            screen.fill(color)
            pygame.display.flip()
            time.sleep(0.2)
            print(f"📊 Frame {i+1}/20 - Color: {color}")
        
        print("✅ Minimal test completed successfully!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        pygame.quit()
        print("🧹 Pygame cleaned up")


if __name__ == "__main__":
    main()