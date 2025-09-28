#!/usr/bin/env bash
# Manual Pi OS image builder for Echo AI Assistant
# This script assumes you've manually downloaded the Pi OS image

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

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
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

# Mount the Pi OS image
mount_pi_os() {
    log "Mounting Pi OS image..."
    
    local img_file="${BUILD_DIR}/raspios-lite.img"
    local loop_device
    local boot_partition
    local root_partition
    
    # Create loop device
    loop_device=$(sudo losetup --find --show "$img_file")
    log "Loop device: $loop_device"
    
    # Map partitions
    sudo kpartx -av "$loop_device"
    
    # Find partition devices
    boot_partition="/dev/mapper/$(ls /dev/mapper/ | grep $(basename $loop_device) | grep p1)"
    root_partition="/dev/mapper/$(ls /dev/mapper/ | grep $(basename $loop_device) | grep p2)"
    
    # Create mount points
    local boot_mount="${BUILD_DIR}/boot"
    local root_mount="${BUILD_DIR}/root"
    
    mkdir -p "$boot_mount" "$root_mount"
    
    # Mount partitions
    sudo mount "$boot_partition" "$boot_mount"
    sudo mount "$root_partition" "$root_mount"
    
    # Store mount info for cleanup
    echo "$loop_device" > "${BUILD_DIR}/loop_device"
    echo "$boot_mount" > "${BUILD_DIR}/boot_mount"
    echo "$root_mount" > "${BUILD_DIR}/root_mount"
    echo "$boot_partition" > "${BUILD_DIR}/boot_partition"
    echo "$root_partition" > "${BUILD_DIR}/root_partition"
    
    success "Pi OS image mounted"
}

# Unmount the Pi OS image
unmount_pi_os() {
    log "Unmounting Pi OS image..."
    
    if [[ -f "${BUILD_DIR}/boot_mount" ]]; then
        local boot_mount=$(cat "${BUILD_DIR}/boot_mount")
        local root_mount=$(cat "${BUILD_DIR}/root_mount")
        local loop_device=$(cat "${BUILD_DIR}/loop_device")
        
        sudo umount "$boot_mount" "$root_mount" || true
        sudo kpartx -d "$loop_device" || true
        sudo losetup -d "$loop_device" || true
        
        rm -f "${BUILD_DIR}/loop_device" "${BUILD_DIR}/boot_mount" "${BUILD_DIR}/root_mount" "${BUILD_DIR}/boot_partition" "${BUILD_DIR}/root_partition"
    fi
    
    success "Pi OS image unmounted"
}

# Install Echo AI Assistant
install_echo() {
    log "Installing Echo AI Assistant..."
    
    local root_mount=$(cat "${BUILD_DIR}/root_mount")
    local boot_mount=$(cat "${BUILD_DIR}/boot_mount")
    
    # Copy Echo files
    log "Copying Echo files..."
    sudo cp -r "$REPO_DIR" "$root_mount/opt/echo-ai"
    sudo chown -R root:root "$root_mount/opt/echo-ai"
    
    # Create systemd services
    log "Installing systemd services..."
    sudo cp "$root_mount/opt/echo-ai/systemd/echo_web.service" "$root_mount/etc/systemd/system/"
    sudo cp "$root_mount/opt/echo-ai/systemd/echo_face.service" "$root_mount/etc/systemd/system/"
    
    # Create echo user
    log "Creating echo user..."
    sudo chroot "$root_mount" useradd -r -s /bin/bash -d /opt/echo-ai -m echo || true
    sudo chown -R echo:echo "$root_mount/opt/echo-ai"
    
    # Install Python dependencies
    log "Installing Python dependencies..."
    sudo chroot "$root_mount" /bin/bash -c "
        cd /opt/echo-ai
        python3 -m venv .venv
        .venv/bin/pip install --upgrade pip setuptools wheel
        .venv/bin/pip install -r requirements.txt
    "
    
    # Create environment file
    log "Creating environment configuration..."
    sudo tee "$root_mount/opt/echo-ai/.env" > /dev/null << 'EOF'
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
EOF
    
    sudo chown echo:echo "$root_mount/opt/echo-ai/.env"
    sudo chmod 600 "$root_mount/opt/echo-ai/.env"
    
    # Create data directories
    log "Creating data directories..."
    sudo mkdir -p "$root_mount/opt/echo-ai/data/faces" "$root_mount/opt/echo-ai/data/chat_logs" "$root_mount/opt/echo-ai/data/backups"
    sudo chown -R echo:echo "$root_mount/opt/echo-ai/data"
    
    # Enable services
    log "Enabling services..."
    sudo chroot "$root_mount" systemctl enable echo_web.service
    sudo chroot "$root_mount" systemctl enable echo_face.service
    
    success "Echo AI Assistant installed"
}

# Configure boot settings
configure_boot() {
    log "Configuring boot settings..."
    
    local boot_mount=$(cat "${BUILD_DIR}/boot_mount")
    
    # Enable SSH
    sudo touch "$boot_mount/ssh"
    
    # Configure WiFi (optional)
    log "Creating WiFi configuration template..."
    sudo tee "$boot_mount/wpa_supplicant.conf" > /dev/null << 'EOF'
# WiFi configuration for Echo AI Assistant
# Uncomment and configure your WiFi settings

#country=US
#ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
#update_config=1

#network={
#    ssid="YOUR_WIFI_SSID"
#    psk="YOUR_WIFI_PASSWORD"
#}
EOF
    
    # Add boot configuration
    log "Adding boot configuration..."
    sudo tee -a "$boot_mount/config.txt" > /dev/null << 'EOF'

# Echo AI Assistant Configuration
# Enable I2C
dtparam=i2c_arm=on

# Enable camera
start_x=1
gpu_mem=128

# Enable audio
dtparam=audio=on

# Enable UART
enable_uart=1

# Disable Bluetooth to free up UART
dtoverlay=disable-bt

# Performance settings
arm_freq=1800
gpu_freq=500
EOF
    
    success "Boot settings configured"
}

# Create final image
create_final_image() {
    log "Creating final image..."
    
    local original_img="${BUILD_DIR}/raspios-lite.img"
    local final_img="${BUILD_DIR}/${IMAGE_NAME}.img"
    
    # Unmount first
    unmount_pi_os
    
    # Copy and rename
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
    
    # Cleanup function
    trap 'unmount_pi_os; exit 1' INT TERM EXIT
    
    check_pi_os_image
    mount_pi_os
    install_echo
    configure_boot
    create_final_image
    
    # Remove trap
    trap - INT TERM EXIT
    
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
}

# Run main function
main "$@"
