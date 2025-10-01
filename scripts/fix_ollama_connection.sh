#!/bin/bash
# Complete fix script for Echo AI Ollama connection issues

set -e

echo "🤖 Echo AI - Ollama Connection Fix"
echo "=================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "Don't run this script as root. Run as the echo user."
   exit 1
fi

# 1. Check current directory
if [[ ! -f "app/services/ai_service.py" ]]; then
    print_error "Please run this script from the echo-ai-assistant directory"
    exit 1
fi

print_info "Running from correct directory"

# 2. Update the repository
print_info "Updating repository..."
git pull origin main || print_warning "Could not update repository (continuing anyway)"

# 3. Check if Ollama is running
print_info "Checking Ollama service..."
if systemctl is-active --quiet ollama; then
    print_status "Ollama service is running"
else
    print_warning "Ollama service is not running"
    print_info "Starting Ollama service..."
    sudo systemctl start ollama || print_error "Could not start Ollama"
fi

# 4. Check if the model is available
print_info "Checking if AI model is available..."
OLLAMA_URL=${OLLAMA_URL:-"http://localhost:11434"}
AI_MODEL=${ECHO_AI_MODEL:-"qwen2.5:latest"}

if curl -s "$OLLAMA_URL/api/tags" | grep -q "$AI_MODEL"; then
    print_status "Model $AI_MODEL is available"
else
    print_warning "Model $AI_MODEL not found"
    print_info "Pulling model $AI_MODEL (this may take a while)..."
    ollama pull "$AI_MODEL" || print_error "Could not pull model"
fi

# 5. Update environment file
print_info "Checking environment configuration..."
ENV_FILE="/opt/echo-ai/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    ENV_FILE=".env"
fi

if [[ ! -f "$ENV_FILE" ]]; then
    print_warning "No .env file found, creating one..."
    cp .env.example "$ENV_FILE"
fi

# Update OLLAMA_URL if not set
if ! grep -q "OLLAMA_URL=" "$ENV_FILE"; then
    echo "OLLAMA_URL=http://localhost:11434" >> "$ENV_FILE"
    print_status "Added OLLAMA_URL to .env"
fi

# Update AI_MODEL if not set
if ! grep -q "ECHO_AI_MODEL=" "$ENV_FILE"; then
    echo "ECHO_AI_MODEL=qwen2.5:latest" >> "$ENV_FILE"
    print_status "Added ECHO_AI_MODEL to .env"
fi

# 6. Install Python dependencies
print_info "Installing/updating Python dependencies..."
pip3 install --user -r requirements.txt || print_warning "Some dependencies may have failed to install"

# 7. Install wake word detection
print_info "Setting up wake word detection..."
pip3 install --user pvporcupine pyaudio || print_warning "Wake word dependencies may have failed"

# 8. Restart Echo AI services
print_info "Restarting Echo AI services..."
sudo systemctl restart echo_web.service || print_warning "Could not restart echo_web.service"
sudo systemctl restart echo_face.service || print_warning "Could not restart echo_face.service"

# 9. Wait for services to start
print_info "Waiting for services to start..."
sleep 5

# 10. Run diagnostics
print_info "Running diagnostics..."
python3 scripts/diagnose_connection.py

echo
print_status "Fix script completed!"
echo
print_info "Next steps:"
echo "1. Check the diagnostic output above"
echo "2. If Ollama is working, test the web interface at http://localhost:5000"
echo "3. For remote access, set up your Cloudflare tunnel"
echo "4. Set your PORCUPINE_ACCESS_KEY for wake word detection"
echo
print_info "Troubleshooting:"
echo "- View logs: journalctl -u echo_web.service -f"
echo "- Test Ollama: curl http://localhost:11434/api/tags"
echo "- Test AI chat: python3 scripts/test_ollama.py"