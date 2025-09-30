#!/bin/bash

# Echo AI Assistant - Diagnostic Script
# This script helps diagnose common issues

echo "🔍 Echo AI Assistant - Diagnostic Script"
echo "========================================"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "⚠️  Warning: Running as root. Some checks may not work properly."
   echo ""
fi

# Check if Echo directory exists
echo "📁 Checking Echo AI directory..."
if [ -d "/opt/echo-ai" ]; then
    echo "✅ /opt/echo-ai directory exists"
    echo "   Contents: $(ls -la /opt/echo-ai | wc -l) items"
else
    echo "❌ /opt/echo-ai directory does not exist"
    echo "   Run the setup script first: curl -fsSL https://raw.githubusercontent.com/DoubleDiamond3D/echo-ai-assistant/main/scripts/setup_pi.sh | sudo bash"
    exit 1
fi

# Check if virtual environment exists
echo ""
echo "🐍 Checking Python virtual environment..."
if [ -d "/opt/echo-ai/.venv" ]; then
    echo "✅ Virtual environment exists"
    if [ -f "/opt/echo-ai/.venv/bin/python" ]; then
        echo "✅ Python executable found"
        echo "   Python version: $(/opt/echo-ai/.venv/bin/python --version)"
    else
        echo "❌ Python executable not found in virtual environment"
    fi
else
    echo "❌ Virtual environment does not exist"
    echo "   Run: cd /opt/echo-ai && python3 -m venv .venv"
fi

# Check if .env file exists
echo ""
echo "⚙️  Checking configuration..."
if [ -f "/opt/echo-ai/.env" ]; then
    echo "✅ .env file exists"
    echo "   File size: $(stat -c%s /opt/echo-ai/.env) bytes"
else
    echo "❌ .env file does not exist"
    echo "   Run: cp /opt/echo-ai/.env.example /opt/echo-ai/.env"
fi

# Check if systemd services exist
echo ""
echo "🔧 Checking systemd services..."
if [ -f "/etc/systemd/system/echo_web.service" ]; then
    echo "✅ echo_web.service exists"
else
    echo "❌ echo_web.service does not exist"
    echo "   Run: sudo cp /opt/echo-ai/systemd/echo_web.service /etc/systemd/system/"
fi

if [ -f "/etc/systemd/system/echo_face.service" ]; then
    echo "✅ echo_face.service exists"
else
    echo "❌ echo_face.service does not exist"
    echo "   Run: sudo cp /opt/echo-ai/systemd/echo_face.service /etc/systemd/system/"
fi

# Check if services are running
echo ""
echo "🚀 Checking running services..."
if pgrep -f "python.*run.py" > /dev/null; then
    echo "✅ Echo AI Assistant is running"
    echo "   Process ID: $(pgrep -f 'python.*run.py')"
    echo "   Memory usage: $(ps -o pid,vsz,rss,comm -p $(pgrep -f 'python.*run.py') | tail -1)"
else
    echo "❌ Echo AI Assistant is not running"
    echo "   Try: sudo systemctl start echo_web.service"
fi

# Check if port 5000 is listening
echo ""
echo "🌐 Checking network connectivity..."
if netstat -tlnp 2>/dev/null | grep -q ":5000 "; then
    echo "✅ Port 5000 is listening"
    echo "   Process: $(netstat -tlnp 2>/dev/null | grep ':5000 ' | awk '{print $7}')"
else
    echo "❌ Port 5000 is not listening"
    echo "   Echo AI may not be running or not bound to port 5000"
fi

# Check if web interface is accessible
echo ""
echo "🌍 Testing web interface..."
if command -v curl >/dev/null 2>&1; then
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null | grep -q "200"; then
        echo "✅ Web interface is accessible"
        echo "   Health check: $(curl -s http://localhost:5000/health 2>/dev/null | head -c 100)..."
    else
        echo "❌ Web interface is not accessible"
        echo "   HTTP status: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null)"
    fi
else
    echo "⚠️  curl not available, cannot test web interface"
fi

# Check system resources
echo ""
echo "💻 System resources..."
echo "   CPU usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "   Memory usage: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
echo "   Disk usage: $(df -h / | awk 'NR==2{printf "%s", $5}')"

# Check recent logs
echo ""
echo "📝 Recent logs (last 10 lines):"
if [ -f "/tmp/echo.log" ]; then
    echo "   From /tmp/echo.log:"
    tail -10 /tmp/echo.log | sed 's/^/   /'
elif [ -f "/var/log/syslog" ]; then
    echo "   From systemd journal:"
    sudo journalctl -u echo_web.service --no-pager -n 10 | sed 's/^/   /'
else
    echo "   No log files found"
fi

echo ""
echo "🏁 Diagnostic complete!"
echo ""
echo "If you see any ❌ errors above, please fix them and run this script again."
echo "For help, check the logs or run: sudo journalctl -u echo_web.service -f"

