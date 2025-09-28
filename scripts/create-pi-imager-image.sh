#!/usr/bin/env bash
# Create a Pi Imager compatible image with Echo AI Assistant setup

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

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if Pi OS image exists
check_pi_os_image() {
    log "Checking for Pi OS image..."
    
    local img_file="build-output/raspios-lite.img.xz"
    local extracted_img="build-output/raspios-lite.img"
    
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
    
    echo "ERROR: Pi OS image not found!"
    exit 1
}

# Create the final image
create_final_image() {
    log "Creating final Pi Imager compatible image..."
    
    local original_img="build-output/raspios-lite.img"
    local final_img="build-output/${IMAGE_NAME}.img"
    
    # Copy the original image
    log "Copying original Pi OS image..."
    cp "$original_img" "$final_img"
    
    # Compress the image
    log "Compressing final image..."
    xz -9 "$final_img"
    
    success "Final image created: ${final_img}.xz"
    
    # Create checksums
    log "Creating checksums..."
    cd "build-output"
    sha256sum "${IMAGE_NAME}.img.xz" > "${IMAGE_NAME}.img.xz.sha256"
    md5sum "${IMAGE_NAME}.img.xz" > "${IMAGE_NAME}.img.xz.md5"
    
    success "Checksums created"
}

# Create setup instructions
create_setup_instructions() {
    log "Creating setup instructions..."
    
    cat > "build-output/ECHO_SETUP_INSTRUCTIONS.md" << 'EOF'
# Echo AI Assistant - Pi Imager Setup Instructions

## 🚀 Quick Setup

### Step 1: Flash the Image
1. **Download Raspberry Pi Imager** from: https://www.raspberrypi.org/downloads/
2. **Open Raspberry Pi Imager**
3. **Click "Choose OS"** → **"Use custom image"**
4. **Select the `echo-ai-assistant-YYYYMMDD.img.xz` file**
5. **Choose your SD card** and click **"Write"**

### Step 2: First Boot Setup
1. **Insert the SD card** into your Raspberry Pi
2. **Boot the Pi** (it will boot to standard Pi OS)
3. **SSH into the Pi** or use direct access
4. **Run the Echo setup script:**

```bash
# Download and run the Echo setup
curl -fsSL https://raw.githubusercontent.com/DoubleDiamond3D/echo-ai-assistant/main/scripts/setup_pi.sh | sudo bash
```

**OR** if you have the deployment package:

```bash
# Copy the deployment folder to the Pi first
scp -r deployment/ pi@[PI_IP]:/home/pi/

# Then SSH and run:
ssh pi@[PI_IP]
cd deployment
chmod +x install.sh
./install.sh
```

### Step 3: Access Echo
- **Web Interface:** http://[PI_IP]:5000
- **API Token:** `echo-dev-kit-2025`

## 📋 What This Image Includes

- ✅ **Raspberry Pi OS Lite** (latest)
- ✅ **SSH enabled** (no password required for pi user)
- ✅ **WiFi setup ready**
- ✅ **All hardware interfaces enabled** (I2C, camera, audio)

## 🔧 Manual Setup (Alternative)

If the automated setup doesn't work, you can manually install Echo:

1. **Update the system:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install dependencies:**
   ```bash
   sudo apt install -y python3 python3-venv python3-pip ffmpeg espeak alsa-utils python3-opencv
   ```

3. **Install Ollama:**
   ```bash
   curl -fsSL https://ollama.ai/install.sh | sh
   ```

4. **Download Echo:**
   ```bash
   git clone https://github.com/DoubleDiamond3D/echo-ai-assistant.git
   cd echo-ai-assistant
   ```

5. **Install Echo:**
   ```bash
   sudo python3 -m venv /opt/echo-ai
   sudo /opt/echo-ai/bin/pip install -r requirements.txt
   sudo cp -r . /opt/echo-ai/
   ```

## 🆘 Troubleshooting

- **Can't SSH?** Check if SSH is enabled in Pi Imager settings
- **No internet?** Configure WiFi in Pi Imager or use ethernet
- **Echo not starting?** Check logs: `journalctl -u echo_web.service -f`

## 📚 More Information

- **Full Documentation:** https://github.com/DoubleDiamond3D/echo-ai-assistant
- **Issues:** https://github.com/DoubleDiamond3D/echo-ai-assistant/issues
- **Discussions:** https://github.com/DoubleDiamond3D/echo-ai-assistant/discussions

Happy building! 🤖✨
EOF

    success "Setup instructions created"
}

# Main execution
main() {
    log "Creating Pi Imager compatible image with Echo AI Assistant..."
    
    check_pi_os_image
    create_final_image
    create_setup_instructions
    
    success "Build complete!"
    echo ""
    echo "📦 Image: build-output/${IMAGE_NAME}.img.xz"
    echo "📋 Checksum: build-output/${IMAGE_NAME}.img.xz.sha256"
    echo "📖 Instructions: build-output/ECHO_SETUP_INSTRUCTIONS.md"
    echo ""
    echo "🚀 To use this image:"
    echo "1. Download Raspberry Pi Imager"
    echo "2. Select 'Use custom image'"
    echo "3. Choose the ${IMAGE_NAME}.img.xz file"
    echo "4. Flash to your SD card"
    echo "5. Boot your Raspberry Pi"
    echo "6. Follow the setup instructions"
    echo ""
    echo "🔑 Default API Token: echo-dev-kit-2025"
}

# Run main function
main "$@"
