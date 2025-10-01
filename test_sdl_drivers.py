#!/usr/bin/env python3
"""Test all possible SDL drivers systematically."""

import os
import sys

def test_driver(driver_name):
    """Test a specific SDL driver."""
    print(f"\n🧪 Testing driver: {driver_name}")
    print("=" * 40)
    
    # Clear any existing pygame modules
    modules_to_clear = [k for k in sys.modules.keys() if k.startswith('pygame')]
    for module in modules_to_clear:
        del sys.modules[module]
    
    # Set environment variables
    os.environ['SDL_VIDEODRIVER'] = driver_name
    os.environ['SDL_AUDIODRIVER'] = 'dummy'
    os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
    
    if driver_name == 'fbcon':
        os.environ['SDL_FBDEV'] = '/dev/fb0'
    
    print(f"🔧 Set SDL_VIDEODRIVER to: {os.environ['SDL_VIDEODRIVER']}")
    
    try:
        # Import pygame fresh
        import pygame
        
        print(f"📦 Pygame version: {pygame.version.ver}")
        print(f"📦 SDL version: {pygame.version.SDL}")
        
        # Initialize
        pygame.init()
        print("✅ pygame.init() successful")
        
        # Check what driver we actually got
        actual_driver = pygame.display.get_driver()
        print(f"🎮 Requested: {driver_name}")
        print(f"🎮 Actual: {actual_driver}")
        
        # Try to create a display
        try:
            screen = pygame.display.set_mode((320, 240))
            print("✅ Display created successfully")
            
            # Try to draw something
            screen.fill((255, 0, 0))  # Red
            pygame.display.flip()
            print("✅ Screen filled and flipped")
            
            pygame.quit()
            print(f"✅ SUCCESS: {driver_name} works!")
            return True
            
        except Exception as display_error:
            print(f"❌ Display creation failed: {display_error}")
            pygame.quit()
            return False
            
    except Exception as e:
        print(f"❌ Failed: {e}")
        try:
            pygame.quit()
        except:
            pass
        return False

def main():
    """Test all available drivers."""
    print("🚀 SDL Driver Test Suite")
    print("=" * 50)
    
    # List of drivers to test
    drivers = [
        'dummy',      # Should always work
        'fbcon',      # Framebuffer
        'directfb',   # DirectFB
        'x11',        # X11 (probably won't work headless)
        'wayland',    # Wayland (probably won't work)
        'kmsdrm',     # The problematic one
    ]
    
    working_drivers = []
    
    for driver in drivers:
        if test_driver(driver):
            working_drivers.append(driver)
    
    print("\n" + "=" * 50)
    print("📊 RESULTS")
    print("=" * 50)
    
    if working_drivers:
        print("✅ Working drivers:")
        for driver in working_drivers:
            print(f"   - {driver}")
        
        print(f"\n🎯 Best driver to use: {working_drivers[0]}")
    else:
        print("❌ No drivers worked!")
        print("\n🔧 Troubleshooting:")
        print("1. Check if pygame is properly installed")
        print("2. Check system graphics configuration")
        print("3. Try running as root")
        print("4. Check /dev/fb0 permissions")
    
    return len(working_drivers) > 0

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)