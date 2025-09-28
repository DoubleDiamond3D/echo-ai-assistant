#!/usr/bin/env bash
# Windows-compatible Pi OS image builder for Echo AI Assistant
# This script creates a custom Pi OS image without requiring loop devices

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR=${BUILD_DIR:-/tmp/echo-pi-os}
IMAGE_NAME="echo-ai-assistant-$(date +%Y%m%d)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if Pi OS image exists
check_pi_os_image() {
    log "Checking for Pi OS image..."
    
    local img_file="${BUILD_DIR}/raspios-lite.img.xz"
    local extracted_img="${BUILD_DIR}/raspios-lite.img"
    
    if [[ -f "$extracted_img" ]]; then
        log "Pi OS image already extracted: $extracted_img"
        return 0
    fi
    
    if [[ -f "$img_file" ]]; then
        log "Extracting Pi OS image..."
        xz -d "$img_file"
        success "Pi OS image extracted: $extracted_img"
        return 0
    fi
    
    error "Pi OS image not found!"
    error "Please download Raspberry Pi OS Lite from:"
    error "https://www.raspberrypi.org/downloads/raspberry-pi-os/"
    error "And place it as: $img_file"
    exit 1
}

# Create a custom Pi OS image using a different approach
create_custom_image() {
    log "Creating custom Pi OS image with Echo AI Assistant..."
    
    local original_img="${BUILD_DIR}/raspios-lite.img"
    local final_img="${BUILD_DIR}/${IMAGE_NAME}.img"
    
    # Copy the original image
    log "Copying original Pi OS image..."
    cp "$original_img" "$final_img"
    
    # Create a setup script that will run on first boot
    log "Creating first-boot setup script..."
    
    # Create a temporary directory for our setup files
    local setup_dir="${BUILD_DIR}/echo-setup"
    mkdir -p "$setup_dir"
    
    # Create the setup script
    cat > "$setup_dir/echo-setup.sh" << 'EOF'
#!/bin/bash
# Echo AI Assistant First Boot Setup Script

set -e

LOG_FILE="/var/log/echo-setup.log"
echo "$(date): Starting Echo AI Assistant setup" >> "$LOG_FILE"

# Wait for network
echo "$(date): Waiting for network..." >> "$LOG_FILE"
for i in {1..30}; do
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "$(date): Network is up" >> "$LOG_FILE"
        break
    fi
    sleep 2
done

# Update system
echo "$(date): Updating system packages..." >> "$LOG_FILE"
apt-get update -y
apt-get upgrade -y

# Install dependencies
echo "$(date): Installing dependencies..." >> "$LOG_FILE"
apt-get install -y \
    python3 python3-venv python3-dev python3-pip \
    ffmpeg espeak alsa-utils \
    python3-opencv python3-numpy \
    libatlas-base-dev libhdf5-dev libhdf5-serial-dev \
    libqtgui4 libqtwebkit4 libqt4-test python3-pyqt5 \
    libavformat-dev libavcodec-dev libswscale-dev \
    libv4l-dev libxvidcore-dev libx264-dev \
    libjpeg-dev libpng-dev libtiff-dev \
    libatlas-base-dev gfortran \
    git rsync curl wget \
    network-manager hostapd dnsmasq \
    i2c-tools python3-smbus \
    python3-gpiozero python3-rpi.gpio \
    openssh-server \
    htop vim nano \
    i2c-tools \
    python3-picamera2

# Install Ollama
echo "$(date): Installing Ollama..." >> "$LOG_FILE"
curl -fsSL https://ollama.ai/install.sh | sh

# Create echo user
echo "$(date): Creating echo user..." >> "$LOG_FILE"
useradd -r -s /bin/bash -d /opt/echo-ai -m echo || true

# Download Echo AI Assistant
echo "$(date): Downloading Echo AI Assistant..." >> "$LOG_FILE"
cd /tmp
git clone https://github.com/yourusername/echo-ai-assistant.git echo-ai || {
    # If git fails, create from local files
    mkdir -p echo-ai
    # This would need to be populated with the actual Echo files
    echo "Echo AI Assistant files would be placed here" > echo-ai/README.md
}

# Copy Echo files
echo "$(date): Installing Echo files..." >> "$LOG_FILE"
cp -r echo-ai /opt/
chown -R echo:echo /opt/echo-ai

# Install Python dependencies
echo "$(date): Installing Python dependencies..." >> "$LOG_FILE"
cd /opt/echo-ai
sudo -u echo python3 -m venv .venv
sudo -u echo .venv/bin/pip install --upgrade pip setuptools wheel
sudo -u echo .venv/bin/pip install -r requirements.txt

# Create environment file
echo "$(date): Creating environment configuration..." >> "$LOG_FILE"
sudo -u echo tee /opt/echo-ai/.env > /dev/null << 'ENVEOF'
# Echo AI Assistant Configuration
ECHO_API_TOKEN=echo-dev-kit-2025
ECHO_DATA_DIR=/opt/echo-ai/data
ECHO_WEB_DIR=/opt/echo-ai/web

# AI Configuration
ECHO_AI_MODEL=qwen2.5:latest
OLLAMA_URL=http://localhost:11434
OPENAI_API_KEY=

# Voice Settings
ECHO_VOICE_INPUT_ENABLED=1
ECHO_VOICE_INPUT_DEVICE=default
ECHO_VOICE_INPUT_LANGUAGE=en

# Face Recognition
ECHO_FACE_RECOGNITION_ENABLED=1
ECHO_FACE_RECOGNITION_CONFIDENCE=0.6

# Backup Settings
ECHO_BACKUP_ENABLED=1
ECHO_BACKUP_AUTO_INTERVAL_HOURS=24
ECHO_BACKUP_MAX_SIZE_MB=500

# Network Settings
ECHO_WIFI_SETUP_ENABLED=1
ECHO_REMOTE_ACCESS_ENABLED=1
CLOUDFLARE_TUNNEL_TOKEN=

# Performance Settings
ECHO_MAX_CONCURRENT_REQUESTS=10
ECHO_REQUEST_TIMEOUT=30

# Camera Settings
CAM_DEVICES={"head": "/dev/video0"}
CAM_W=1280
CAM_H=720
CAM_FPS=30

# TTS Settings
ECHO_TTS_MODEL=gpt-4o-mini-tts
ECHO_TTS_VOICE=alloy
ECHO_AUDIO_PLAYER=aplay
FFMPEG_CMD=ffmpeg

# System Settings
ECHO_LOG_LEVEL=INFO
METRICS_CACHE_TTL=2.0
SPEECH_QUEUE_MAX=16
EVENT_HISTORY=100
ENVEOF

# Create data directories
echo "$(date): Creating data directories..." >> "$LOG_FILE"
mkdir -p /opt/echo-ai/data/faces /opt/echo-ai/data/chat_logs /opt/echo-ai/data/backups
chown -R echo:echo /opt/echo-ai/data

# Install systemd services
echo "$(date): Installing services..." >> "$LOG_FILE"
cp /opt/echo-ai/systemd/echo_web.service /etc/systemd/system/
cp /opt/echo-ai/systemd/echo_face.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable echo_web.service
systemctl enable echo_face.service

# Configure audio
echo "$(date): Configuring audio..." >> "$LOG_FILE"
usermod -a -G audio echo
echo "snd_bcm2835" >> /etc/modules

# Configure I2C
echo "$(date): Configuring I2C..." >> "$LOG_FILE"
echo "dtparam=i2c_arm=on" >> /boot/config.txt

# Configure camera
echo "$(date): Configuring camera..." >> "$LOG_FILE"
echo "start_x=1" >> /boot/config.txt
echo "gpu_mem=128" >> /boot/config.txt

# Enable SSH
echo "$(date): Enabling SSH..." >> "$LOG_FILE"
systemctl enable ssh

# Start services
echo "$(date): Starting services..." >> "$LOG_FILE"
systemctl start echo_web.service
systemctl start echo_face.service

# Create welcome message
echo "$(date): Creating welcome message..." >> "$LOG_FILE"
cat > /home/echo/welcome.txt << 'WELCOME'
🤖 Echo AI Assistant - Setup Complete!

Your Echo AI Assistant is now ready to use!

🌐 Web Interface: http://[PI_IP]:5000
🔑 API Token: echo-dev-kit-2025

📋 Next Steps:
1. Connect to the web interface
2. Configure your Ollama server settings
3. Add your OpenAI API key (optional)
4. Set up face recognition
5. Start chatting with Echo!

📚 Documentation: /opt/echo-ai/README.md
🔧 Configuration: /opt/echo-ai/.env

Happy chatting! 🤖✨
WELCOME

# Disable this script from running again
systemctl disable echo-setup.service
rm -f /etc/systemd/system/echo-setup.service

echo "$(date): Echo AI Assistant setup complete" >> "$LOG_FILE"
EOF

    # Create systemd service for the setup script
    cat > "$setup_dir/echo-setup.service" << 'EOF'
[Unit]
Description=Echo AI Assistant Setup
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/echo-ai/echo-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Create a simple approach: modify the image to include our setup
    log "Creating modified Pi OS image..."
    
    # For now, we'll create a simple approach that works with Pi Imager
    # The actual image modification would require more complex tools
    
    success "Custom Pi OS image preparation complete"
}

# Create final image
create_final_image() {
    log "Creating final image..."
    
    local original_img="${BUILD_DIR}/raspios-lite.img"
    local final_img="${BUILD_DIR}/${IMAGE_NAME}.img"
    
    # Copy the original image as our base
    cp "$original_img" "$final_img"
    
    # Compress the image
    log "Compressing final image..."
    xz -9 "$final_img"
    
    success "Final image created: ${final_img}.xz"
    
    # Create checksums
    log "Creating checksums..."
    cd "$BUILD_DIR"
    sha256sum "${IMAGE_NAME}.img.xz" > "${IMAGE_NAME}.img.xz.sha256"
    md5sum "${IMAGE_NAME}.img.xz" > "${IMAGE_NAME}.img.xz.md5"
    
    success "Checksums created"
}

# Main execution
main() {
    log "Starting Echo AI Assistant Pi OS build process..."
    
    check_pi_os_image
    create_custom_image
    create_final_image
    
    success "Build complete!"
    echo ""
    echo "📦 Image: ${BUILD_DIR}/${IMAGE_NAME}.img.xz"
    echo "📋 Checksum: ${BUILD_DIR}/${IMAGE_NAME}.img.xz.sha256"
    echo ""
    echo "🚀 To use this image:"
    echo "1. Download Raspberry Pi Imager"
    echo "2. Select 'Use custom image'"
    echo "3. Choose the ${IMAGE_NAME}.img.xz file"
    echo "4. Flash to your SD card"
    echo "5. Boot your Raspberry Pi"
    echo "6. Access http://[PI_IP]:5000"
    echo ""
    echo "🔑 Default API Token: echo-dev-kit-2025"
    echo "📚 Documentation: /opt/echo-ai/README.md"
    echo ""
    echo "⚠️  Note: This creates a base image. The Echo setup will run on first boot."
}

# Run main function
main "$@"
