#!/bin/bash
# Setup script for Pi #2 (Echo Face)

set -euo pipefail

echo "🎭 Setting up Echo Face (Pi #2)"
echo "==============================="

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
    usermod -a -G video,audio,input,render "$TARGET_USER"
fi

print_info "Installing system packages for Face Pi..."
apt-get update
apt-get install -y \
    python3 python3-venv python3-dev python3-pip \
    python3-pygame python3-opencv \
    portaudio19-dev python3-pyaudio \
    espeak espeak-data libespeak-dev \
    git curl wget \
    v4l-utils \
    alsa-utils pulseaudio \
    htop

print_info "Configuring graphics and audio..."
# Enable GPU memory split
if ! grep -q "gpu_mem=128" /boot/config.txt; then
    echo "gpu_mem=128" >> /boot/config.txt
fi

# Enable hardware acceleration
if ! grep -q "dtoverlay=vc4-kms-v3d" /boot/config.txt; then
    echo "dtoverlay=vc4-kms-v3d" >> /boot/config.txt
fi

# Disable screen blanking
if ! grep -q "consoleblank=0" /boot/cmdline.txt; then
    sed -i 's/$/ consoleblank=0/' /boot/cmdline.txt
fi

print_info "Setting up Echo AI directory..."
mkdir -p "$INSTALL_DIR"
chown -R "$TARGET_USER:$TARGET_USER" "$INSTALL_DIR"

# Copy face-specific files
print_info "Installing Face services..."
cp -r ../services/* "$INSTALL_DIR/"
cp -r ../../shared "$INSTALL_DIR/"
cp ../configs/.env.face "$INSTALL_DIR/.env"

# Set up Python virtual environment
print_info "Setting up Python environment..."
sudo -u "$TARGET_USER" python3 -m venv "$INSTALL_DIR/.venv"
sudo -u "$TARGET_USER" "$INSTALL_DIR/.venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt"

# Install wake word detection
print_info "Installing wake word detection..."
sudo -u "$TARGET_USER" "$INSTALL_DIR/.venv/bin/pip" install pvporcupine

# Install systemd services
print_info "Installing systemd services..."
cp ../configs/systemd/*.service /etc/systemd/system/
systemctl daemon-reload

# Enable Face services
systemctl enable echo_face.service
systemctl enable echo_voice_input.service
systemctl enable echo_wake_word.service
systemctl enable echo_camera.service
systemctl enable echo_speech_output.service

print_status "Pi #2 (Face) setup complete!"
print_warning "REBOOT REQUIRED for graphics changes to take effect"
print_info "Next steps:"
echo "1. Reboot the Pi: sudo reboot"
echo "2. Configure .env file: nano $INSTALL_DIR/.env"
echo "3. Set Pi #1 IP address: ECHO_BRAIN_PI_URL=http://192.168.1.101:5000"
echo "4. Test display: sudo systemctl start echo_face.service"
echo "5. Check face display on connected monitor/screen"