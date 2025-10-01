#!/usr/bin/env python3
"""Test script to diagnose Ollama connection issues."""

import os
import sys
import requests
import json
from pathlib import Path

# Add the app directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import Settings
from app.utils.env import load_first_existing

def test_ollama_connection():
    """Test connection to Ollama server."""
    
    # Load environment
    base_dir = Path(__file__).parent.parent
    load_first_existing([base_dir / ".env", base_dir.parent / ".env"])
    
    # Load settings
    settings = Settings.from_env(base_dir)
    
    print("🤖 Echo AI - Ollama Connection Test")
    print("=" * 40)
    print(f"Ollama URL: {settings.ollama_url}")
    print(f"AI Model: {settings.ai_model}")
    print(f"Request Timeout: {settings.request_timeout}s")
    print()
    
    if not settings.ollama_url:
        print("❌ ERROR: OLLAMA_URL not configured in .env file")
        print("Please set OLLAMA_URL=http://your-ollama-server:11434")
        return False
    
    # Test 1: Basic connectivity
    print("🔍 Test 1: Basic connectivity...")
    try:
        response = requests.get(f"{settings.ollama_url}/api/tags", timeout=10)
        if response.status_code == 200:
            print("✅ Ollama server is reachable")
            models = response.json().get("models", [])
            print(f"📋 Available models: {len(models)}")
            for model in models:
                print(f"   - {model.get('name', 'Unknown')}")
        else:
            print(f"❌ Ollama server returned status {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to Ollama server")
        print("   - Check if Ollama is running")
        print("   - Verify the URL is correct")
        print("   - Check network connectivity")
        return False
    except requests.exceptions.Timeout:
        print("❌ Connection timeout")
        print("   - Server may be slow to respond")
        print("   - Try increasing timeout")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False
    
    print()
    
    # Test 2: Model availability
    print("🔍 Test 2: Model availability...")
    try:
        response = requests.get(f"{settings.ollama_url}/api/tags", timeout=10)
        models = response.json().get("models", [])
        model_names = [model.get("name", "") for model in models]
        
        if settings.ai_model in model_names:
            print(f"✅ Model '{settings.ai_model}' is available")
        else:
            print(f"❌ Model '{settings.ai_model}' not found")
            print("Available models:")
            for name in model_names:
                print(f"   - {name}")
            print(f"\nTo pull the model, run:")
            print(f"   ollama pull {settings.ai_model}")
            return False
    except Exception as e:
        print(f"❌ Error checking models: {e}")
        return False
    
    print()
    
    # Test 3: Chat API
    print("🔍 Test 3: Chat API test...")
    try:
        payload = {
            "model": settings.ai_model,
            "messages": [
                {"role": "system", "content": "You are a helpful AI assistant. Respond briefly."},
                {"role": "user", "content": "Hello, can you hear me?"}
            ],
            "stream": False,
            "options": {
                "temperature": 0.7,
                "max_tokens": 50
            }
        }
        
        print("📤 Sending test message...")
        response = requests.post(
            f"{settings.ollama_url}/api/chat",
            json=payload,
            timeout=settings.request_timeout,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            result = response.json()
            ai_message = result.get("message", {}).get("content", "")
            print(f"✅ Chat API working!")
            print(f"📝 AI Response: {ai_message}")
        else:
            print(f"❌ Chat API error: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Chat API test failed: {e}")
        return False
    
    print()
    print("🎉 All tests passed! Ollama connection is working correctly.")
    return True

def test_cloudflare_tunnel():
    """Test if we're behind a Cloudflare tunnel."""
    print("\n🌐 Cloudflare Tunnel Test")
    print("=" * 30)
    
    # Check if we have a tunnel token
    tunnel_token = os.environ.get("CLOUDFLARE_TUNNEL_TOKEN", "")
    if tunnel_token:
        print(f"✅ Cloudflare tunnel token configured")
        print(f"Token: {tunnel_token[:20]}...")
    else:
        print("ℹ️  No Cloudflare tunnel token found")
    
    # Test external connectivity
    try:
        response = requests.get("https://httpbin.org/ip", timeout=10)
        if response.status_code == 200:
            ip_info = response.json()
            print(f"📍 External IP: {ip_info.get('origin', 'Unknown')}")
        else:
            print("❌ Cannot determine external IP")
    except Exception as e:
        print(f"❌ External connectivity test failed: {e}")

if __name__ == "__main__":
    success = test_ollama_connection()
    test_cloudflare_tunnel()
    
    if not success:
        print("\n🔧 Troubleshooting Tips:")
        print("1. Make sure Ollama is running: systemctl status ollama")
        print("2. Check if the model is pulled: ollama list")
        print("3. Test Ollama directly: curl http://localhost:11434/api/tags")
        print("4. Check firewall settings")
        print("5. Verify network connectivity")
        sys.exit(1)
    else:
        print("\n✅ Everything looks good! Your Echo AI should be able to connect to Ollama.")
