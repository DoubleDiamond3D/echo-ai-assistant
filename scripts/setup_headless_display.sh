#!/bin/bash
# Setup display for headless Raspberry Pi (framebuffer mode)

echo "🖥️  Setting up headless display (framebuffer)..."

# Add echo user to necessary groups for framebuffer access
echo "Adding echo user to video and tty groups..."
usermod -a -G video,tty,input echo

# Enable framebuffer if disabled
echo "Enabling framebuffer..."
if [ -e /boot/config.txt ]; then
    # For Raspberry Pi OS
    if ! grep -q "^hdmi_force_hotplug=1" /boot/config.txt; then
        echo "hdmi_force_hotplug=1" >> /boot/config.txt
        echo "Added hdmi_force_hotplug=1 to /boot/config.txt"
    fi
    if ! grep -q "^hdmi_group=" /boot/config.txt; then
        echo "hdmi_group=2" >> /boot/config.txt
        echo "hdmi_mode=82" >> /boot/config.txt
        echo "Added HDMI settings for 1920x1080 to /boot/config.txt"
    fi
elif [ -e /boot/firmware/config.txt ]; then
    # For newer Raspberry Pi OS versions
    if ! grep -q "^hdmi_force_hotplug=1" /boot/firmware/config.txt; then
        echo "hdmi_force_hotplug=1" >> /boot/firmware/config.txt
        echo "Added hdmi_force_hotplug=1 to /boot/firmware/config.txt"
    fi
    if ! grep -q "^hdmi_group=" /boot/firmware/config.txt; then
        echo "hdmi_group=2" >> /boot/firmware/config.txt
        echo "hdmi_mode=82" >> /boot/firmware/config.txt
        echo "Added HDMI settings for 1920x1080 to /boot/firmware/config.txt"
    fi
fi

# Set permissions for framebuffer device
echo "Setting framebuffer permissions..."
if [ -e /dev/fb0 ]; then
    chmod 666 /dev/fb0
    echo "Framebuffer /dev/fb0 permissions set"
else
    echo "Warning: /dev/fb0 not found. It will be created on next boot."
fi

# Create udev rule for persistent framebuffer permissions
echo "Creating udev rule for framebuffer permissions..."
cat > /etc/udev/rules.d/99-framebuffer.rules << 'EOF'
# Allow echo user to access framebuffer
KERNEL=="fb[0-9]*", GROUP="video", MODE="0666"
EOF

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

# Test framebuffer access
echo "Testing framebuffer access..."
if [ -e /dev/fb0 ]; then
    if sudo -u echo dd if=/dev/fb0 of=/dev/null bs=1 count=1 2>/dev/null; then
        echo "✅ Echo user can access framebuffer"
    else
        echo "⚠️  Echo user cannot access framebuffer yet. May need reboot."
    fi
else
    echo "⚠️  Framebuffer not available. Reboot required."
fi

echo ""
echo "✅ Headless display setup complete!"
echo ""
echo "📝 Notes:"
echo "  - The display will use the framebuffer (/dev/fb0)"
echo "  - No X11 server is required"
echo "  - HDMI output will work without a desktop environment"
echo ""
echo "🔄 If the display doesn't work immediately:"
echo "  1. Reboot the Raspberry Pi: sudo reboot"
echo "  2. Check framebuffer: ls -la /dev/fb*"
echo "  3. Test display: sudo -u echo python3 -c 'import pygame; pygame.init(); print(\"OK\")'"
echo ""
