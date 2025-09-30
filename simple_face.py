#!/usr/bin/env python3
"""Simplified face renderer for testing."""

import os
import sys
import time
import json
from pathlib import Path

def main():
    print("=== Simple Face Renderer Test ===")
    print(f"Python version: {sys.version}")
    print(f"Working directory: {os.getcwd()}")
    
    # Test basic imports
    try:
        import pygame
        print("✅ Pygame imported")
    except Exception as e:
        print(f"❌ Pygame import failed: {e}")
        return 1
    
    # Test pygame initialization
    try:
        pygame.init()
        print("✅ Pygame initialized")
    except Exception as e:
        print(f"❌ Pygame init failed: {e}")
        return 1
    
    # Test display creation with minimal settings
    try:
        # Try the simplest possible display
        os.environ['SDL_VIDEODRIVER'] = 'dummy'  # Use dummy driver for testing
        screen = pygame.display.set_mode((100, 100), 0)
        print("✅ Display created successfully")
        
        # Draw something simple
        screen.fill((0, 0, 0))
        pygame.draw.circle(screen, (255, 255, 255), (50, 50), 20)
        pygame.display.flip()
        print("✅ Drawing successful")
        
        # Wait a moment
        time.sleep(1)
        
        pygame.quit()
        print("✅ Pygame quit successfully")
        return 0
        
    except Exception as e:
        print(f"❌ Display creation failed: {e}")
        pygame.quit()
        return 1

if __name__ == "__main__":
    sys.exit(main())
