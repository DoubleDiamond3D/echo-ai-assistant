#!/usr/bin/env bash
# Create a minimal Pi-compatible image for Echo AI Assistant

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR=${BUILD_DIR:-/tmp/echo-pi-minimal}
IMAGE_NAME="echo-ai-assistant-minimal-$(date +%Y%m%d)"

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

# Create minimal Pi image
create_minimal_pi() {
    log "Creating minimal Pi image..."
    
    local img_file="${BUILD_DIR}/${IMAGE_NAME}.img"
    local img_size="2G"  # 2GB image
    
    mkdir -p "$BUILD_DIR"
    
    # Create empty image file
    log "Creating ${img_size} image file..."
    dd if=/dev/zero of="$img_file" bs=1M count=2048 status=progress
    
    # Create partition table
    log "Creating partition table..."
    parted "$img_file" mklabel msdos
    
    # Create boot partition (FAT32, 256MB)
    log "Creating boot partition..."
    parted "$img_file" mkpart primary fat32 1MiB 257MiB
    parted "$img_file" set 1 boot on
    
    # Create root partition (ext4, rest of space)
    log "Creating root partition..."
    parted "$img_file" mkpart primary ext4 257MiB 100%
    
    # Map partitions
    log "Mapping partitions..."
    local loop_device=$(sudo losetup --find --show "$img_file")
    sudo kpartx -av "$loop_device"
    
    # Format partitions
    log "Formatting partitions..."
    local boot_partition="/dev/mapper/$(ls /dev/mapper/ | grep $(basename $loop_device) | grep p1)"
    local root_partition="/dev/mapper/$(ls /dev/mapper/ | grep $(basename $loop_device) | grep p2)"
    
    sudo mkfs.fat -F32 "$boot_partition"
    sudo mkfs.ext4 "$root_partition"
    
    # Mount partitions
    local boot_mount="${BUILD_DIR}/boot"
    local root_mount="${BUILD_DIR}/root"
    mkdir -p "$boot_mount" "$root_mount"
    
    sudo mount "$boot_partition" "$boot_mount"
    sudo mount "$root_partition" "$root_mount"
    
    # Store mount info
    echo "$loop_device" > "${BUILD_DIR}/loop_device"
    echo "$boot_mount" > "${BUILD_DIR}/boot_mount"
    echo "$root_mount" > "${BUILD_DIR}/root_mount"
    echo "$boot_partition" > "${BUILD_DIR}/boot_partition"
    echo "$root_partition" > "${BUILD_DIR}/root_partition"
    
    success "Minimal Pi image created and mounted"
}

# Install base system
install_base_system() {
    log "Installing base system..."
    
    local root_mount=$(cat "${BUILD_DIR}/root_mount")
    local boot_mount=$(cat "${BUILD_DIR}/boot_mount")
    
    # Create basic directory structure
    log "Creating directory structure..."
    sudo mkdir -p "$root_mount"/{bin,sbin,etc,var,usr,home,opt,proc,sys,dev,run,tmp}
    sudo mkdir -p "$root_mount"/usr/{bin,sbin,lib,share,include}
    sudo mkdir -p "$root_mount"/var/{log,lib,spool,cache}
    sudo mkdir -p "$boot_mount"
    
    # Create basic files
    log "Creating basic system files..."
    
    # /etc/passwd
    sudo tee "$root_mount/etc/passwd" > /dev/null << 'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
echo:x:1000:1000:echo:/opt/echo-ai:/bin/bash
EOF

    # /etc/group
    sudo tee "$root_mount/etc/group" > /dev/null << 'EOF'
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:
fax:x:21:
voice:x:22:
cdrom:x:24:
floppy:x:25:
tape:x:26:
sudo:x:27:
audio:x:29:
dip:x:30:
www-data:x:33:
backup:x:34:
operator:x:37:
list:x:38:
irc:x:39:
src:x:40:
gnats:x:41:
shadow:x:42:
utmp:x:43:
video:x:44:
sasl:x:45:
plugdev:x:46:
staff:x:50:
games:x:60:
users:x:100:
nogroup:x:65534:
echo:x:1000:
EOF

    # /etc/hostname
    echo "raspberrypi" | sudo tee "$root_mount/etc/hostname" > /dev/null
    
    # /etc/hosts
    sudo tee "$root_mount/etc/hosts" > /dev/null << 'EOF'
127.0.0.1	localhost
127.0.1.1	raspberrypi

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

    success "Base system installed"
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
    
    # Create echo user
    log "Creating echo user..."
    sudo chown -R echo:echo "$root_mount/opt/echo-ai"
    
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
    
    success "Echo AI Assistant installed"
}

# Configure boot settings
configure_boot() {
    log "Configuring boot settings..."
    
    local boot_mount=$(cat "${BUILD_DIR}/boot_mount")
    
    # Enable SSH
    sudo touch "$boot_mount/ssh"
    
    # Create basic config.txt
    sudo tee "$boot_mount/config.txt" > /dev/null << 'EOF'
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
    
    local original_img="${BUILD_DIR}/${IMAGE_NAME}.img"
    local final_img="${BUILD_DIR}/${IMAGE_NAME}-final.img"
    
    # Unmount first
    local boot_mount=$(cat "${BUILD_DIR}/boot_mount")
    local root_mount=$(cat "${BUILD_DIR}/root_mount")
    local loop_device=$(cat "${BUILD_DIR}/loop_device")
    
    sudo umount "$boot_mount" "$root_mount" || true
    sudo kpartx -d "$loop_device" || true
    sudo losetup -d "$loop_device" || true
    
    # Copy and rename
    cp "$original_img" "$final_img"
    
    # Compress the image
    log "Compressing final image..."
    xz -9 "$final_img"
    
    success "Final image created: ${final_img}.xz"
    
    # Create checksums
    log "Creating checksums..."
    cd "$BUILD_DIR"
    sha256sum "${IMAGE_NAME}-final.img.xz" > "${IMAGE_NAME}-final.img.xz.sha256"
    md5sum "${IMAGE_NAME}-final.img.xz" > "${IMAGE_NAME}-final.img.xz.md5"
    
    success "Checksums created"
}

# Main execution
main() {
    log "Starting minimal Echo AI Assistant Pi image build..."
    
    create_minimal_pi
    install_base_system
    install_echo
    configure_boot
    create_final_image
    
    success "Build complete!"
    echo ""
    echo "📦 Image: ${BUILD_DIR}/${IMAGE_NAME}-final.img.xz"
    echo "📋 Checksum: ${BUILD_DIR}/${IMAGE_NAME}-final.img.xz.sha256"
    echo ""
    echo "⚠️  Note: This is a minimal image. You'll need to:"
    echo "1. Flash it to an SD card"
    echo "2. Boot the Pi"
    echo "3. Install the full Pi OS: sudo apt update && sudo apt install -y raspberrypi-ui-mods"
    echo "4. Install Echo dependencies: cd /opt/echo-ai && pip install -r requirements.txt"
    echo "5. Start Echo: systemctl start echo_web.service"
}

# Run main function
main "$@"
