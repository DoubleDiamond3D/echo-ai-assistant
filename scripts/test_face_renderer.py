#!/usr/bin/env python3
"""Test the face renderer manually with different configurations."""

import os
import sys
import time
import subprocess
from pathlib import Path

def test_with_driver(driver_name, description):
    """Test face renderer with a specific SDL driver."""
    print(f"\n🧪 Testing with {description} ({driver_name})")
    print("=" * 50)
    
    # Set environment
    env = os.environ.copy()
    env['SDL_VIDEODRIVER'] = driver_name
    env['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
    env['PYTHONUNBUFFERED'] = '1'
    
    if driver_name == 'fbcon':
        env['SDL_FBDEV'] = '/dev/fb0'
    elif driver_name == 'kmsdrm':
        env['XDG_RUNTIME_DIR'] = '/run/user/1000'
    
    script_path = Path(__file__).parent.parent / 'echo_face.py'
    
    try:
        print(f"Running: python3 {script_path}")
        print(f"Environment: SDL_VIDEODRIVER={driver_name}")
        
        # Run for 10 seconds then kill
        process = subprocess.Popen([
            sys.executable, str(script_path)
        ], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        # Wait for 10 seconds
        try:
            stdout, stderr = process.communicate(timeout=10)
            print(f"✅ Process completed normally")
            if stdout:
                print(f"stdout: {stdout}")
            if stderr:
                print(f"stderr: {stderr}")
        except subprocess.TimeoutExpired:
            print(f"⏰ Process running for 10+ seconds (good sign)")
            process.terminate()
            try:
                stdout, stderr = process.communicate(timeout=5)
                if stdout:
                    print(f"stdout: {stdout}")
                if stderr:
                    print(f"stderr: {stderr}")
            except subprocess.TimeoutExpired:
                process.kill()
                print("🔪 Process killed (was unresponsive)")
        
        return_code = process.returncode
        if return_code == 0:
            print(f"✅ Success with {description}")
            return True
        elif return_code == -15:  # SIGTERM
            print(f"✅ Success with {description} (terminated as expected)")
            return True
        else:
            print(f"❌ Failed with return code {return_code}")
            return False
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

def check_prerequisites():
    """Check if prerequisites are met."""
    print("🔍 Checking Prerequisites")
    print("=" * 30)
    
    # Check if script exists
    script_path = Path(__file__).parent.parent / 'echo_face.py'
    if not script_path.exists():
        print(f"❌ echo_face.py not found at {script_path}")
        return False
    print(f"✅ echo_face.py found")
    
    # Check pygame
    try:
        import pygame
        print(f"✅ pygame available: {pygame.version.ver}")
    except ImportError:
        print("❌ pygame not installed")
        return False
    
    # Check framebuffer
    if os.path.exists('/dev/fb0'):
        stat = os.stat('/dev/fb0')
        print(f"✅ /dev/fb0 exists (permissions: {oct(stat.st_mode)[-3:]})")
    else:
        print("❌ /dev/fb0 not found")
    
    # Check if running as echo user
    import pwd
    current_user = pwd.getpwuid(os.getuid()).pw_name
    print(f"ℹ️  Running as user: {current_user}")
    
    return True

def main():
    """Main test function."""
    print("🤖 Echo Face Renderer Test")
    print("=" * 30)
    
    if not check_prerequisites():
        print("\n❌ Prerequisites not met")
        return 1
    
    # Test different SDL drivers
    drivers = [
        ('dummy', 'Dummy Driver (no display)'),
        ('fbcon', 'Framebuffer Console'),
        ('kmsdrm', 'Kernel Mode Setting DRM'),
        ('x11', 'X11 (if available)')
    ]
    
    successful_drivers = []
    
    for driver, description in drivers:
        if test_with_driver(driver, description):
            successful_drivers.append((driver, description))
    
    print("\n" + "=" * 50)
    print("📊 Test Results")
    print("=" * 50)
    
    if successful_drivers:
        print("✅ Working drivers:")
        for driver, description in successful_drivers:
            print(f"   - {driver}: {description}")
        
        print(f"\n💡 Recommended driver: {successful_drivers[0][0]}")
        print(f"   Add to service: Environment=\"SDL_VIDEODRIVER={successful_drivers[0][0]}\"")
    else:
        print("❌ No drivers worked")
        print("\n🔧 Troubleshooting:")
        print("1. Check if echo user is in video group: groups echo")
        print("2. Check framebuffer permissions: ls -l /dev/fb0")
        print("3. Try running as root: sudo python3 scripts/test_face_renderer.py")
        print("4. Check pygame installation: python3 -c 'import pygame; print(pygame.version.ver)'")
    
    return 0 if successful_drivers else 1

if __name__ == "__main__":
    sys.exit(main())