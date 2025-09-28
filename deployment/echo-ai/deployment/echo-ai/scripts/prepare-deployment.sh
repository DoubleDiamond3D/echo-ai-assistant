#!/usr/bin/env bash
# Prepare Echo AI Assistant for deployment on existing Pi

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DEPLOY_DIR="$REPO_DIR/deployment"

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

# Create deployment package
create_deployment_package() {
    log "Creating deployment package..."
    
    mkdir -p "$DEPLOY_DIR"
    
    # Copy Echo files
    log "Copying Echo files..."
    cp -r "$REPO_DIR" "$DEPLOY_DIR/echo-ai"
    
    # Create installation script
    log "Creating installation script..."
    cat > "$DEPLOY_DIR/install.sh" << 'EOF'
#!/bin/bash
# Echo AI Assistant Installation Script

set -e

echo "🤖 Installing Echo AI Assistant..."

# Update system
echo "📦 Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install dependencies
echo "📦 Installing dependencies..."
sudo apt install -y \
    python3 python3-venv python3-dev python3-pip \
    ffmpeg espeak alsa-utils \
    python3-opencv python3-numpy \
    libatlas-base-dev libhdf5-dev libhdf5-serial-dev \
    python3-pyqt5 python3-pyqt5.qtwidgets \
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
echo "🤖 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Create echo user
echo "👤 Creating echo user..."
sudo useradd -r -s /bin/bash -d /opt/echo-ai -m echo || true

# Copy Echo files
echo "📁 Installing Echo files..."
sudo cp -r echo-ai /opt/
sudo chown -R echo:echo /opt/echo-ai

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
cd /opt/echo-ai
sudo -u echo python3 -m venv .venv
sudo -u echo .venv/bin/pip install --upgrade pip setuptools wheel
sudo -u echo .venv/bin/pip install -r requirements.txt

# Install systemd services
echo "⚙️ Installing services..."
sudo cp systemd/echo_web.service /etc/systemd/system/
sudo cp systemd/echo_face.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable echo_web.service
sudo systemctl enable echo_face.service

# Configure audio
echo "🔊 Configuring audio..."
sudo usermod -a -G audio echo
echo "snd_bcm2835" | sudo tee -a /etc/modules

# Configure I2C
echo "🔌 Configuring I2C..."
echo "dtparam=i2c_arm=on" | sudo tee -a /boot/config.txt

# Configure camera
echo "📷 Configuring camera..."
echo "start_x=1" | sudo tee -a /boot/config.txt
echo "gpu_mem=128" | sudo tee -a /boot/config.txt

# Enable SSH
echo "🌐 Enabling SSH..."
sudo systemctl enable ssh

# Start services
echo "🚀 Starting services..."
sudo systemctl start echo_web.service
sudo systemctl start echo_face.service

echo "✅ Installation complete!"
echo ""
echo "🌐 Web Interface: http://[PI_IP]:5000"
echo "🔑 API Token: echo-dev-kit-2025"
echo ""
echo "📚 Next steps:"
echo "1. Configure your Ollama server"
echo "2. Add your OpenAI API key (optional)"
echo "3. Set up face recognition"
echo "4. Start chatting with Echo!"
EOF

    chmod +x "$DEPLOY_DIR/install.sh"
    
    # Create README
    cat > "$DEPLOY_DIR/README.md" << 'EOF'
# Echo AI Assistant Deployment Package

This package contains everything needed to install Echo AI Assistant on a Raspberry Pi.

## Quick Start

1. **Copy this folder to your Raspberry Pi**
2. **Run the installation script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
3. **Access the web interface:** http://[PI_IP]:5000
4. **Use API token:** `echo-dev-kit-2025`

## What's Included

- ✅ Echo AI Assistant application
- ✅ Installation script with all dependencies
- ✅ Systemd services for auto-start
- ✅ Configuration files
- ✅ Documentation

## Requirements

- Raspberry Pi 4B (4GB+) or Pi 5 (8GB recommended)
- MicroSD card (32GB+ recommended)
- Internet connection
- USB microphone (optional)
- Camera (optional)

## Configuration

After installation, edit `/opt/echo-ai/.env` to configure:
- AI model settings
- Voice input options
- Face recognition settings
- Network configuration

## Support

- Documentation: `/opt/echo-ai/README.md`
- Logs: `journalctl -u echo_web.service -f`
- Configuration: `/opt/echo-ai/.env`

Happy chatting! 🤖✨
EOF

    success "Deployment package created in: $DEPLOY_DIR"
}

# Main execution
main() {
    log "Preparing Echo AI Assistant deployment package..."
    
    create_deployment_package
    
    success "Deployment package ready!"
    echo ""
    echo "📦 Package location: $DEPLOY_DIR"
    echo "📋 Contents:"
    echo "   - echo-ai/ (Echo application)"
    echo "   - install.sh (Installation script)"
    echo "   - README.md (Instructions)"
    echo ""
    echo "🚀 To deploy:"
    echo "1. Copy the deployment folder to your Pi"
    echo "2. Run: chmod +x install.sh && ./install.sh"
    echo "3. Access: http://[PI_IP]:5000"
    echo ""
    echo "🔑 Default API Token: echo-dev-kit-2025"
}

# Run main function
main "$@"
