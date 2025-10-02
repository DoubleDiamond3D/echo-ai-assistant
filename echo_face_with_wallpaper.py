#!/usr/bin/env python3
"""Echo Face service for Pi #2 - with wallpaper support."""
from __future__ import annotations

import json
import math
import os
import time
import requests
from pathlib import Path
from typing import Dict, Any, Optional

import pygame

# Load configuration
BASE_DIR = Path(__file__).resolve().parent
ENV_FILE = BASE_DIR / ".env"
WALLPAPER_DIR = Path("/opt/echo-ai/wallpapers")

def load_env():
    """Load environment variables from .env file."""
    if ENV_FILE.exists():
        with open(ENV_FILE) as f:
            for line in f:
                if line.strip() and not line.startswith('#') and '=' in line:
                    key, value = line.strip().split('=', 1)
                    os.environ[key] = value

def load_state() -> Dict[str, Any]:
    """Load robot state from Brain Pi or local file."""
    brain_url = os.environ.get('ECHO_BRAIN_PI_URL', '')
    api_token = os.environ.get('ECHO_API_TOKEN', '')
    
    if brain_url and api_token:
        try:
            response = requests.get(
                f"{brain_url}/api/state",
                headers={"X-API-Key": api_token},
                timeout=2
            )
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            print(f"Warning: Could not fetch state from Brain Pi: {e}")
    
    # Fallback to local state file
    local_state_path = BASE_DIR / "data" / "echo_state.json"
    try:
        if local_state_path.exists():
            return json.loads(local_state_path.read_text())
    except Exception:
        pass
    
    return {"state": "idle", "last_talk": 0.0, "toggles": {}}

def load_wallpaper(screen_size: tuple) -> Optional[pygame.Surface]:
    """Load and scale wallpaper image if available."""
    try:
        # Check for image wallpaper first
        image_path = WALLPAPER_DIR / "wallpaper.jpg"
        if image_path.exists():
            print(f"📸 Loading wallpaper: {image_path}")
            wallpaper = pygame.image.load(str(image_path))
            return pygame.transform.scale(wallpaper, screen_size)
        
        # Check for PNG fallback
        png_path = WALLPAPER_DIR / "wallpaper.png"
        if png_path.exists():
            print(f"📸 Loading wallpaper: {png_path}")
            wallpaper = pygame.image.load(str(png_path))
            return pygame.transform.scale(wallpaper, screen_size)
            
    except Exception as e:
        print(f"⚠️  Failed to load wallpaper: {e}")
    
    return None

def draw_gradient_background(surface: pygame.Surface) -> None:
    """Draw gradient background when no wallpaper is available."""
    width, height = surface.get_size()
    for y in range(height):
        color_intensity = int(5 + (y / height) * 10)
        color = (color_intensity, color_intensity, color_intensity + 5)
        pygame.draw.line(surface, color, (0, y), (width, y))

def draw_face(surface: pygame.Surface, mood: str, timestamp: float, wallpaper: Optional[pygame.Surface] = None) -> None:
    """Draw the Echo face with improved graphics and optional wallpaper background."""
    width, height = surface.get_size()
    
    # Background
    if wallpaper:
        # Draw wallpaper with slight transparency overlay for better face visibility
        surface.blit(wallpaper, (0, 0))
        overlay = pygame.Surface((width, height))
        overlay.set_alpha(100)  # Semi-transparent overlay
        overlay.fill((0, 0, 0))
        surface.blit(overlay, (0, 0))
    else:
        # Gradient background
        draw_gradient_background(surface)
    
    # Face parameters
    eye_y = int(height * 0.35)
    eye_dx = int(width * 0.25)
    eye_radius = int(height * 0.08)
    
    # Mood-based colors
    palette = {
        "idle": (0, 170, 255),
        "talking": (0, 220, 255),
        "sleeping": (0, 80, 140),
        "listening": (255, 170, 0),
        "thinking": (170, 0, 255),
    }
    color = palette.get(mood, palette["idle"])
    
    # Animation pulse
    pulse = 0
    if mood == "talking":
        pulse = int(12 * abs(math.sin(timestamp * 8)))
    elif mood == "listening":
        pulse = int(6 * abs(math.sin(timestamp * 4)))
    elif mood == "idle":
        pulse = int(3 * abs(math.sin(timestamp * 2)))
    
    # Draw eyes with glow effect
    for direction in (-1, 1):
        center = (width // 2 + direction * eye_dx, eye_y)
        
        # Glow effect
        for i in range(3):
            glow_color = tuple(c // (i + 2) for c in color)
            pygame.draw.circle(surface, glow_color, center, eye_radius + pulse + (3 - i) * 2, width=2)
        
        # Main eye
        pygame.draw.circle(surface, color, center, eye_radius + pulse, width=4)
        
        # Eye center
        pygame.draw.circle(surface, (255, 255, 255), center, max(2, (eye_radius + pulse) // 4))
    
    # Draw mouth
    mouth_y = int(height * 0.65)
    mouth_w = int(width * 0.4)
    mouth_h = 80 if mood == "talking" else (20 if mood != "sleeping" else 8)
    
    if mood == "sleeping":
        # Sleeping mouth (straight line)
        start_pos = (width // 2 - mouth_w // 2, mouth_y)
        end_pos = (width // 2 + mouth_w // 2, mouth_y)
        pygame.draw.line(surface, color, start_pos, end_pos, 4)
    else:
        # Curved mouth
        rect = pygame.Rect(width // 2 - mouth_w // 2, mouth_y - mouth_h // 2, mouth_w, mouth_h)
        start_angle = math.pi * 0.1
        end_angle = math.pi * 0.9
        pygame.draw.arc(surface, color, rect, start_angle, end_angle, width=6)
    
    # Status text with background for better visibility
    try:
        font = pygame.font.Font(None, 36)
        status_text = f"Echo: {mood.title()}"
        text_surface = font.render(status_text, True, (255, 255, 255))
        
        # Text background
        text_bg = pygame.Surface((text_surface.get_width() + 20, text_surface.get_height() + 10))
        text_bg.set_alpha(150)
        text_bg.fill((0, 0, 0))
        surface.blit(text_bg, (5, height - 45))
        surface.blit(text_surface, (15, height - 40))
        
        # Connection status
        brain_url = os.environ.get('ECHO_BRAIN_PI_URL', '')
        if brain_url:
            conn_text = "Connected to Brain Pi"
            conn_color = (0, 255, 0)
        else:
            conn_text = "Standalone Mode"
            conn_color = (255, 255, 0)
        
        small_font = pygame.font.Font(None, 24)
        conn_surface = small_font.render(conn_text, True, conn_color)
        
        # Connection status background
        conn_bg = pygame.Surface((conn_surface.get_width() + 20, conn_surface.get_height() + 6))
        conn_bg.set_alpha(150)
        conn_bg.fill((0, 0, 0))
        surface.blit(conn_bg, (5, 5))
        surface.blit(conn_surface, (15, 8))
        
        # Wallpaper status
        if wallpaper:
            wall_text = "Wallpaper Active"
            wall_color = (0, 255, 255)
            wall_surface = small_font.render(wall_text, True, wall_color)
            wall_bg = pygame.Surface((wall_surface.get_width() + 20, wall_surface.get_height() + 6))
            wall_bg.set_alpha(150)
            wall_bg.fill((0, 0, 0))
            surface.blit(wall_bg, (5, 35))
            surface.blit(wall_surface, (15, 38))
        
    except Exception:
        pass  # Font might not be available

def main() -> None:
    print("🎭 Starting Echo Face with Wallpaper Support (Pi #2)")
    print("=" * 50)
    
    # Load environment
    load_env()
    
    # Initialize pygame
    pygame.init()
    print("✅ Pygame initialized")
    
    # Check display driver
    driver = pygame.display.get_driver()
    print(f"🎮 SDL driver: {driver}")
    
    # Get display settings
    fullscreen = os.environ.get('ECHO_FACE_FULLSCREEN', '1') == '1'
    width = int(os.environ.get('ECHO_FACE_WIDTH', '800'))
    height = int(os.environ.get('ECHO_FACE_HEIGHT', '480'))
    
    # Create display
    if fullscreen:
        screen = pygame.display.set_mode((width, height), pygame.FULLSCREEN)
        print(f"✅ Fullscreen display: {width}x{height}")
    else:
        screen = pygame.display.set_mode((width, height))
        print(f"✅ Windowed display: {width}x{height}")
    
    pygame.display.set_caption("Echo AI Face")
    clock = pygame.time.Clock()
    
    # Hide mouse cursor in fullscreen
    if fullscreen:
        pygame.mouse.set_visible(False)
    
    # Load initial wallpaper
    wallpaper = load_wallpaper((width, height))
    last_wallpaper_check = 0
    
    print("🎯 Starting face display loop...")
    
    frame_count = 0
    running = True
    last_mood = None
    
    try:
        while running:
            now = time.time()
            
            # Handle events
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE or event.key == pygame.K_q:
                        running = False
                    elif event.key == pygame.K_f:
                        # Toggle fullscreen
                        fullscreen = not fullscreen
                        if fullscreen:
                            screen = pygame.display.set_mode((width, height), pygame.FULLSCREEN)
                            pygame.mouse.set_visible(False)
                        else:
                            screen = pygame.display.set_mode((width, height))
                            pygame.mouse.set_visible(True)
                        # Reload wallpaper for new screen size
                        wallpaper = load_wallpaper((width, height))
                    elif event.key == pygame.K_r:
                        # Reload wallpaper manually
                        print("🔄 Reloading wallpaper...")
                        wallpaper = load_wallpaper((width, height))
            
            # Load state every 30 frames (1 second at 30fps)
            if frame_count % 30 == 0:
                state = load_state()
                current_mood = state.get("state", "idle")
                
                # Log mood changes
                if current_mood != last_mood:
                    print(f"😊 Mood: {last_mood} → {current_mood}")
                    last_mood = current_mood
            else:
                current_mood = last_mood or "idle"
            
            # Check for wallpaper updates every 5 minutes
            if now - last_wallpaper_check > 300:  # 5 minutes
                new_wallpaper = load_wallpaper((width, height))
                if new_wallpaper != wallpaper:
                    print("🖼️  Wallpaper updated")
                    wallpaper = new_wallpaper
                last_wallpaper_check = now
            
            # Draw face
            draw_face(screen, current_mood, now, wallpaper)
            pygame.display.flip()
            
            # Maintain 30 FPS
            clock.tick(30)
            frame_count += 1
            
            # Log status every 5 minutes
            if frame_count % (30 * 60 * 5) == 0:
                minutes = frame_count // (30 * 60)
                wallpaper_status = "with wallpaper" if wallpaper else "no wallpaper"
                print(f"📊 Running {minutes}m, Mood: {current_mood}, FPS: {clock.get_fps():.1f}, {wallpaper_status}")
    
    except KeyboardInterrupt:
        print("\n⏹️  Interrupted by user")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        pygame.quit()
        print("🧹 Face display stopped")

if __name__ == "__main__":
    main()