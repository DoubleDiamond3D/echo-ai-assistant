#!/bin/bash
# Deploy Pi #1 (Brain) Configuration

echo "🧠 Deploying Pi #1 (Brain) Configuration"
echo "========================================"

# Backup current .env and deploy new configuration
sudo cp /opt/echo-ai/.env /opt/echo-ai/.env.backup
sudo cp pi1_env_config.txt /opt/echo-ai/.env
sudo chown echo:echo /opt/echo-ai/.env
sudo chmod 644 /opt/echo-ai/.env

echo "✅ Configuration deployed"

# Restart web service to load new configuration
echo "🔄 Restarting web service..."
sudo systemctl restart echo_web.service

# Verify service started properly
echo "🔍 Checking service status..."
sudo systemctl status echo_web.service --no-pager -l

# Test the web interface
echo "🧪 Testing web interface..."
curl -H "X-API-Key: Lolo6750" http://localhost:5000/api/state

echo ""
echo "✅ Pi #1 (Brain) configuration deployment complete!"
echo "🌐 Web interface: http://$(hostname -I | awk '{print $1}'):5000"
echo "🔑 API Key: Lolo6750"
