#!/bin/bash
# Setup X11 display permissions for Echo AI Assistant

echo "🖥️  Setting up X11 display permissions..."

# Create autostart entry for X11 permissions
mkdir -p /home/pi/.config/autostart
cat > /home/pi/.config/autostart/echo-display-permission.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Echo Display Permission
Exec=xhost +SI:localuser:echo
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Set proper ownership
chown pi:pi /home/pi/.config/autostart/echo-display-permission.desktop

# Also create for echo user if it has a home directory
if [[ -d "/home/echo" ]]; then
  echo "Creating autostart entry for echo user..."
  mkdir -p /home/echo/.config/autostart
  cat > /home/echo/.config/autostart/echo-display-permission.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Echo Display Permission
Exec=xhost +SI:localuser:echo
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
  chown echo:echo /home/echo/.config/autostart/echo-display-permission.desktop
fi

# Set X11 permissions immediately
echo "Setting X11 permissions for echo user..."
xhost +SI:localuser:echo 2>/dev/null || echo "Warning: Could not set X11 permissions (X server may not be running)"

echo "✅ Display permissions setup complete!"
echo "The echo user should now be able to access the X11 display."
