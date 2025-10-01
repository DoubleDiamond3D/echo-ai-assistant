#!/usr/bin/env python3
"""Minimal face renderer driven by the shared state file - Headless Version."""
from __future__ import annotations

import json
import math
import os
import sys
import time
from pathlib import Path

# Set SDL to use framebuffer before importing pygame
os.environ['SDL_VIDEODRIVER'] = 'fbcon'
os.environ['SDL_FBDEV'] = '/dev/fb0'

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


def test_framebuffer():
    """Test if framebuffer is accessible"""
    fb_device = os.environ.get('SDL_FBDEV', '/dev/fb0')
    if not os.path.exists(fb_device):
        print(f"❌ Framebuffer device {fb_device} not found!")
        print("   Make sure HDMI is connected and framebuffer is enabled.")
        print("   Try: sudo modprobe bcm2835-v4l2")
        return False
    
    if not os.access(fb_device, os.R_OK | os.W_OK):
        print(f"❌ No read/write access to {fb_device}")
        print("   Add echo user to video group: sudo usermod -a -G video echo")
        print("   Or run: sudo chmod 666 /dev/fb0")
        return False
    
    print(f"✅ Framebuffer {fb_device} is accessible")
    return True


def main() -> None:
    load_first_existing([BASE_DIR / ".env", BASE_DIR.parent / ".env"])
    settings = Settings.from_env(BASE_DIR)
    state_path = settings.data_dir / "echo_state.json"
    state_path.parent.mkdir(parents=True, exist_ok=True)

    # Test framebuffer access first
    if not test_framebuffer():
        print("❌ Cannot access framebuffer. Exiting.")
        sys.exit(1)

    # Initialize pygame with specific driver settings for headless
    try:
        # Initialize SDL with framebuffer
        os.environ['SDL_VIDEODRIVER'] = 'fbcon'
        os.environ['SDL_FBDEV'] = '/dev/fb0'
        
        # Don't initialize audio to avoid conflicts
        pygame.display.init()
        pygame.font.init()
        
        print("Pygame display initialized successfully")
    except Exception as e:
        print(f"Failed to initialize pygame: {e}")
        print("Make sure you're running on a real Raspberry Pi with HDMI connected")
        return

    # Get framebuffer info and create display
    screen = None
    try:
        # Try to get current framebuffer resolution
        info = pygame.display.Info()
        width = info.current_w if info.current_w > 0 else 800
        height = info.current_h if info.current_h > 0 else 480
        print(f"Detected framebuffer resolution: {width}x{height}")
        
        # Create the display surface
        screen = pygame.display.set_mode((width, height), pygame.FULLSCREEN)
        print(f"✅ Display created: {width}x{height}")
    except Exception as e:
        print(f"❌ Failed to create display: {e}")
        # Try fallback resolution
        try:
            screen = pygame.display.set_mode((800, 480))
            print("✅ Using fallback resolution 800x480")
        except Exception as e2:
            print(f"❌ Fallback also failed: {e2}")
            pygame.quit()
            return
    
    pygame.display.set_caption("Project Echo Face")
    clock = pygame.time.Clock()
    
    # Hide mouse cursor
    pygame.mouse.set_visible(False)

    running = True
    frame_count = 0
    current_mood = "idle"
    
    print("Starting face renderer main loop...")
    
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
            
            # Periodic status update
            if frame_count % 300 == 0:  # Every 10 seconds at 30 FPS
                print(f"Running... Frame: {frame_count}, Mood: {current_mood}")
            
            # Safety check - restart after 1 hour to prevent memory leaks
            if frame_count > 30 * 60 * 60:  # 30 FPS * 60 seconds * 60 minutes
                print("Safety timeout reached. Restarting...")
                running = False
                
    except KeyboardInterrupt:
        print("\nReceived interrupt signal, shutting down...")
    except Exception as e:
        print(f"Error in main loop: {e}")
    finally:
        print("Cleaning up pygame...")
        pygame.quit()
        print("Face renderer stopped.")


if __name__ == "__main__":
    main()
