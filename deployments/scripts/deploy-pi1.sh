#!/bin/bash
# Echo AI Assistant - Deploy to Pi #1 (Brain)
# This script sets up the Brain Pi with AI processing capabilities

set -e

echo "🧠 Echo AI Assistant - Pi #1 (Brain) Deployment"
echo "================================================"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "❌ Don't run this script as root. Run as the echo user."
    exit 1
fi

# Set deployment directory
DEPLOY_DIR="/opt/echo-ai"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📍 Deploying from: $REPO_ROOT"
echo "📍 Target directory: $DEPLOY_DIR"

# Create deployment directory if it doesn't exist
sudo mkdir -p "$DEPLOY_DIR"
sudo chown echo:echo "$DEPLOY_DIR"

# Copy Pi1 specific files
echo "📋 Copying Pi #1 (Brain) files..."
cp -r "$REPO_ROOT/pi1-brain/"* "$DEPLOY_DIR/"

# Copy shared components
echo "📋 Copying shared components..."
cp -r "$REPO_ROOT/shared/"* "$DEPLOY_DIR/"

# Copy documentation
cp -r "$REPO_ROOT/docs" "$DEPLOY_DIR/"

# Make scripts executable
find "$DEPLOY_DIR/scripts" -name "*.sh" -exec chmod +x {} \;

# Set up Python environment
echo "🐍 Setting up Python environment..."
cd "$DEPLOY_DIR"
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Install systemd services
echo "⚙️  Installing systemd services..."
sudo cp systemd/echo_web.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable echo_web.service

# Create .env file if it doesn't exist
if [ ! -f "$DEPLOY_DIR/.env" ]; then
    echo "📝 Creating .env configuration..."
    cat > "$DEPLOY_DIR/.env" << EOF
# Pi #1 (Brain) Configuration
ECHO_ROLE=brain
ECHO_FACE_PI_URL=http://192.168.1.102:5001
OLLAMA_URL=http://localhost:11434
ECHO_FACE_DISPLAY_ENABLED=0
ECHO_VOICE_INPUT_ENABLED=0
ECHO_CAMERA_ENABLED=0
ECHO_API_TOKEN=echo-dev-kit-2025
ECHO_AI_MODEL=qwen2.5:latest
EOF
    echo "⚠️  Please edit $DEPLOY_DIR/.env with your specific configuration"
fi

# Run Pi1-specific setup
if [ -f "$DEPLOY_DIR/scripts/setup_pi1_brain.sh" ]; then
    echo "🔧 Running Pi #1 setup script..."
    bash "$DEPLOY_DIR/scripts/setup_pi1_brain.sh"
fi

echo ""
echo "✅ Pi #1 (Brain) deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Edit $DEPLOY_DIR/.env with your configuration"
echo "2. Start services: sudo systemctl start echo_web.service"
echo "3. Check status: sudo systemctl status echo_web.service"
echo "4. Access web interface: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "📖 See docs/DUAL_PI_ARCHITECTURE.md for complete setup guide"
