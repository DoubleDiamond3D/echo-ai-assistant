#!/usr/bin/env python3
"""Setup script for wake word detection with pvporcupine."""

import os
import sys
import subprocess
from pathlib import Path

def install_pvporcupine():
    """Install pvporcupine package."""
    print("📦 Installing pvporcupine...")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "pvporcupine"], check=True)
        print("✅ pvporcupine installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install pvporcupine: {e}")
        return False

def install_pyaudio():
    """Install pyaudio package."""
    print("📦 Installing pyaudio...")
    try:
        # Try to install system dependencies first (Raspberry Pi)
        try:
            subprocess.run(["sudo", "apt-get", "update"], check=True, capture_output=True)
            subprocess.run(["sudo", "apt-get", "install", "-y", "portaudio19-dev", "python3-pyaudio"], check=True, capture_output=True)
            print("✅ System audio dependencies installed")
        except subprocess.CalledProcessError:
            print("⚠️  Could not install system dependencies (may not be needed)")
        
        # Install Python package
        subprocess.run([sys.executable, "-m", "pip", "install", "pyaudio"], check=True)
        print("✅ pyaudio installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install pyaudio: {e}")
        print("💡 Try: sudo apt-get install portaudio19-dev python3-pyaudio")
        return False

def test_wake_word():
    """Test wake word detection setup."""
    print("\n🧪 Testing wake word detection...")
    
    try:
        import pvporcupine
        print("✅ pvporcupine imported successfully")
    except ImportError:
        print("❌ pvporcupine not available")
        return False
    
    try:
        import pyaudio
        print("✅ pyaudio imported successfully")
    except ImportError:
        print("❌ pyaudio not available")
        return False
    
    # Check for access key
    access_key = os.getenv('PORCUPINE_ACCESS_KEY', '')
    if not access_key or access_key == 'your-porcupine-api-key-here':
        print("⚠️  PORCUPINE_ACCESS_KEY not set")
        print("🔗 Get your free API key from: https://console.picovoice.ai/")
        print("📝 Add to your .env file: PORCUPINE_ACCESS_KEY=your-actual-key")
        return False
    else:
        print(f"✅ Porcupine access key configured: {access_key[:10]}...")
    
    # Test Porcupine initialization
    try:
        porcupine = pvporcupine.create(
            access_key=access_key,
            keywords=['hey echo'],
            sensitivities=[0.5]
        )
        porcupine.delete()
        print("✅ Porcupine initialization test passed")
        return True
    except Exception as e:
        print(f"❌ Porcupine initialization failed: {e}")
        if "invalid access key" in str(e).lower():
            print("🔑 Your access key appears to be invalid")
            print("🔗 Get a new key from: https://console.picovoice.ai/")
        return False

def list_audio_devices():
    """List available audio input devices."""
    print("\n🎤 Available Audio Devices:")
    print("=" * 30)
    
    try:
        import pyaudio
        audio = pyaudio.PyAudio()
        
        for i in range(audio.get_device_count()):
            device_info = audio.get_device_info_by_index(i)
            if device_info['maxInputChannels'] > 0:  # Input device
                print(f"Device {i}: {device_info['name']}")
                print(f"  Channels: {device_info['maxInputChannels']}")
                print(f"  Sample Rate: {device_info['defaultSampleRate']}")
                print()
        
        audio.terminate()
    except Exception as e:
        print(f"❌ Could not list audio devices: {e}")

def update_env_file():
    """Update .env file with wake word settings."""
    print("\n📝 Updating .env file...")
    
    env_paths = [
        Path(".env"),
        Path("/opt/echo-ai/.env")
    ]
    
    env_file = None
    for path in env_paths:
        if path.exists():
            env_file = path
            break
    
    if not env_file:
        print("⚠️  No .env file found. Creating one...")
        env_file = Path(".env")
    
    # Read existing content
    existing_content = ""
    if env_file.exists():
        existing_content = env_file.read_text()
    
    # Add wake word settings if not present
    wake_word_settings = """
# Wake Word Detection (pvporcupine)
ECHO_WAKE_WORD_ENABLED=1
ECHO_WAKE_WORD_ENGINE=porcupine
ECHO_WAKE_WORD_KEYWORD=hey echo
ECHO_WAKE_WORD_SENSITIVITY=0.5
PORCUPINE_ACCESS_KEY=your-porcupine-api-key-here
"""
    
    if "ECHO_WAKE_WORD_ENABLED" not in existing_content:
        with open(env_file, "a") as f:
            f.write(wake_word_settings)
        print(f"✅ Wake word settings added to {env_file}")
        print("🔑 Don't forget to set your PORCUPINE_ACCESS_KEY!")
    else:
        print("ℹ️  Wake word settings already present in .env file")

def main():
    """Main setup function."""
    print("🤖 Echo AI - Wake Word Detection Setup")
    print("=" * 40)
    print()
    
    # Check Python version
    if sys.version_info < (3, 7):
        print("❌ Python 3.7+ required")
        return 1
    
    print(f"✅ Python {sys.version_info.major}.{sys.version_info.minor}")
    print()
    
    # Install dependencies
    success = True
    
    if not install_pyaudio():
        success = False
    
    if not install_pvporcupine():
        success = False
    
    if not success:
        print("\n❌ Installation failed. Please fix the errors above.")
        return 1
    
    # Update .env file
    update_env_file()
    
    # List audio devices
    list_audio_devices()
    
    # Test setup
    if test_wake_word():
        print("\n🎉 Wake word detection setup complete!")
        print("\n📋 Next steps:")
        print("1. Set your PORCUPINE_ACCESS_KEY in the .env file")
        print("2. Restart Echo AI services")
        print("3. Say 'Hey Echo' to test wake word detection")
        return 0
    else:
        print("\n⚠️  Setup incomplete. Please fix the issues above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())