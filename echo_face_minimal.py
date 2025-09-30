#!/usr/bin/env python3
"""Minimal face renderer that definitely won't hang."""

import os
import sys
import time

def main():
    print("=== Echo Face Renderer Starting ===")
    
    # Set environment variables
    os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
    os.environ['SDL_VIDEODRIVER'] = 'dummy'
    
    try:
        import pygame
        print("✅ Pygame imported")
    except ImportError as e:
        print(f"❌ Pygame import failed: {e}")
        return 1
    
    try:
        pygame.init()
        print("✅ Pygame initialized")
    except Exception as e:
        print(f"❌ Pygame init failed: {e}")
        return 1
    
    try:
        screen = pygame.display.set_mode((100, 100), 0)
        print("✅ Display created")
    except Exception as e:
        print(f"❌ Display creation failed: {e}")
        pygame.quit()
        return 1
    
    # Simple loop with timeout
    print("Starting main loop...")
    start_time = time.time()
    frame_count = 0
    
    try:
        while frame_count < 100:  # Only run for 100 frames
            # Handle events
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    print("QUIT event received")
                    break
            
            # Simple drawing
            screen.fill((0, 0, 0))
            pygame.draw.circle(screen, (0, 255, 0), (50, 50), 20)
            pygame.display.flip()
            
            # Sleep
            time.sleep(0.1)
            frame_count += 1
            
            # Check timeout
            if time.time() - start_time > 30:  # 30 second timeout
                print("Timeout reached, exiting")
                break
            
            if frame_count % 10 == 0:
                print(f"Frame {frame_count}")
    
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        print("Cleaning up...")
        pygame.quit()
        print("✅ Done")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
