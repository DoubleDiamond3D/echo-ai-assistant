#!/bin/bash
# Test script for the complete wallpaper system
# Can be run on either Pi to test different aspects

set -e

# Configuration
BRAIN_PI_IP="${ECHO_BRAIN_PI_IP:-192.168.68.56}"
BRAIN_PI_URL="http://${BRAIN_PI_IP}:5000"
API_TOKEN="${ECHO_API_TOKEN:-echo-dev-kit-2025}"

# Detect which Pi we're on
CURRENT_IP=$(hostname -I | awk '{print $1}')
if [ "$CURRENT_IP" = "$BRAIN_PI_IP" ]; then
    PI_ROLE="BRAIN"
    echo "🧠 Running on Pi #1 (Brain) - $CURRENT_IP"
else
    PI_ROLE="FACE"
    echo "🎭 Running on Pi #2 (Face) - $CURRENT_IP"
fi

echo "🧪 Testing Echo AI Wallpaper System"
echo "=" * 40

# Test 1: API Connectivity
echo "1️⃣  Testing API connectivity..."
if curl -s --connect-timeout 10 "$BRAIN_PI_URL/api/state" \
    -H "X-API-Key: $API_TOKEN" >/dev/null; then
    echo "✅ Brain Pi API is accessible"
else
    echo "❌ Brain Pi API not accessible"
    exit 1
fi

# Test 2: Wallpaper API
echo "2️⃣  Testing wallpaper API..."
wallpaper_info=$(curl -s "$BRAIN_PI_URL/api/pi/wallpaper/current" \
    -H "X-API-Key: $API_TOKEN")

if echo "$wallpaper_info" | grep -q '"has_wallpaper"'; then
    echo "✅ Wallpaper API responding"
    echo "   Info: $wallpaper_info"
    
    has_wallpaper=$(echo "$wallpaper_info" | grep -o '"has_wallpaper":[^,]*' | cut -d':' -f2 | tr -d ' "')
    if [ "$has_wallpaper" = "true" ]; then
        wallpaper_type=$(echo "$wallpaper_info" | grep -o '"type":[^,}]*' | cut -d':' -f2 | tr -d ' "')
        echo "   📸 Wallpaper available: $wallpaper_type"
    else
        echo "   📭 No wallpaper currently set"
    fi
else
    echo "❌ Wallpaper API not responding properly"
fi

if [ "$PI_ROLE" = "BRAIN" ]; then
    # Tests specific to Pi #1 (Brain)
    echo ""
    echo "🧠 Pi #1 (Brain) Specific Tests"
    echo "=" * 30
    
    # Test 3: Wallpaper directory
    echo "3️⃣  Checking wallpaper directory..."
    if [ -d "/opt/echo-ai/wallpapers" ]; then
        echo "✅ Wallpaper directory exists"
        ls -la /opt/echo-ai/wallpapers/ || echo "   (empty)"
    else
        echo "❌ Wallpaper directory missing"
        echo "   Creating: mkdir -p /opt/echo-ai/wallpapers"
        mkdir -p /opt/echo-ai/wallpapers
    fi
    
    # Test 4: Download API endpoint
    echo "4️⃣  Testing download API endpoint..."
    if [ -f "/opt/echo-ai/wallpapers/wallpaper.jpg" ]; then
        if curl -s -f "$BRAIN_PI_URL/api/pi/wallpaper/download/wallpaper.jpg" \
            -H "X-API-Key: $API_TOKEN" -o /tmp/test_download.jpg; then
            echo "✅ Download API working"
            rm -f /tmp/test_download.jpg
        else
            echo "❌ Download API not working"
        fi
    else
        echo "⚠️  No wallpaper file to test download"
    fi
    
    # Test 5: Web interface upload
    echo "5️⃣  Testing web interface..."
    if curl -s "$BRAIN_PI_URL/" >/dev/null; then
        echo "✅ Web interface accessible"
        echo "   You can upload wallpapers at: $BRAIN_PI_URL"
    else
        echo "❌ Web interface not accessible"
    fi

elif [ "$PI_ROLE" = "FACE" ]; then
    # Tests specific to Pi #2 (Face)
    echo ""
    echo "🎭 Pi #2 (Face) Specific Tests"
    echo "=" * 30
    
    # Test 3: Sync script
    echo "3️⃣  Checking sync script..."
    if [ -f "/opt/echo-ai/sync_wallpaper.sh" ]; then
        echo "✅ Sync script exists"
        if [ -x "/opt/echo-ai/sync_wallpaper.sh" ]; then
            echo "✅ Sync script is executable"
        else
            echo "⚠️  Sync script not executable"
        fi
    else
        echo "❌ Sync script missing"
    fi
    
    # Test 4: Cron job
    echo "4️⃣  Checking cron job..."
    if [ -f "/etc/cron.d/echo-wallpaper-sync" ]; then
        echo "✅ Cron job exists"
        echo "   Content:"
        cat /etc/cron.d/echo-wallpaper-sync | sed 's/^/   /'
    else
        echo "❌ Cron job missing"
    fi
    
    # Test 5: Local wallpaper directory
    echo "5️⃣  Checking local wallpaper directory..."
    if [ -d "/opt/echo-ai/wallpapers" ]; then
        echo "✅ Local wallpaper directory exists"
        ls -la /opt/echo-ai/wallpapers/ || echo "   (empty)"
    else
        echo "❌ Local wallpaper directory missing"
    fi
    
    # Test 6: Face service
    echo "6️⃣  Checking face service..."
    if systemctl is-active --quiet echo_face.service; then
        echo "✅ Face service is running"
    else
        echo "⚠️  Face service not running"
        echo "   Status: $(systemctl is-active echo_face.service 2>/dev/null || echo 'not found')"
    fi
    
    # Test 7: Manual sync test
    echo "7️⃣  Testing manual sync..."
    if [ -f "/opt/echo-ai/sync_wallpaper.sh" ] && [ -x "/opt/echo-ai/sync_wallpaper.sh" ]; then
        echo "   Running sync test..."
        if /opt/echo-ai/sync_wallpaper.sh; then
            echo "✅ Manual sync successful"
        else
            echo "❌ Manual sync failed"
        fi
    else
        echo "❌ Cannot test sync - script missing"
    fi
    
    # Test 8: Enhanced face service
    echo "8️⃣  Checking enhanced face service..."
    if [ -f "/opt/echo-ai/echo_face_with_wallpaper.py" ]; then
        echo "✅ Enhanced face service available"
    else
        echo "⚠️  Enhanced face service not installed"
    fi
fi

# Common tests
echo ""
echo "🔧 Common System Tests"
echo "=" * 20

# Test: Log file
echo "📝 Checking log file..."
if [ -f "/var/log/echo-wallpaper-sync.log" ]; then
    echo "✅ Log file exists"
    echo "   Recent entries:"
    tail -n 5 /var/log/echo-wallpaper-sync.log 2>/dev/null | sed 's/^/   /' || echo "   (no entries)"
else
    echo "⚠️  Log file missing (will be created on first sync)"
fi

# Test: Network connectivity
echo "🌐 Testing network connectivity..."
if ping -c 3 "$BRAIN_PI_IP" >/dev/null 2>&1; then
    echo "✅ Network connectivity to Brain Pi working"
else
    echo "❌ Network connectivity to Brain Pi failed"
fi

echo ""
echo "📊 Test Summary"
echo "=" * 15
echo "🎯 Role: Pi #$([[ $PI_ROLE == "BRAIN" ]] && echo "1 (Brain)" || echo "2 (Face)")"
echo "🌐 Brain Pi: $BRAIN_PI_IP"
echo "🔗 API: $([[ $(curl -s --connect-timeout 5 "$BRAIN_PI_URL/api/state" -H "X-API-Key: $API_TOKEN" >/dev/null 2>&1) ]] && echo "✅ Working" || echo "❌ Failed")"

if [ "$PI_ROLE" = "FACE" ]; then
    sync_status="❌ Not configured"
    if [ -f "/opt/echo-ai/sync_wallpaper.sh" ] && [ -f "/etc/cron.d/echo-wallpaper-sync" ]; then
        sync_status="✅ Configured"
    fi
    echo "🔄 Sync: $sync_status"
fi

echo ""
echo "🎉 Testing complete!"