#!/bin/bash
# Setup KMSDRM display for Echo Face Renderer

echo "🖥️  Setting up KMSDRM display..."

# Check if we're running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Add echo user to required groups for KMSDRM
echo "Adding echo user to required groups..."
usermod -a -G video,input,render,kvm echo

# Check if render group exists, if not create it
if ! getent group render > /dev/null 2>&1; then
    echo "Creating render group..."
    groupadd -r render
fi

# Set up permissions for DRM devices
echo "Setting up DRM device permissions..."
cat > /etc/udev/rules.d/99-drm.rules << 'EOF'
# DRM render nodes - allow video group
SUBSYSTEM=="drm", KERNEL=="card[0-9]*", GROUP="video", MODE="0666"
SUBSYSTEM=="drm", KERNEL=="renderD[0-9]*", GROUP="render", MODE="0666"

# Input devices for KMSDRM
SUBSYSTEM=="input", GROUP="input", MODE="0660"
EOF

# Set up permissions for /dev/dri
if [ -d /dev/dri ]; then
    chmod 755 /dev/dri
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/renderD* 2>/dev/null || true
    echo "DRM device permissions set"
fi

# Enable KMS in boot config
echo "Configuring boot settings for KMS..."
CONFIG_FILE=""
if [ -f /boot/config.txt ]; then
    CONFIG_FILE="/boot/config.txt"
elif [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
fi

if [ -n "$CONFIG_FILE" ]; then
    # Backup config
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Enable KMS driver
    if ! grep -q "^dtoverlay=vc4-kms-v3d" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "# Enable KMS driver for KMSDRM" >> "$CONFIG_FILE"
        echo "dtoverlay=vc4-kms-v3d" >> "$CONFIG_FILE"
        echo "max_framebuffers=2" >> "$CONFIG_FILE"
        echo "KMS driver enabled in $CONFIG_FILE"
    else
        echo "KMS driver already enabled"
    fi
    
    # Set display resolution (800x480)
    if ! grep -q "^hdmi_group=2" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "# Display settings for 800x480" >> "$CONFIG_FILE"
        echo "hdmi_group=2" >> "$CONFIG_FILE"
        echo "hdmi_mode=14" >> "$CONFIG_FILE"
        echo "hdmi_force_hotplug=1" >> "$CONFIG_FILE"
        echo "Display settings added to $CONFIG_FILE"
    fi
fi

# Install required packages for KMSDRM
echo "Installing required packages..."
apt-get update
apt-get install -y libdrm2 libgbm1 libgl1-mesa-dri libgles2-mesa libegl1-mesa

# Test KMSDRM availability
echo "Testing KMSDRM..."
if [ -e /dev/dri/card0 ]; then
    echo "✅ DRM device /dev/dri/card0 found"
    ls -la /dev/dri/
else
    echo "⚠️  No DRM devices found. May need to reboot or enable KMS driver."
fi

# Create a test script
cat > /opt/echo-ai/test_kmsdrm.py << 'EOF'
#!/usr/bin/env python3
import os
import sys

# Set KMSDRM driver
os.environ['SDL_VIDEODRIVER'] = 'kmsdrm'

try:
    import pygame
    print("Pygame imported successfully")
    
    pygame.init()
    print("Pygame initialized")
    
    info = pygame.display.Info()
    print(f"Display info: {info.current_w}x{info.current_h}")
    
    screen = pygame.display.set_mode((800, 480), pygame.FULLSCREEN | pygame.DOUBLEBUF)
    print("Display created successfully!")
    
    # Draw something
    screen.fill((0, 0, 255))  # Blue screen
    pygame.display.flip()
    
    import time
    time.sleep(3)
    
    pygame.quit()
    print("Test completed successfully!")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF

chmod +x /opt/echo-ai/test_kmsdrm.py
chown echo:echo /opt/echo-ai/test_kmsdrm.py

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

# Create XDG runtime directory for echo user
mkdir -p /run/user/1000
chown echo:echo /run/user/1000
chmod 700 /run/user/1000

echo ""
echo "✅ KMSDRM setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Update echo_face.py with the fixed version"
echo "  2. Copy the KMSDRM service file:"
echo "     sudo cp /opt/echo-ai/systemd/echo_face_kmsdrm.service /etc/systemd/system/echo_face.service"
echo "  3. Reload and restart the service:"
echo "     sudo systemctl daemon-reload"
echo "     sudo systemctl restart echo_face.service"
echo ""
echo "🧪 To test KMSDRM directly:"
echo "  sudo -u echo /opt/echo-ai/.venv/bin/python /opt/echo-ai/test_kmsdrm.py"
echo ""
echo "⚠️  If display doesn't work:"
echo "  1. Reboot: sudo reboot"
echo "  2. Check DRM devices: ls -la /dev/dri/"
echo "  3. Check groups: groups echo"
echo "  4. Check logs: sudo journalctl -u echo_face.service -f"
echo ""




