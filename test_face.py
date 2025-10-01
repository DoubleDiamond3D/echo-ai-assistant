#!/usr/bin/env python3
"""Simple test script for pygame display on Raspberry Pi."""

import os
import sys
import time

def test_pygame():
    print("Testing pygame initialization...")
    
    try:
        import pygame
        print("✅ Pygame imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import pygame: {e}")
        return False
    
    try:
        pygame.init()
        print("✅ Pygame initialized successfully")
    except Exception as e:
        print(f"❌ Failed to initialize pygame: {e}")
        return False
    
    # Test different display drivers
    drivers = ['fbcon', 'x11', 'dummy']
    
    for driver in drivers:
        print(f"\nTesting SDL driver: {driver}")
        os.environ['SDL_VIDEODRIVER'] = driver
        
        try:
            # Try to create a small test surface
            screen = pygame.display.set_mode((100, 100), 0)
            print(f"✅ {driver} driver works!")
            pygame.quit()
            return True
        except Exception as e:
            print(f"❌ {driver} driver failed: {e}")
            continue
    
    print("❌ No working display driver found")
    return False

def test_framebuffer():
    print("\nTesting framebuffer access...")
    
    fb_devices = ['/dev/fb0', '/dev/fb1']
    
    for fb in fb_devices:
        if os.path.exists(fb):
            print(f"✅ {fb} exists")
            try:
                with open(fb, 'rb') as f:
                    f.read(1)  # Try to read 1 byte
                print(f"✅ {fb} is readable")
            except Exception as e:
                print(f"❌ {fb} not readable: {e}")
        else:
            print(f"❌ {fb} does not exist")

if __name__ == "__main__":
    print("=== Pygame Display Test ===")
    print(f"Python version: {sys.version}")
    print(f"Current working directory: {os.getcwd()}")
    print(f"Environment variables:")
    for key in ['DISPLAY', 'SDL_VIDEODRIVER', 'FRAMEBUFFER']:
        print(f"  {key}: {os.environ.get(key, 'Not set')}")
    
    test_framebuffer()
    success = test_pygame()
    
    if success:
        print("\n✅ Pygame test passed!")
        sys.exit(0)
    else:
        print("\n❌ Pygame test failed!")
        sys.exit(1)




