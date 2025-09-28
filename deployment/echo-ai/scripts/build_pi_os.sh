#!/usr/bin/env bash
set -euo pipefail

# Echo AI Assistant - Custom Raspberry Pi OS Builder
# This script creates a custom Pi OS image with Echo pre-installed

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR=${BUILD_DIR:-/tmp/echo-pi-os}
IMAGE_NAME="echo-ai-assistant-$(date +%Y%m%d)"
PI_OS_VERSION="2024-10-04"  # Latest Pi OS Lite version

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

# Check if running as root (allow in Docker)
if [[ $EUID -eq 0 ]] && [[ -z "${DOCKER_BUILD:-}" ]]; then
    error "This script should not be run as root"
    exit 1
fi

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    local commands=("wget" "unzip" "parted" "kpartx" "losetup" "mkfs.ext4" "mkfs.fat")
    local packages=("qemu-user-static")
    local missing=()
    
    # Check commands
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    # Check packages
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            missing+=("$pkg")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing[*]}"
        echo "Install them with:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y wget unzip qemu-user-static parted kpartx dosfstools e2fsprogs"
        exit 1
    fi
    
    success "All dependencies found"
}

# Download Raspberry Pi OS
download_pi_os() {
    log "Downloading Raspberry Pi OS Lite..."
    
    # Try multiple known working URLs
    local pi_os_urls=(
        "https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2024-10-04/2024-10-04-raspios-bookworm-armhf-lite.img.xz"
        "https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2024-09-26/2024-09-26-raspios-bookworm-armhf-lite.img.xz"
        "https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2024-08-22/2024-08-22-raspios-bookworm-armhf-lite.img.xz"
    )
    
    local img_file="${BUILD_DIR}/raspios-lite.img.xz"
    local extracted_img="${BUILD_DIR}/raspios-lite.img"
    
    mkdir -p "$BUILD_DIR"
    
    if [[ ! -f "$extracted_img" ]]; then
        if [[ ! -f "$img_file" ]]; then
            log "Trying to download Pi OS image..."
            local download_success=false
            
            for url in "${pi_os_urls[@]}"; do
                log "Trying URL: $url"
                if wget -O "$img_file" "$url"; then
                    download_success=true
                    break
                else
                    log "Failed to download from $url, trying next..."
                    rm -f "$img_file"
                fi
            done
            
            if [[ "$download_success" != "true" ]]; then
                error "Failed to download Pi OS image from any URL"
                error "Please check the Raspberry Pi OS downloads page for current URLs"
                error "https://www.raspberrypi.org/downloads/raspberry-pi-os/"
                exit 1
            fi
        fi
        
        log "Extracting Pi OS image..."
        xz -d "$img_file"
    else
        log "Pi OS image already exists"
    fi
    
    success "Pi OS image ready: $extracted_img"
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
        .venv/bin/pip install dlib face-recognition
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

# Install additional packages
install_packages() {
    log "Installing additional packages..."
    
    local root_mount=$(cat "${BUILD_DIR}/root_mount")
    
    # Create package installation script
    sudo tee "$root_mount/tmp/install_packages.sh" > /dev/null << 'EOF'
#!/bin/bash
set -e

# Update package lists
apt-get update

# Install system packages
apt-get install -y \
    python3 python3-venv python3-dev python3-pip \
    ffmpeg espeak alsa-utils \
    python3-opencv python3-numpy \
    libatlas-base-dev libhdf5-dev libhdf5-serial-dev \
    python3-pyqt5 \
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

# Enable audio
modprobe snd_bcm2835
echo "snd_bcm2835" >> /etc/modules

# Configure audio for USB microphones
usermod -a -G audio echo

# Enable I2C
echo "dtparam=i2c_arm=on" >> /boot/config.txt

# Enable camera
echo "start_x=1" >> /boot/config.txt
echo "gpu_mem=128" >> /boot/config.txt

# Enable SSH
systemctl enable ssh

# Clean up
apt-get autoremove -y
apt-get autoclean
EOF
    
    sudo chmod +x "$root_mount/tmp/install_packages.sh"
    
    # Run package installation
    log "Installing packages (this may take a while)..."
    sudo chroot "$root_mount" /tmp/install_packages.sh
    
    # Clean up
    sudo rm -f "$root_mount/tmp/install_packages.sh"
    
    success "Additional packages installed"
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

# Create first-boot script
create_first_boot_script() {
    log "Creating first-boot script..."
    
    local root_mount=$(cat "${BUILD_DIR}/root_mount")
    
    # Create first-boot script
    sudo tee "$root_mount/opt/echo-ai/first-boot.sh" > /dev/null << 'EOF'
#!/bin/bash
# Echo AI Assistant First Boot Script

set -e

LOG_FILE="/var/log/echo-first-boot.log"
echo "$(date): Starting Echo AI Assistant first boot setup" >> "$LOG_FILE"

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

# Install Ollama
echo "$(date): Installing Ollama..." >> "$LOG_FILE"
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
systemctl start ollama
systemctl enable ollama

# Pull Qwen2.5 model
echo "$(date): Downloading Qwen2.5 model..." >> "$LOG_FILE"
su - echo -c "ollama pull qwen2.5:latest" || echo "$(date): Failed to pull model" >> "$LOG_FILE"

# Start Echo services
echo "$(date): Starting Echo services..." >> "$LOG_FILE"
systemctl start echo_web.service
systemctl start echo_face.service

# Create welcome message
echo "$(date): Creating welcome message..." >> "$LOG_FILE"
cat > /home/echo/welcome.txt << 'WELCOME'
🤖 Echo AI Assistant - First Boot Complete!

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
systemctl disable echo-first-boot.service
rm -f /etc/systemd/system/echo-first-boot.service

echo "$(date): First boot setup complete" >> "$LOG_FILE"
EOF
    
    sudo chmod +x "$root_mount/opt/echo-ai/first-boot.sh"
    
    # Create systemd service for first boot
    sudo tee "$root_mount/etc/systemd/system/echo-first-boot.service" > /dev/null << 'EOF'
[Unit]
Description=Echo AI Assistant First Boot Setup
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/echo-ai/first-boot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable first boot service
    sudo chroot "$root_mount" systemctl enable echo-first-boot.service
    
    success "First-boot script created"
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
    
    check_dependencies
    download_pi_os
    mount_pi_os
    install_packages
    install_echo
    configure_boot
    create_first_boot_script
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
