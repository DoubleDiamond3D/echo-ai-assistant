#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
INSTALL_DIR=${INSTALL_DIR:-/opt/echo-ai}
PY_VENV="$INSTALL_DIR/.venv"
ENV_FILE="$INSTALL_DIR/.env"
TARGET_USER=${ECHO_USER:-echo}
TARGET_GROUP=${ECHO_GROUP:-$TARGET_USER}

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo scripts/setup_pi.sh)" >&2
  exit 1
fi

echo "🤖 Echo AI Assistant - Raspberry Pi Setup"
echo "=========================================="

# Create user if it doesn't exist
if ! id "$TARGET_USER" &>/dev/null; then
  echo "Creating user: $TARGET_USER"
  useradd -r -s /bin/bash -d "$INSTALL_DIR" "$TARGET_USER"
fi

echo "📦 Installing system packages..."
apt-get update
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
  python3-gpiozero python3-rpi.gpio

echo "🔧 Setting up audio..."
# Enable audio
modprobe snd_bcm2835
echo "snd_bcm2835" >> /etc/modules

# Configure audio for USB microphones
usermod -a -G audio "$TARGET_USER"

echo "📁 Installing Echo AI Assistant..."
mkdir -p "$INSTALL_DIR"
rsync -a --delete "$REPO_DIR"/ "$INSTALL_DIR"/

# Create necessary directories
mkdir -p "$INSTALL_DIR/data/faces" "$INSTALL_DIR/data/chat_logs" "$INSTALL_DIR/data/backups"
chown -R "$TARGET_USER:$TARGET_GROUP" "$INSTALL_DIR"

cd "$INSTALL_DIR"

echo "🐍 Setting up Python environment..."
if [[ ! -d "$PY_VENV" ]]; then
  sudo -u "$TARGET_USER" python3 -m venv "$PY_VENV"
fi

sudo -u "$TARGET_USER" "$PY_VENV/bin/pip" install --upgrade pip setuptools wheel
sudo -u "$TARGET_USER" "$PY_VENV/bin/pip" install -r requirements.txt

# Install additional packages for face recognition
sudo -u "$TARGET_USER" "$PY_VENV/bin/pip" install dlib face-recognition

echo "⚙️  Configuring services..."
# Update service files with correct paths
sed -i "s|/opt/project-echo|$INSTALL_DIR|g" systemd/echo_web.service
sed -i "s|/opt/project-echo|$INSTALL_DIR|g" systemd/echo_face.service
sed -i "s|User=echo|User=$TARGET_USER|g" systemd/echo_web.service
sed -i "s|User=echo|User=$TARGET_USER|g" systemd/echo_face.service

install -m 0644 systemd/echo_web.service /etc/systemd/system/echo_web.service
install -m 0644 systemd/echo_face.service /etc/systemd/system/echo_face.service

echo "🌐 Setting up network configuration..."
# Enable WiFi setup mode
systemctl enable NetworkManager
systemctl start NetworkManager

# Create WiFi setup script
cat > /usr/local/bin/echo-wifi-setup << 'EOF'
#!/bin/bash
# Echo WiFi Setup Script
echo "Setting up WiFi for Echo AI Assistant..."
read -p "Enter WiFi SSID: " ssid
read -s -p "Enter WiFi Password: " password
echo

# Configure WiFi
nmcli dev wifi connect "$ssid" password "$password"
echo "WiFi configured successfully!"
EOF
chmod +x /usr/local/bin/echo-wifi-setup

echo "🔐 Setting up environment..."
if [[ ! -f "$ENV_FILE" ]]; then
  # Generate a secure API token
  API_TOKEN=$(openssl rand -hex 32)
  
  cat > "$ENV_FILE" << EOF
# Echo AI Assistant Configuration
ECHO_API_TOKEN=$API_TOKEN
ECHO_DATA_DIR=$INSTALL_DIR/data
ECHO_WEB_DIR=$INSTALL_DIR/web

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
  
  chown "$TARGET_USER:$TARGET_GROUP" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  
  echo "✅ Environment file created with secure API token"
  echo "🔑 Your API token is: $API_TOKEN"
  echo "   Save this token - you'll need it to access the web interface"
else
  echo "⚠️  Environment file already exists at $ENV_FILE"
fi

echo "🚀 Starting services..."
systemctl daemon-reload
systemctl enable echo_web.service
systemctl enable echo_face.service

# Start services
systemctl start echo_web.service
systemctl start echo_face.service

echo "📋 Setup Summary"
echo "================"
echo "✅ Echo AI Assistant installed to: $INSTALL_DIR"
echo "✅ Services enabled and started"
echo "✅ API Token: $API_TOKEN"
echo "✅ Web interface: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "🔧 Next Steps:"
echo "1. Configure your Ollama server URL in $ENV_FILE"
echo "2. Add your OpenAI API key (optional) in $ENV_FILE"
echo "3. Set up Cloudflare tunnel token for remote access (optional)"
echo "4. Access the web interface and configure your settings"
echo ""
echo "📚 Useful Commands:"
echo "  sudo systemctl status echo_web.service    # Check web service"
echo "  sudo systemctl status echo_face.service   # Check face service"
echo "  sudo systemctl restart echo_web.service   # Restart web service"
echo "  echo-wifi-setup                           # Configure WiFi"
echo "  journalctl -u echo_web.service -f         # View web service logs"
echo ""
echo "🎉 Setup complete! Echo AI Assistant is ready to use."
