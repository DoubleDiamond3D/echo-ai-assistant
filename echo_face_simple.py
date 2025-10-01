#!/usr/bin/env python3
"""Simplified face renderer that won't hang the system."""

import os
import sys
import time
import signal
import json
from pathlib import Path

# Global flag for graceful shutdown
shutdown_requested = False

def signal_handler(signum, frame):
    global shutdown_requested
    print(f"Received signal {signum}, shutting down gracefully...")
    shutdown_requested = True

def main():
    global shutdown_requested
    print("=== Echo Face Renderer Starting ===")
    
    # Set up signal handlers
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    # Set environment variables
    os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
    os.environ['SDL_VIDEODRIVER'] = 'dummy'  # Use dummy driver to avoid display issues
    
    try:
        import pygame
        print("✅ Pygame imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import pygame: {e}")
        return 1
    
    try:
        pygame.init()
        print("✅ Pygame initialized successfully")
    except Exception as e:
        print(f"❌ Failed to initialize pygame: {e}")
        return 1
    
    # Create a minimal display
    try:
        screen = pygame.display.set_mode((100, 100), 0)
        print("✅ Display created successfully")
    except Exception as e:
        print(f"❌ Failed to create display: {e}")
        pygame.quit()
        return 1
    
    # Simple main loop that won't hang
    frame_count = 0
    print("Starting main loop...")
    
    try:
        while not shutdown_requested and frame_count < 1000:  # Limit to 1000 frames for safety
            # Handle events
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    shutdown_requested = True
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        shutdown_requested = True
            
            # Simple drawing
            screen.fill((0, 0, 0))
            pygame.draw.circle(screen, (0, 255, 0), (50, 50), 20)
            pygame.display.flip()
            
            # Sleep to prevent high CPU usage
            time.sleep(0.1)  # 10 FPS
            frame_count += 1
            
            # Print status every 100 frames
            if frame_count % 100 == 0:
                print(f"Running... frame {frame_count}")
    
    except Exception as e:
        print(f"❌ Error in main loop: {e}")
    finally:
        print("Cleaning up...")
        pygame.quit()
        print("✅ Shutdown complete")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
