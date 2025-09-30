#!/bin/bash

# Quick Fresh Install - One-liner version
# This is a minimal version that can be run with curl

echo "🚀 Echo AI Assistant - Quick Fresh Install"
echo "=========================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

echo "This will completely remove and reinstall Echo AI Assistant."
echo ""

# Confirm
# Support non-interactive mode via QUICK_INSTALL_YES=1
if [[ -z "$QUICK_INSTALL_YES" ]]; then
  read -p "Continue? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Installation cancelled."
      exit 0
  fi
else
  echo "Auto-approve enabled (QUICK_INSTALL_YES=1). Proceeding..."
fi

echo ""
echo "🔄 Starting fresh installation..."

# Stop services
sudo systemctl stop echo_web.service echo_face.service 2>/dev/null || true
sudo systemctl disable echo_web.service echo_face.service 2>/dev/null || true

# Clean up
sudo rm -rf /opt/echo-ai
sudo rm -f /etc/systemd/system/echo_*.service
sudo systemctl daemon-reload

# Kill processes
pkill -f "python.*run.py" 2>/dev/null || true

# Fresh install
sudo mkdir -p /opt/echo-ai
sudo chown $USER:$USER /opt/echo-ai
cd /opt/echo-ai

git clone https://github.com/DoubleDiamond3D/echo-ai-assistant.git .

python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

cp .env.example .env

sudo cp systemd/echo_web.service /etc/systemd/system/
sudo cp systemd/echo_face.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable echo_web.service echo_face.service

sudo chown -R $USER:$USER /opt/echo-ai
chmod +x scripts/*.sh

sudo systemctl start echo_web.service

sleep 3

if systemctl is-active --quiet echo_web.service; then
    echo ""
    echo "✅ Installation successful!"
    echo "🌐 Web interface: http://$(hostname -I | awk '{print $1}'):5000"
    echo "📝 Logs: sudo journalctl -u echo_web.service -f"
else
    echo "❌ Installation failed. Check logs: sudo journalctl -u echo_web.service -f"
    exit 1
fi

