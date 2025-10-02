#!/bin/bash
# Setup script for wallpaper sync on Pi #2 (Face Display)
# This script sets up automatic wallpaper synchronization from Pi #1 to Pi #2

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="/opt/echo-ai/sync_wallpaper.sh"
CRON_FILE="/etc/cron.d/echo-wallpaper-sync"
LOG_FILE="/var/log/echo-wallpaper-sync.log"

echo "🖼️  Setting up wallpaper sync for Pi #2..."
echo "=" * 50

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Copy sync script to system location
echo "📋 Installing sync script..."
cp "$SCRIPT_DIR/sync_wallpaper.sh" "$SYNC_SCRIPT"
chmod +x "$SYNC_SCRIPT"
echo "✅ Sync script installed at $SYNC_SCRIPT"

# Create log file with proper permissions
echo "📝 Setting up logging..."
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"
chown root:root "$LOG_FILE"
echo "✅ Log file created at $LOG_FILE"

# Set up cron job for automatic sync
echo "⏰ Setting up cron job..."
cat > "$CRON_FILE" << 'EOF'
# Echo AI Wallpaper Sync - runs every 5 minutes
# Syncs wallpapers from Pi #1 (Brain) to Pi #2 (Face)
*/5 * * * * root /opt/echo-ai/sync_wallpaper.sh >/dev/null 2>&1

# Also run at startup (after 2 minutes delay)
@reboot root sleep 120 && /opt/echo-ai/sync_wallpaper.sh >/dev/null 2>&1
EOF

chmod 644 "$CRON_FILE"
echo "✅ Cron job installed at $CRON_FILE"

# Restart cron service
echo "🔄 Restarting cron service..."
systemctl restart cron
systemctl enable cron
echo "✅ Cron service restarted"

# Test SSH connectivity to Brain Pi
echo "🔗 Testing SSH connectivity to Brain Pi..."
BRAIN_PI_IP="${ECHO_BRAIN_PI_IP:-192.168.68.56}"

if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes \
    "pi@${BRAIN_PI_IP}" "echo 'SSH connection successful'" 2>/dev/null; then
    echo "✅ SSH connection to Brain Pi working"
else
    echo "⚠️  SSH connection to Brain Pi failed"
    echo "   You may need to set up SSH key authentication:"
    echo "   1. Generate SSH key: ssh-keygen -t rsa -b 2048"
    echo "   2. Copy to Brain Pi: ssh-copy-id pi@${BRAIN_PI_IP}"
    echo "   3. Test connection: ssh pi@${BRAIN_PI_IP}"
fi

# Run initial sync
echo "🚀 Running initial wallpaper sync..."
if "$SYNC_SCRIPT"; then
    echo "✅ Initial sync completed successfully"
else
    echo "⚠️  Initial sync failed - check logs: tail -f $LOG_FILE"
fi

# Show status
echo ""
echo "📊 Wallpaper Sync Setup Complete!"
echo "=" * 50
echo "📁 Sync script: $SYNC_SCRIPT"
echo "📝 Log file: $LOG_FILE"
echo "⏰ Cron job: $CRON_FILE"
echo "🔄 Sync frequency: Every 5 minutes"
echo ""
echo "📋 Useful commands:"
echo "   Manual sync: sudo $SYNC_SCRIPT"
echo "   View logs: tail -f $LOG_FILE"
echo "   Check cron: sudo crontab -l"
echo "   Test SSH: ssh pi@${BRAIN_PI_IP}"
echo ""
echo "🎯 The wallpaper sync is now active!"