#!/bin/bash
# Troubleshooting script for wallpaper sync issues
# Run this on Pi #2 (Face Display) to diagnose sync problems

set -e

# Configuration
BRAIN_PI_IP="${ECHO_BRAIN_PI_IP:-192.168.68.56}"
BRAIN_PI_URL="http://${BRAIN_PI_IP}:5000"
API_TOKEN="${ECHO_API_TOKEN:-echo-dev-kit-2025}"
WALLPAPER_DIR="/opt/echo-ai/wallpapers"
SYNC_SCRIPT="/opt/echo-ai/sync_wallpaper.sh"
LOG_FILE="/var/log/echo-wallpaper-sync.log"

echo "🔍 Echo AI Wallpaper Sync Troubleshooter"
echo "=" * 50

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "✅ Running as root"
else
    echo "⚠️  Running as user $(whoami) - some checks may fail"
fi

echo ""
echo "📋 System Information:"
echo "   Pi #2 (Face): $(hostname -I | awk '{print $1}')"
echo "   Pi #1 (Brain): $BRAIN_PI_IP"
echo "   API Token: ${API_TOKEN:0:10}..."
echo ""

# 1. Check network connectivity
echo "🌐 Testing network connectivity..."
if ping -c 3 "$BRAIN_PI_IP" >/dev/null 2>&1; then
    echo "✅ Brain Pi is reachable via ping"
else
    echo "❌ Brain Pi is NOT reachable via ping"
    echo "   Check network configuration and IP address"
fi

# 2. Check HTTP API connectivity
echo "🔗 Testing HTTP API connectivity..."
if curl -s --connect-timeout 10 "$BRAIN_PI_URL/api/state" -H "X-API-Key: $API_TOKEN" >/dev/null; then
    echo "✅ Brain Pi API is accessible"
else
    echo "❌ Brain Pi API is NOT accessible"
    echo "   Check if Echo web service is running on Brain Pi"
    echo "   Command: ssh pi@$BRAIN_PI_IP 'sudo systemctl status echo_web.service'"
fi

# 3. Check SSH connectivity
echo "🔐 Testing SSH connectivity..."
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes \
    "pi@${BRAIN_PI_IP}" "echo 'SSH OK'" 2>/dev/null; then
    echo "✅ SSH connection to Brain Pi working"
else
    echo "❌ SSH connection to Brain Pi failed"
    echo "   Set up SSH key authentication:"
    echo "   1. ssh-keygen -t rsa -b 2048 (if no key exists)"
    echo "   2. ssh-copy-id pi@$BRAIN_PI_IP"
    echo "   3. Test: ssh pi@$BRAIN_PI_IP"
fi

# 4. Check wallpaper directory
echo "📁 Checking wallpaper directories..."
if [ -d "$WALLPAPER_DIR" ]; then
    echo "✅ Local wallpaper directory exists: $WALLPAPER_DIR"
    ls -la "$WALLPAPER_DIR" 2>/dev/null || echo "   (empty)"
else
    echo "❌ Local wallpaper directory missing: $WALLPAPER_DIR"
    echo "   Creating directory..."
    mkdir -p "$WALLPAPER_DIR"
    echo "✅ Directory created"
fi

# Check remote wallpaper directory via SSH
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
    "pi@${BRAIN_PI_IP}" "ls -la /opt/echo-ai/wallpapers/" 2>/dev/null; then
    echo "✅ Remote wallpaper directory accessible"
else
    echo "❌ Cannot access remote wallpaper directory"
fi

# 5. Check sync script
echo "🔧 Checking sync script..."
if [ -f "$SYNC_SCRIPT" ]; then
    echo "✅ Sync script exists: $SYNC_SCRIPT"
    if [ -x "$SYNC_SCRIPT" ]; then
        echo "✅ Sync script is executable"
    else
        echo "⚠️  Sync script is not executable"
        echo "   Fix: chmod +x $SYNC_SCRIPT"
    fi
else
    echo "❌ Sync script missing: $SYNC_SCRIPT"
    echo "   Run setup script to install it"
fi

# 6. Check cron job
echo "⏰ Checking cron job..."
if [ -f "/etc/cron.d/echo-wallpaper-sync" ]; then
    echo "✅ Cron job file exists"
    echo "   Content:"
    cat /etc/cron.d/echo-wallpaper-sync | sed 's/^/   /'
else
    echo "❌ Cron job file missing"
    echo "   Run setup script to install it"
fi

# Check if cron service is running
if systemctl is-active --quiet cron; then
    echo "✅ Cron service is running"
else
    echo "❌ Cron service is not running"
    echo "   Fix: sudo systemctl start cron && sudo systemctl enable cron"
fi

# 7. Check logs
echo "📝 Checking sync logs..."
if [ -f "$LOG_FILE" ]; then
    echo "✅ Log file exists: $LOG_FILE"
    echo "   Recent entries:"
    tail -n 10 "$LOG_FILE" 2>/dev/null | sed 's/^/   /' || echo "   (no entries)"
else
    echo "⚠️  Log file missing: $LOG_FILE"
    echo "   Will be created on first sync run"
fi

# 8. Test wallpaper API
echo "🖼️  Testing wallpaper API..."
wallpaper_info=$(curl -s "$BRAIN_PI_URL/api/pi/wallpaper/current" \
    -H "X-API-Key: $API_TOKEN" 2>/dev/null || echo '{"error": "API call failed"}')

if echo "$wallpaper_info" | grep -q '"has_wallpaper"'; then
    echo "✅ Wallpaper API responding"
    echo "   Response: $wallpaper_info"
else
    echo "❌ Wallpaper API not responding properly"
    echo "   Response: $wallpaper_info"
fi

# 9. Check face service
echo "👁️  Checking face service..."
if systemctl is-active --quiet echo_face.service; then
    echo "✅ Face service is running"
    echo "   Status: $(systemctl is-active echo_face.service)"
else
    echo "⚠️  Face service is not running"
    echo "   Status: $(systemctl is-active echo_face.service 2>/dev/null || echo 'not found')"
    echo "   Start: sudo systemctl start echo_face.service"
fi

# 10. Manual sync test
echo ""
echo "🧪 Manual Sync Test"
echo "=" * 20
if [ -f "$SYNC_SCRIPT" ] && [ -x "$SYNC_SCRIPT" ]; then
    echo "Running manual sync test..."
    if "$SYNC_SCRIPT"; then
        echo "✅ Manual sync completed successfully"
    else
        echo "❌ Manual sync failed"
        echo "   Check the log file for details: tail -f $LOG_FILE"
    fi
else
    echo "❌ Cannot run manual sync - script missing or not executable"
fi

echo ""
echo "📊 Troubleshooting Summary"
echo "=" * 30

# Summary of issues
issues=0

if ! ping -c 1 "$BRAIN_PI_IP" >/dev/null 2>&1; then
    echo "❌ Network connectivity issue"
    ((issues++))
fi

if ! curl -s --connect-timeout 5 "$BRAIN_PI_URL/api/state" -H "X-API-Key: $API_TOKEN" >/dev/null; then
    echo "❌ API connectivity issue"
    ((issues++))
fi

if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes \
    "pi@${BRAIN_PI_IP}" "echo test" >/dev/null 2>&1; then
    echo "❌ SSH connectivity issue"
    ((issues++))
fi

if [ ! -f "$SYNC_SCRIPT" ] || [ ! -x "$SYNC_SCRIPT" ]; then
    echo "❌ Sync script issue"
    ((issues++))
fi

if [ ! -f "/etc/cron.d/echo-wallpaper-sync" ]; then
    echo "❌ Cron job missing"
    ((issues++))
fi

if [ $issues -eq 0 ]; then
    echo "✅ No major issues detected!"
    echo "   If sync is still not working, check the log file:"
    echo "   tail -f $LOG_FILE"
else
    echo "⚠️  Found $issues issue(s) that need attention"
    echo ""
    echo "🔧 Quick fixes:"
    echo "   1. Set up SSH keys: ssh-copy-id pi@$BRAIN_PI_IP"
    echo "   2. Install sync script: sudo ./scripts/setup_wallpaper_sync.sh"
    echo "   3. Test manual sync: sudo $SYNC_SCRIPT"
fi

echo ""
echo "🎯 Troubleshooting complete!"