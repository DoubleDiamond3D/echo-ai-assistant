#!/bin/bash
# Echo AI Assistant - Deploy to Pi #2 (Face)
# This script sets up the Face Pi with display and interface capabilities

set -e

echo "🎭 Echo AI Assistant - Pi #2 (Face) Deployment"
echo "==============================================="

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

# Copy Pi2 specific files
echo "📋 Copying Pi #2 (Face) files..."
cp -r "$REPO_ROOT/pi2-face/"* "$DEPLOY_DIR/"

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
if [ -d "$DEPLOY_DIR/configs/systemd" ]; then
    sudo cp "$DEPLOY_DIR/configs/systemd/"*.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable echo_face.service
fi

# Create .env file if it doesn't exist
if [ ! -f "$DEPLOY_DIR/.env" ]; then
    echo "📝 Creating .env configuration..."
    cat > "$DEPLOY_DIR/.env" << EOF
# Pi #2 (Face) Configuration
ECHO_ROLE=face
ECHO_BRAIN_PI_URL=http://192.168.1.101:5000
OLLAMA_URL=http://192.168.1.101:11434
ECHO_WEB_INTERFACE_ENABLED=0
ECHO_BACKUP_ENABLED=0
ECHO_FACE_DISPLAY_ENABLED=1
ECHO_VOICE_INPUT_ENABLED=1
ECHO_CAMERA_ENABLED=1
ECHO_API_TOKEN=echo-dev-kit-2025
EOF
    echo "⚠️  Please edit $DEPLOY_DIR/.env with your specific configuration"
fi

# Run Pi2-specific setup
if [ -f "$DEPLOY_DIR/scripts/setup_pi2_face.sh" ]; then
    echo "🔧 Running Pi #2 setup script..."
    bash "$DEPLOY_DIR/scripts/setup_pi2_face.sh"
fi

echo ""
echo "✅ Pi #2 (Face) deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Edit $DEPLOY_DIR/.env with your Pi #1 IP address"
echo "2. Start services: sudo systemctl start echo_face.service"
echo "3. Check status: sudo systemctl status echo_face.service"
echo "4. Test display: python3 $DEPLOY_DIR/scripts/test_face_display.py"
echo ""
echo "📖 See docs/DUAL_PI_ARCHITECTURE.md for complete setup guide"
