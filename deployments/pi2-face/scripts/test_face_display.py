#!/usr/bin/env python3
"""Test face display on Pi #2 with desktop OS."""

import os
import sys
import time
from pathlib import Path

# Force environment before pygame import
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'

import pygame

def test_display_modes():
    """Test different display modes."""
    print("🎭 Echo Face Display Test (Pi #2)")
    print("=" * 40)
    
    # Initialize pygame
    pygame.init()
    print("✅ Pygame initialized")
    
    # Check SDL driver
    driver = pygame.display.get_driver()
    print(f"🎮 SDL driver: {driver}")
    
    # Test different display modes
    modes = [
        ((800, 480), 0, "Windowed 800x480"),
        ((1024, 768), 0, "Windowed 1024x768"),
        ((800, 480), pygame.FULLSCREEN, "Fullscreen 800x480"),
    ]
    
    for size, flags, description in modes:
        print(f"\n🧪 Testing: {description}")
        try:
            screen = pygame.display.set_mode(size, flags)
            print(f"✅ Display mode set: {size}")
            
            # Draw test pattern
            colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)]
            for i, color in enumerate(colors):
                screen.fill(color)
                
                # Add text
                try:
                    font = pygame.font.Font(None, 48)
                    text = font.render(f"Test {i+1}: {description}", True, (255, 255, 255))
                    screen.blit(text, (10, 10))
                except:
                    pass
                
                pygame.display.flip()
                time.sleep(1)
                
                # Check for quit events
                for event in pygame.event.get():
                    if event.type == pygame.QUIT:
                        pygame.quit()
                        return
                    elif event.type == pygame.KEYDOWN:
                        if event.key == pygame.K_ESCAPE:
                            pygame.quit()
                            return
            
            print(f"✅ {description} works!")
            
        except Exception as e:
            print(f"❌ {description} failed: {e}")
    
    pygame.quit()
    print("\n🎉 Display test completed!")

def test_face_animation():
    """Test animated face display."""
    print("\n🎭 Testing Face Animation")
    print("=" * 30)
    
    pygame.init()
    
    try:
        # Create display
        screen = pygame.display.set_mode((800, 480))
        pygame.display.set_caption("Echo Face Animation Test")
        clock = pygame.time.Clock()
        
        print("✅ Animation test started")
        print("Press ESC or close window to exit")
        
        frame_count = 0
        running = True
        
        while running and frame_count < 300:  # Run for 10 seconds at 30fps
            # Handle events
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
            
            # Clear screen
            screen.fill((5, 5, 12))
            
            # Draw animated face
            width, height = screen.get_size()
            now = time.time()
            
            # Animated eyes
            eye_y = height // 3
            eye_radius = 40
            pulse = int(5 * abs(math.sin(now * 3)))
            
            for direction in (-1, 1):
                center = (width // 2 + direction * 100, eye_y)
                pygame.draw.circle(screen, (0, 170, 255), center, eye_radius + pulse, width=4)
            
            # Animated mouth
            mouth_y = int(height * 0.65)
            mouth_w = 200
            mouth_h = 60
            rect = pygame.Rect(width // 2 - mouth_w // 2, mouth_y - mouth_h // 2, mouth_w, mouth_h)
            pygame.draw.arc(screen, (0, 200, 255), rect, 0.1 * 3.14159, 0.9 * 3.14159, width=6)
            
            # Status text
            try:
                font = pygame.font.Font(None, 36)
                text = font.render(f"Frame {frame_count}/300", True, (200, 200, 200))
                screen.blit(text, (10, 10))
            except:
                pass
            
            pygame.display.flip()
            clock.tick(30)
            frame_count += 1
        
        print("✅ Animation test completed successfully!")
        
    except Exception as e:
        print(f"❌ Animation test failed: {e}")
    finally:
        pygame.quit()

def main():
    """Run all display tests."""
    import math  # Import here for animation test
    
    print("🚀 Starting Echo Face Display Tests")
    print("This will test if the display works properly on Pi #2")
    print()
    
    # Test basic display modes
    test_display_modes()
    
    # Test face animation
    test_face_animation()
    
    print("\n🎯 Test Summary:")
    print("If you saw colored screens and animated face, the display is working!")
    print("You can now run the full Echo Face service.")

if __name__ == "__main__":
    main()