#!/usr/bin/env python3
"""Diagnose echo_face.service issues."""

import os
import sys
import subprocess
import pwd
import grp
from pathlib import Path

def check_user_and_groups():
    """Check if echo user exists and has proper groups."""
    print("👤 Checking User and Groups")
    print("=" * 30)
    
    try:
        echo_user = pwd.getpwnam('echo')
        print(f"✅ Echo user exists: UID {echo_user.pw_uid}")
        print(f"   Home: {echo_user.pw_dir}")
        print(f"   Shell: {echo_user.pw_shell}")
        
        # Check groups
        groups = [g.gr_name for g in grp.getgrall() if 'echo' in g.gr_mem]
        user_groups = subprocess.run(['groups', 'echo'], capture_output=True, text=True)
        print(f"   Groups: {user_groups.stdout.strip()}")
        
        # Check important groups
        important_groups = ['video', 'audio', 'input', 'render']
        for group in important_groups:
            if group in user_groups.stdout:
                print(f"   ✅ In {group} group")
            else:
                print(f"   ❌ NOT in {group} group")
        
    except KeyError:
        print("❌ Echo user does not exist")
        return False
    
    print()
    return True

def check_display_environment():
    """Check display and graphics environment."""
    print("🖥️  Checking Display Environment")
    print("=" * 35)
    
    # Check if X11 is running
    try:
        result = subprocess.run(['pgrep', 'X'], capture_output=True)
        if result.returncode == 0:
            print("✅ X11 server is running")
        else:
            print("❌ X11 server not running")
    except Exception as e:
        print(f"❓ Could not check X11: {e}")
    
    # Check DISPLAY variable
    display = os.environ.get('DISPLAY', '')
    if display:
        print(f"✅ DISPLAY set to: {display}")
    else:
        print("❌ DISPLAY not set")
    
    # Check framebuffer
    fb_devices = ['/dev/fb0', '/dev/fb1']
    for fb in fb_devices:
        if os.path.exists(fb):
            stat = os.stat(fb)
            print(f"✅ Framebuffer {fb} exists")
            print(f"   Permissions: {oct(stat.st_mode)[-3:]}")
            print(f"   Owner: {stat.st_uid}:{stat.st_gid}")
        else:
            print(f"❌ Framebuffer {fb} not found")
    
    # Check DRM devices
    drm_devices = list(Path('/dev/dri').glob('card*')) if Path('/dev/dri').exists() else []
    if drm_devices:
        print(f"✅ DRM devices found: {[str(d) for d in drm_devices]}")
    else:
        print("❌ No DRM devices found")
    
    print()

def check_pygame_dependencies():
    """Check if pygame and its dependencies are available."""
    print("🎮 Checking Pygame Dependencies")
    print("=" * 35)
    
    try:
        import pygame
        print(f"✅ Pygame available: {pygame.version.ver}")
        
        # Test pygame initialization
        os.environ['SDL_VIDEODRIVER'] = 'dummy'  # Use dummy driver for testing
        pygame.init()
        print("✅ Pygame initialization successful")
        pygame.quit()
        
    except ImportError:
        print("❌ Pygame not installed")
        return False
    except Exception as e:
        print(f"❌ Pygame initialization failed: {e}")
        return False
    
    # Check SDL drivers
    print("\n🔍 Available SDL Video Drivers:")
    try:
        import pygame
        pygame.init()
        drivers = pygame.display.get_driver()
        print(f"   Current driver: {drivers}")
        pygame.quit()
    except Exception as e:
        print(f"   Could not get driver info: {e}")
    
    print()
    return True

def check_service_files():
    """Check systemd service files."""
    print("⚙️  Checking Service Files")
    print("=" * 25)
    
    service_dir = Path('/etc/systemd/system')
    face_services = list(service_dir.glob('echo_face*.service'))
    
    if not face_services:
        print("❌ No echo_face service files found in /etc/systemd/system")
        return False
    
    for service in face_services:
        print(f"✅ Found: {service.name}")
        
        # Check if enabled
        try:
            result = subprocess.run(['systemctl', 'is-enabled', service.name], 
                                  capture_output=True, text=True)
            status = result.stdout.strip()
            print(f"   Status: {status}")
        except Exception as e:
            print(f"   Could not check status: {e}")
    
    print()
    return True

def check_runtime_directories():
    """Check runtime directories and permissions."""
    print("📁 Checking Runtime Directories")
    print("=" * 35)
    
    directories = [
        '/opt/echo-ai',
        '/opt/echo-ai/.venv',
        '/opt/echo-ai/data',
        '/run/user/1000'
    ]
    
    for directory in directories:
        path = Path(directory)
        if path.exists():
            stat = path.stat()
            print(f"✅ {directory} exists")
            print(f"   Owner: {stat.st_uid}:{stat.st_gid}")
            print(f"   Permissions: {oct(stat.st_mode)[-3:]}")
        else:
            print(f"❌ {directory} does not exist")
    
    # Check .env file
    env_file = Path('/opt/echo-ai/.env')
    if env_file.exists():
        print(f"✅ .env file exists")
    else:
        print(f"❌ .env file missing")
    
    print()

def test_face_script():
    """Test running the face script directly."""
    print("🧪 Testing Face Script")
    print("=" * 25)
    
    script_path = Path('/opt/echo-ai/echo_face.py')
    if not script_path.exists():
        print("❌ echo_face.py not found")
        return False
    
    print("✅ echo_face.py exists")
    
    # Test with dummy driver
    print("🔍 Testing with dummy SDL driver...")
    env = os.environ.copy()
    env['SDL_VIDEODRIVER'] = 'dummy'
    env['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
    
    try:
        result = subprocess.run([
            '/opt/echo-ai/.venv/bin/python', 
            '/opt/echo-ai/echo_face.py'
        ], env=env, timeout=10, capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Face script runs successfully")
        else:
            print(f"❌ Face script failed with return code {result.returncode}")
            print(f"   stdout: {result.stdout}")
            print(f"   stderr: {result.stderr}")
    except subprocess.TimeoutExpired:
        print("✅ Face script started (timeout after 10s is expected)")
    except Exception as e:
        print(f"❌ Could not test face script: {e}")
    
    print()

def get_service_logs():
    """Get recent service logs."""
    print("📋 Recent Service Logs")
    print("=" * 25)
    
    try:
        result = subprocess.run([
            'journalctl', '-u', 'echo_face.service', 
            '--no-pager', '-n', '20'
        ], capture_output=True, text=True)
        
        if result.stdout:
            print(result.stdout)
        else:
            print("No logs found for echo_face.service")
    except Exception as e:
        print(f"Could not get logs: {e}")
    
    print()

def main():
    """Run all diagnostic checks."""
    print("🤖 Echo Face Service Diagnostics")
    print("=" * 40)
    print()
    
    if os.geteuid() == 0:
        print("⚠️  Running as root - some tests may not be accurate")
        print()
    
    check_user_and_groups()
    check_display_environment()
    check_pygame_dependencies()
    check_service_files()
    check_runtime_directories()
    test_face_script()
    get_service_logs()
    
    print("🔧 Recommended Fixes:")
    print("1. Add echo user to video group: sudo usermod -a -G video echo")
    print("2. Fix XDG_RUNTIME_DIR: sudo mkdir -p /run/user/1000 && sudo chown echo:echo /run/user/1000")
    print("3. Use headless service: sudo systemctl disable echo_face && sudo systemctl enable echo_face_headless")
    print("4. Check logs: journalctl -u echo_face.service -f")

if __name__ == "__main__":
    main()