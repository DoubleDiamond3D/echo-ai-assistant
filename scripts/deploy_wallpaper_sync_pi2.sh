#!/bin/bash
# Deployment script for wallpaper sync on Pi #2 (Face Display)
# Run this script on Pi #2 after pulling from GitHub

set -e

echo "🚀 Deploying Wallpaper Sync on Pi #2 (Face Display)"
echo "=" * 50

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    echo "Usage: sudo ./scripts/deploy_wallpaper_sync_pi2.sh"
    exit 1
fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📁 Project root: $PROJECT_ROOT"
echo "📁 Script directory: $SCRIPT_DIR"

# 1. Install sync script
echo "📋 Installing sync script..."
cp "$SCRIPT_DIR/sync_wallpaper.sh" "/opt/echo-ai/sync_wallpaper.sh"
chmod +x "/opt/echo-ai/sync_wallpaper.sh"
echo "✅ Sync script installed"

# 2. Set up cron job
echo "⏰ Setting up cron job..."
cat > "/etc/cron.d/echo-wallpaper-sync" << 'EOF'
# Echo AI Wallpaper Sync - runs every 5 minutes
# Syncs wallpapers from Pi #1 (Brain) to Pi #2 (Face)
*/5 * * * * root /opt/echo-ai/sync_wallpaper.sh >/dev/null 2>&1

# Also run at startup (after 2 minutes delay)
@reboot root sleep 120 && /opt/echo-ai/sync_wallpaper.sh >/dev/null 2>&1
EOF

chmod 644 "/etc/cron.d/echo-wallpaper-sync"
echo "✅ Cron job configured"

# 3. Create wallpaper directory
echo "📁 Creating wallpaper directory..."
mkdir -p "/opt/echo-ai/wallpapers"
chmod 755 "/opt/echo-ai/wallpapers"
echo "✅ Wallpaper directory ready"

# 4. Create log file
echo "📝 Setting up logging..."
touch "/var/log/echo-wallpaper-sync.log"
chmod 644 "/var/log/echo-wallpaper-sync.log"
echo "✅ Log file created"

# 5. Update face service with wallpaper support
echo "🎭 Updating face service..."
if [ -f "$PROJECT_ROOT/pi2-face/echo_face_with_wallpaper.py" ]; then
    cp "$PROJECT_ROOT/pi2-face/echo_face_with_wallpaper.py" "/opt/echo-ai/echo_face_with_wallpaper.py"
    chmod +x "/opt/echo-ai/echo_face_with_wallpaper.py"
    echo "✅ Enhanced face service installed"
    
    # Optionally update the systemd service to use the new script
    echo "🔧 Would you like to update the face service to use wallpaper support? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Update systemd service file
        if [ -f "/etc/systemd/system/echo_face.service" ]; then
            sed -i 's|ExecStart=.*echo_face\.py|ExecStart=/usr/bin/python3 /opt/echo-ai/echo_face_with_wallpaper.py|' \
                "/etc/systemd/system/echo_face.service"
            systemctl daemon-reload
            echo "✅ Face service updated to use wallpaper support"
        fi
    fi
else
    echo "⚠️  Enhanced face service not found, skipping"
fi

# 6. Restart cron service
echo "🔄 Restarting cron service..."
systemctl restart cron
systemctl enable cron
echo "✅ Cron service restarted"

# 7. Test connectivity
echo "🔗 Testing connectivity to Brain Pi..."
BRAIN_PI_IP="${ECHO_BRAIN_PI_IP:-192.168.68.56}"
API_TOKEN="${ECHO_API_TOKEN:-echo-dev-kit-2025}"

if curl -s --connect-timeout 10 "http://${BRAIN_PI_IP}:5000/api/state" \
    -H "X-API-Key: $API_TOKEN" >/dev/null; then
    echo "✅ Brain Pi API is accessible"
else
    echo "⚠️  Brain Pi API not accessible - check network and configuration"
fi

# 8. Run initial sync
echo "🎯 Running initial wallpaper sync..."
if /opt/echo-ai/sync_wallpaper.sh; then
    echo "✅ Initial sync completed successfully"
else
    echo "⚠️  Initial sync failed - check logs: tail -f /var/log/echo-wallpaper-sync.log"
fi

# 9. Show status
echo ""
echo "📊 Deployment Complete!"
echo "=" * 30
echo "✅ Sync script: /opt/echo-ai/sync_wallpaper.sh"
echo "✅ Cron job: /etc/cron.d/echo-wallpaper-sync"
echo "✅ Log file: /var/log/echo-wallpaper-sync.log"
echo "✅ Wallpaper dir: /opt/echo-ai/wallpapers"
echo ""
echo "📋 Useful commands:"
echo "   Manual sync: sudo /opt/echo-ai/sync_wallpaper.sh"
echo "   View logs: tail -f /var/log/echo-wallpaper-sync.log"
echo "   Check cron: sudo crontab -l"
echo "   Troubleshoot: sudo ./scripts/troubleshoot_wallpaper_sync.sh"
echo ""
echo "🎭 Wallpaper sync is now active on Pi #2!"