#!/bin/bash
# Deploy Pi #2 (Face) Configuration

echo "🎭 Deploying Pi #2 (Face) Configuration"
echo "======================================="

# Backup current .env and deploy new configuration
sudo cp /opt/echo-ai/.env /opt/echo-ai/.env.backup
sudo cp pi2_env_config.txt /opt/echo-ai/.env
sudo chown echo2:echo2 /opt/echo-ai/.env
sudo chmod 644 /opt/echo-ai/.env

echo "✅ Configuration deployed"

# Restart face service to load new configuration
echo "🔄 Restarting face service..."
sudo systemctl restart echo_face.service

# Verify service started properly
echo "🔍 Checking service status..."
sudo systemctl status echo_face.service --no-pager -l

# Test the face display
echo "🧪 Testing face display..."
python3 /opt/echo-ai/echo_face.py --test 2>/dev/null &
sleep 3
pkill -f echo_face.py

echo ""
echo "✅ Pi #2 (Face) configuration deployment complete!"
echo "🎭 Face display should be active"
echo "🔗 Connected to Brain Pi: http://192.168.68.62:5000"
