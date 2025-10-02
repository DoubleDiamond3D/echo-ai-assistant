#!/bin/bash
# Setup script for Pi #1 (Echo Brain)

set -euo pipefail

echo "🧠 Setting up Echo Brain (Pi #1)"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅${NC} $1"; }
print_error() { echo -e "${RED}❌${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠️${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ️${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "Please run as root (sudo)"
   exit 1
fi

INSTALL_DIR="/opt/echo-ai"
TARGET_USER="echo"

# Create echo user if it doesn't exist
if ! id "$TARGET_USER" &>/dev/null; then
    print_info "Creating user: $TARGET_USER"
    useradd -r -s /bin/bash -d "$INSTALL_DIR" "$TARGET_USER"
fi

print_info "Installing system packages for Brain Pi..."
apt-get update
apt-get install -y \
    python3 python3-venv python3-dev python3-pip \
    git curl wget rsync \
    nginx \
    htop iotop \
    fail2ban \
    ca-certificates gnupg

print_info "Setting up Echo AI directory..."
mkdir -p "$INSTALL_DIR"
chown -R "$TARGET_USER:$TARGET_USER" "$INSTALL_DIR"

# Copy brain-specific files
print_info "Installing Brain services..."
cp -r ../services/* "$INSTALL_DIR/"
cp -r ../../app "$INSTALL_DIR/"
cp -r ../../shared "$INSTALL_DIR/"
cp ../configs/.env.brain "$INSTALL_DIR/.env"

# Set up Python virtual environment
print_info "Setting up Python environment..."
sudo -u "$TARGET_USER" python3 -m venv "$INSTALL_DIR/.venv"
sudo -u "$TARGET_USER" "$INSTALL_DIR/.venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt"

# Install Ollama
print_info "Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Install systemd services
print_info "Installing systemd services..."
cp ../configs/systemd/*.service /etc/systemd/system/
systemctl daemon-reload

# Enable Brain services
systemctl enable ollama.service
systemctl enable echo_web.service
systemctl enable echo_ai.service
systemctl enable echo_chat_log.service
systemctl enable echo_backup.service

print_info "Starting services..."
systemctl start ollama.service
sleep 5
systemctl start echo_web.service
systemctl start echo_ai.service

print_status "Pi #1 (Brain) setup complete!"
print_info "Next steps:"
echo "1. Configure .env file: nano $INSTALL_DIR/.env"
echo "2. Set Pi #2 IP address: ECHO_FACE_PI_URL=http://192.168.1.102:5001"
echo "3. Pull AI model: ollama pull qwen2.5:latest"
echo "4. Access web interface: http://$(hostname -I | awk '{print $1}'):5000"