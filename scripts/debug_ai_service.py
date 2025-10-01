#!/usr/bin/env python3
"""Debug the AI service to see why it's not connecting to Ollama."""

import os
import sys
from pathlib import Path

# Add the app directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import Settings
from app.utils.env import load_first_existing
from app.services.state_service import StateService
from app.services.ai_service import AIService

def debug_ai_service():
    """Debug the AI service configuration and connection."""
    print("🤖 Echo AI Service Debug")
    print("=" * 30)
    
    # Load environment
    base_dir = Path(__file__).parent.parent
    load_first_existing([base_dir / ".env", base_dir.parent / ".env", Path("/opt/echo-ai/.env")])
    
    # Load settings
    settings = Settings.from_env(base_dir)
    
    print(f"📁 Base directory: {base_dir}")
    print(f"📄 Data directory: {settings.data_dir}")
    print(f"🌐 Ollama URL: '{settings.ollama_url}'")
    print(f"🤖 AI Model: '{settings.ai_model}'")
    print(f"⏱️  Request timeout: {settings.request_timeout}s")
    print()
    
    # Check if Ollama URL is set
    if not settings.ollama_url:
        print("❌ OLLAMA_URL is not set or empty!")
        print("🔧 This is why the AI is using fallback responses.")
        print()
        print("💡 To fix this:")
        print("1. Add OLLAMA_URL=http://localhost:11434 to your .env file")
        print("2. Or set the environment variable: export OLLAMA_URL=http://localhost:11434")
        print("3. Restart the echo_web.service")
        return False
    
    print("✅ Ollama URL is configured")
    
    # Create state service
    state_service = StateService(settings.data_dir / "echo_state.json")
    
    # Create AI service
    ai_service = AIService(settings, state_service)
    
    # Test a simple message
    print("🧪 Testing AI service with a simple message...")
    try:
        response = ai_service.process_input("What is the capital of Montana?")
        print(f"📝 Response: {response.response_text}")
        print(f"🎯 Confidence: {response.confidence}")
        print(f"🔧 Action: {response.action}")
        
        if response.confidence > 0.7 and "I understand you said:" not in response.response_text:
            print("✅ AI service is working with Ollama!")
            return True
        else:
            print("❌ AI service is using fallback responses")
            return False
            
    except Exception as e:
        print(f"❌ Error testing AI service: {e}")
        return False

def check_environment_files():
    """Check all possible .env file locations."""
    print("📄 Checking Environment Files")
    print("=" * 35)
    
    env_locations = [
        Path(".env"),
        Path("/opt/echo-ai/.env"),
        Path.home() / ".env"
    ]
    
    found_env = False
    for env_path in env_locations:
        if env_path.exists():
            print(f"✅ Found: {env_path}")
            found_env = True
            
            # Check for OLLAMA_URL
            content = env_path.read_text()
            if "OLLAMA_URL" in content:
                for line in content.split('\n'):
                    if line.startswith('OLLAMA_URL'):
                        print(f"   {line}")
            else:
                print("   ❌ No OLLAMA_URL found in this file")
        else:
            print(f"❌ Not found: {env_path}")
    
    if not found_env:
        print("❌ No .env files found!")
    
    print()

def main():
    """Main debug function."""
    check_environment_files()
    
    success = debug_ai_service()
    
    if not success:
        print("\n🔧 Quick Fix:")
        print("1. Find your .env file (probably /opt/echo-ai/.env)")
        print("2. Add this line: OLLAMA_URL=http://localhost:11434")
        print("3. Restart: sudo systemctl restart echo_web.service")
        print("4. Test again with this script")

if __name__ == "__main__":
    main()