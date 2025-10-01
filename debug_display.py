#!/usr/bin/env python3
"""Debug script to test display drivers and show what's available."""

import os
import sys

def test_display_drivers():
    print("=== Display Driver Debug ===")
    
    # Check environment
    print(f"DISPLAY: {os.environ.get('DISPLAY', 'Not set')}")
    print(f"XDG_RUNTIME_DIR: {os.environ.get('XDG_RUNTIME_DIR', 'Not set')}")
    
    # Check if we can import pygame
    try:
        import pygame
        print("✅ Pygame imported successfully")
    except ImportError as e:
        print(f"❌ Pygame import failed: {e}")
        return
    
    # Initialize pygame
    try:
        pygame.init()
        print("✅ Pygame initialized")
    except Exception as e:
        print(f"❌ Pygame init failed: {e}")
        return
    
    # Test different drivers
    drivers = ["x11", "fbcon", "dummy"]
    
    for driver in drivers:
        print(f"\n--- Testing {driver} driver ---")
        os.environ['SDL_VIDEODRIVER'] = driver
        
        try:
            # Try to create a display
            screen = pygame.display.set_mode((100, 100), 0)
            print(f"✅ {driver} driver works!")
            
            # Try to draw something
            screen.fill((255, 0, 0))  # Red background
            pygame.draw.circle(screen, (0, 255, 0), (50, 50), 20)  # Green circle
            pygame.display.flip()
            print(f"✅ {driver} driver can draw!")
            
            # Clean up
            pygame.quit()
            pygame.init()  # Reinit for next test
            
        except Exception as e:
            print(f"❌ {driver} driver failed: {e}")
    
    # Check available video drivers
    print(f"\n--- Available video drivers ---")
    try:
        drivers = pygame.display.get_driver()
        print(f"Current driver: {drivers}")
    except Exception as e:
        print(f"Error getting driver info: {e}")
    
    # Check display info
    print(f"\n--- Display info ---")
    try:
        info = pygame.display.Info()
        print(f"Display info: {info}")
    except Exception as e:
        print(f"Error getting display info: {e}")
    
    pygame.quit()

if __name__ == "__main__":
    test_display_drivers()




