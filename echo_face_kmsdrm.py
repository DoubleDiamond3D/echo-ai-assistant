#!/usr/bin/env python3
"""Minimal face renderer driven by the shared state file - KMSDRM Version."""
from __future__ import annotations

import json
import math
import os
import sys
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

    # Check which SDL driver is being requested
    sdl_driver = os.environ.get("SDL_VIDEODRIVER", "auto")
    print(f"Using SDL driver from environment: {sdl_driver}")
    
    # IMPORTANT: Don't override the SDL_VIDEODRIVER if it's already set to kmsdrm
    if sdl_driver == "auto":
        # Only try different drivers if not explicitly set
        sdl_drivers = ["kmsdrm", "fbcon", "x11", "dummy"]
    else:
        # Use the driver specified in the environment
        sdl_drivers = [sdl_driver]
    
    # Initialize pygame with error handling
    try:
        pygame.init()
        print("Pygame initialized successfully")
    except Exception as e:
        print(f"Failed to initialize pygame: {e}")
        return

    # Try different display modes with fallbacks
    fullscreen = os.environ.get("ECHO_FACE_FULLSCREEN", "0") == "1"
    size = (800, 480)
    screen = None
    
    for driver in sdl_drivers:
        if driver != os.environ.get("SDL_VIDEODRIVER"):
            print(f"Setting SDL driver to: {driver}")
            os.environ['SDL_VIDEODRIVER'] = driver
        
        # Reinitialize pygame display with new driver
        try:
            pygame.display.quit()
            pygame.display.init()
        except:
            pass
        
        # Try different display modes
        display_modes = []
        if fullscreen and driver == "kmsdrm":
            # For KMSDRM, try to detect the native resolution first
            try:
                info = pygame.display.Info()
                if info.current_w > 0 and info.current_h > 0:
                    native_size = (info.current_w, info.current_h)
                    print(f"KMSDRM detected native resolution: {native_size}")
                    display_modes = [
                        (native_size, pygame.FULLSCREEN | pygame.DOUBLEBUF),
                        (size, pygame.FULLSCREEN | pygame.DOUBLEBUF),
                        (size, pygame.FULLSCREEN),
                    ]
                else:
                    display_modes = [
                        (size, pygame.FULLSCREEN | pygame.DOUBLEBUF),
                        (size, pygame.FULLSCREEN),
                    ]
            except:
                display_modes = [
                    (size, pygame.FULLSCREEN | pygame.DOUBLEBUF),
                    (size, pygame.FULLSCREEN),
                ]
        elif fullscreen:
            display_modes = [
                (size, pygame.FULLSCREEN),
                (size, 0),  # Windowed fallback
            ]
        else:
            display_modes = [
                (size, 0),
            ]
        
        for mode_size, mode_flags in display_modes:
            try:
                screen = pygame.display.set_mode(mode_size, mode_flags)
                print(f"✅ Display mode set: {mode_size}, flags: {mode_flags} with driver: {driver}")
                break
            except Exception as e:
                print(f"❌ Failed to set display mode {mode_size} with flags {mode_flags} using {driver}: {e}")
                continue
        
        if screen is not None:
            break
    
    if screen is None:
        print("❌ Failed to initialize any display mode. Exiting.")
        pygame.quit()
        return
    
    pygame.display.set_caption("Project Echo Face")
    
    # Hide mouse cursor for KMSDRM
    if sdl_driver == "kmsdrm":
        pygame.mouse.set_visible(False)
    
    clock = pygame.time.Clock()

    running = True
    frame_count = 0
    current_mood = "idle"
    
    print("Starting face renderer main loop...")
    print(f"Display size: {screen.get_size()}")
    print(f"Display driver: {os.environ.get('SDL_VIDEODRIVER')}")
    
    try:
        while running:
            now = time.time()
            
            # Handle events (but don't block if no events)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE or event.key == pygame.K_q:
                        running = False
            
            # Only update state every 10 frames to reduce file I/O
            if frame_count % 10 == 0:
                state = load_state(state_path)
                current_mood = state.get("state", "idle")
            
            # Draw the face
            draw_face(screen, current_mood, now)
            pygame.display.flip()
            
            # Limit to 30 FPS to reduce CPU usage
            clock.tick(30)
            frame_count += 1
            
            # Debug output every 10 seconds
            if frame_count % 300 == 0:
                print(f"Running... Frame: {frame_count}, Mood: {current_mood}")
            
            # Safety check - exit after 1 hour to prevent memory leaks
            if frame_count > 30 * 60 * 60:  # 30 FPS * 60 seconds * 60 minutes
                print("Safety timeout reached. Restarting...")
                running = False
                
    except KeyboardInterrupt:
        print("\nReceived interrupt, shutting down...")
    except Exception as e:
        print(f"Error in main loop: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("Cleaning up pygame...")
        pygame.quit()
        print("Echo face renderer stopped.")


if __name__ == "__main__":
    main()
