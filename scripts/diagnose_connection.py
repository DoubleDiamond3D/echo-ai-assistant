#!/usr/bin/env python3
"""Diagnose Echo AI connection issues, especially for Cloudflare tunnel setups."""

import os
import sys
import requests
import json
import subprocess
from pathlib import Path

# Add the app directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

def check_local_services():
    """Check if local services are running."""
    print("🔍 Checking Local Services")
    print("=" * 30)
    
    services = [
        "echo_web.service",
        "echo_face.service", 
        "ollama.service"
    ]
    
    for service in services:
        try:
            result = subprocess.run(
                ["systemctl", "is-active", service],
                capture_output=True,
                text=True,
                timeout=5
            )
            status = result.stdout.strip()
            if status == "active":
                print(f"✅ {service}: {status}")
            else:
                print(f"❌ {service}: {status}")
        except Exception as e:
            print(f"❓ {service}: Could not check ({e})")
    
    print()

def check_ports():
    """Check if required ports are listening."""
    print("🔍 Checking Port Availability")
    print("=" * 30)
    
    ports = {
        5000: "Echo AI Web Interface",
        11434: "Ollama API Server"
    }
    
    for port, description in ports.items():
        try:
            result = subprocess.run(
                ["netstat", "-tlnp"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if f":{port} " in result.stdout:
                print(f"✅ Port {port} ({description}): Listening")
            else:
                print(f"❌ Port {port} ({description}): Not listening")
        except Exception as e:
            print(f"❓ Port {port}: Could not check ({e})")
    
    print()

def test_local_api():
    """Test local API endpoints."""
    print("🔍 Testing Local API")
    print("=" * 25)
    
    # Load API token from environment
    api_token = os.environ.get("ECHO_API_TOKEN", "change-me")
    headers = {"X-API-Key": api_token}
    
    endpoints = [
        ("/api/health", "Health Check"),
        ("/api/status", "System Status"),
        ("/api/state", "Robot State")
    ]
    
    for endpoint, description in endpoints:
        try:
            response = requests.get(
                f"http://localhost:5000{endpoint}",
                headers=headers,
                timeout=10
            )
            if response.status_code == 200:
                print(f"✅ {description}: OK")
            else:
                print(f"❌ {description}: HTTP {response.status_code}")
                print(f"   Response: {response.text[:100]}")
        except requests.exceptions.ConnectionError:
            print(f"❌ {description}: Connection refused")
        except Exception as e:
            print(f"❌ {description}: {e}")
    
    print()

def test_ollama_connection():
    """Test Ollama connection."""
    print("🔍 Testing Ollama Connection")
    print("=" * 30)
    
    ollama_url = os.environ.get("OLLAMA_URL", "http://localhost:11434")
    ai_model = os.environ.get("ECHO_AI_MODEL", "qwen2.5:latest")
    
    print(f"Ollama URL: {ollama_url}")
    print(f"AI Model: {ai_model}")
    print()
    
    # Test basic connectivity
    try:
        response = requests.get(f"{ollama_url}/api/tags", timeout=10)
        if response.status_code == 200:
            print("✅ Ollama server reachable")
            models = response.json().get("models", [])
            model_names = [m.get("name", "") for m in models]
            
            if ai_model in model_names:
                print(f"✅ Model '{ai_model}' available")
            else:
                print(f"❌ Model '{ai_model}' not found")
                print("Available models:")
                for name in model_names:
                    print(f"   - {name}")
        else:
            print(f"❌ Ollama server error: {response.status_code}")
    except Exception as e:
        print(f"❌ Ollama connection failed: {e}")
    
    print()

def test_ai_chat():
    """Test AI chat functionality."""
    print("🔍 Testing AI Chat")
    print("=" * 20)
    
    api_token = os.environ.get("ECHO_API_TOKEN", "change-me")
    headers = {
        "X-API-Key": api_token,
        "Content-Type": "application/json"
    }
    
    payload = {
        "message": "Hello, this is a test message. Please respond briefly."
    }
    
    try:
        response = requests.post(
            "http://localhost:5000/api/ai/chat",
            headers=headers,
            json=payload,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            ai_response = result.get("response", "")
            print(f"✅ AI Chat working!")
            print(f"📝 AI Response: {ai_response}")
        else:
            print(f"❌ AI Chat failed: HTTP {response.status_code}")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"❌ AI Chat error: {e}")
    
    print()

def check_cloudflare_tunnel():
    """Check Cloudflare tunnel status."""
    print("🔍 Checking Cloudflare Tunnel")
    print("=" * 30)
    
    tunnel_token = os.environ.get("CLOUDFLARE_TUNNEL_TOKEN", "")
    if tunnel_token:
        print(f"✅ Tunnel token configured: {tunnel_token[:20]}...")
    else:
        print("ℹ️  No tunnel token found")
    
    # Check if cloudflared is running
    try:
        result = subprocess.run(
            ["systemctl", "is-active", "cloudflared"],
            capture_output=True,
            text=True,
            timeout=5
        )
        status = result.stdout.strip()
        if status == "active":
            print("✅ Cloudflared service: active")
        else:
            print(f"❌ Cloudflared service: {status}")
    except Exception as e:
        print(f"❓ Cloudflared service: Could not check ({e})")
    
    # Check tunnel processes
    try:
        result = subprocess.run(
            ["pgrep", "-f", "cloudflared"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            print("✅ Cloudflared process running")
        else:
            print("❌ Cloudflared process not found")
    except Exception as e:
        print(f"❓ Cloudflared process: Could not check ({e})")
    
    print()

def check_network():
    """Check network connectivity."""
    print("🔍 Checking Network Connectivity")
    print("=" * 35)
    
    # Test internet connectivity
    try:
        response = requests.get("https://httpbin.org/ip", timeout=10)
        if response.status_code == 200:
            ip_info = response.json()
            print(f"✅ Internet connectivity: OK")
            print(f"📍 External IP: {ip_info.get('origin', 'Unknown')}")
        else:
            print("❌ Internet connectivity: Failed")
    except Exception as e:
        print(f"❌ Internet connectivity: {e}")
    
    # Test DNS resolution
    try:
        import socket
        socket.gethostbyname("google.com")
        print("✅ DNS resolution: OK")
    except Exception as e:
        print(f"❌ DNS resolution: {e}")
    
    print()

def main():
    """Run all diagnostic checks."""
    print("🤖 Echo AI Assistant - Connection Diagnostics")
    print("=" * 50)
    print()
    
    # Load environment variables
    env_files = [
        Path(__file__).parent.parent / ".env",
        Path("/opt/echo-ai/.env")
    ]
    
    for env_file in env_files:
        if env_file.exists():
            print(f"📄 Loading environment from: {env_file}")
            with open(env_file) as f:
                for line in f:
                    if line.strip() and not line.startswith("#"):
                        key, _, value = line.partition("=")
                        os.environ[key.strip()] = value.strip()
            break
    else:
        print("⚠️  No .env file found")
    
    print()
    
    # Run all checks
    check_local_services()
    check_ports()
    test_local_api()
    test_ollama_connection()
    test_ai_chat()
    check_cloudflare_tunnel()
    check_network()
    
    print("🏁 Diagnostic Complete")
    print("=" * 20)
    print()
    print("💡 Troubleshooting Tips:")
    print("1. If services are not active: sudo systemctl start echo_web.service")
    print("2. If Ollama is not reachable: sudo systemctl start ollama")
    print("3. If model is missing: ollama pull qwen2.5:latest")
    print("4. Check logs: journalctl -u echo_web.service -f")
    print("5. Test Ollama directly: curl http://localhost:11434/api/tags")

if __name__ == "__main__":
    main()
