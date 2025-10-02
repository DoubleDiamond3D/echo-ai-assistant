#!/bin/bash

echo "🔧 Fixing Echo Face Service Display Issues..."

# Fix runtime directory permissions
echo "📁 Setting up runtime directories..."
sudo mkdir -p /run/user/1001
sudo chown echo:echo /run/user/1001
sudo chmod 700 /run/user/1001

# Create pulse directory
sudo mkdir -p /run/user/1001/pulse
sudo chown echo:echo /run/user/1001/pulse
sudo chmod 700 /run/user/1001/pulse

# Fix X11 authorization
echo "🔐 Setting up X11 authorization..."
sudo -u echo2 xhost +local:echo
sudo cp /home/echo2/.Xauthority /home/echo/.Xauthority 2>/dev/null || true
sudo chown echo:echo /home/echo/.Xauthority 2>/dev/null || true

# Update the service file to include proper environment
echo "⚙️ Updating service configuration..."
sudo tee /etc/systemd/system/echo_face.service << 'EOF'
[Unit]
Description=Echo AI Face Display (Pi #2)
After=network.target graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
User=echo
Group=echo
WorkingDirectory=/opt/echo-ai
ExecStartPre=/bin/mkdir -p /run/user/1001
ExecStartPre=/bin/chown echo:echo /run/user/1001
ExecStartPre=/bin/chmod 700 /run/user/1001
ExecStartPre=/bin/mkdir -p /run/user/1001/pulse
ExecStartPre=/bin/chown echo:echo /run/user/1001/pulse
ExecStart=/opt/echo-ai/.venv/bin/python /opt/echo-ai/echo_face.py
Restart=always
RestartSec=10

# Environment variables for display and audio
Environment=XDG_RUNTIME_DIR=/run/user/1001
Environment=DISPLAY=:0
Environment=PULSE_RUNTIME_PATH=/run/user/1001/pulse
Environment=SDL_VIDEODRIVER=x11
Environment=SDL_AUDIODRIVER=pulse

# Additional permissions
SupplementaryGroups=audio video input render gpio

[Install]
WantedBy=multi-user.target
EOF

# Reload and restart the service
echo "🔄 Reloading service..."
sudo systemctl daemon-reload
sudo systemctl restart echo_face.service

echo "✅ Service configuration updated!"
echo "📊 Checking service status..."
sudo systemctl status echo_face.service --no-pager -l

echo ""
echo "📋 To monitor logs in real-time:"
echo "sudo journalctl -u echo_face.service -f"