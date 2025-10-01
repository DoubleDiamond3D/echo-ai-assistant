#!/usr/bin/env python3
"""Super basic pygame test."""

import os
import sys

print("🧪 Basic Pygame Test")
print("=" * 30)

# Try different drivers
drivers_to_test = ['dummy', 'fbcon', 'directfb']

for driver in drivers_to_test:
    print(f"\n🔍 Testing driver: {driver}")
    
    # Set environment
    os.environ['SDL_VIDEODRIVER'] = driver
    if driver == 'fbcon':
        os.environ['SDL_FBDEV'] = '/dev/fb0'
    
    try:
        # Import pygame fresh
        if 'pygame' in sys.modules:
            del sys.modules['pygame']
            del sys.modules['pygame.display']
        
        import pygame
        
        print(f"   Pygame version: {pygame.version.ver}")
        
        # Initialize
        pygame.init()
        print(f"   ✅ pygame.init() successful")
        
        # Check driver
        actual_driver = pygame.display.get_driver()
        print(f"   🎮 Actual driver: {actual_driver}")
        
        # Try to create display
        screen = pygame.display.set_mode((320, 240))
        print(f"   ✅ Display created: 320x240")
        
        # Fill with color
        screen.fill((0, 255, 0))  # Green
        pygame.display.flip()
        print(f"   ✅ Screen filled and flipped")
        
        pygame.quit()
        print(f"   ✅ {driver} driver WORKS!")
        break
        
    except Exception as e:
        print(f"   ❌ {driver} failed: {e}")
        try:
            pygame.quit()
        except:
            pass

print("\n🏁 Test completed")