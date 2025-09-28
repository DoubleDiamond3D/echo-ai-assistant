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
