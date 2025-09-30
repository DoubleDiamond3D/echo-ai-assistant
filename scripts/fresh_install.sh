#!/bin/bash

# Echo AI Assistant - Fresh Install Script
# This script completely removes and reinstalls Echo AI Assistant

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

echo "🚀 Echo AI Assistant - Fresh Install Script"
echo "==========================================="
echo ""
echo "This script will:"
echo "1. Stop and remove all Echo AI services"
echo "2. Clean up old installation"
echo "3. Install fresh copy from GitHub"
echo "4. Set up virtual environment"
echo "5. Install dependencies"
echo "6. Configure services"
echo "7. Start Echo AI Assistant"
echo ""

# Confirm before proceeding
read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
log "Starting fresh installation..."

# Step 1: Stop and remove services
log "Step 1: Stopping and removing services..."
if systemctl is-active --quiet echo_web.service 2>/dev/null; then
    log "Stopping echo_web.service..."
    sudo systemctl stop echo_web.service || true
fi

if systemctl is-active --quiet echo_face.service 2>/dev/null; then
    log "Stopping echo_face.service..."
    sudo systemctl stop echo_face.service || true
fi

# Disable services
sudo systemctl disable echo_web.service 2>/dev/null || true
sudo systemctl disable echo_face.service 2>/dev/null || true

# Remove service files
sudo rm -f /etc/systemd/system/echo_web.service
sudo rm -f /etc/systemd/system/echo_face.service
sudo systemctl daemon-reload

success "Services stopped and removed"

# Step 2: Clean up old installation
log "Step 2: Cleaning up old installation..."
if [ -d "/opt/echo-ai" ]; then
    log "Removing old installation directory..."
    sudo rm -rf /opt/echo-ai
fi

# Kill any remaining processes
pkill -f "python.*run.py" 2>/dev/null || true
pkill -f "echo_face.py" 2>/dev/null || true

success "Old installation cleaned up"

# Step 3: Create fresh directory
log "Step 3: Creating fresh installation directory..."
sudo mkdir -p /opt/echo-ai
sudo chown $USER:$USER /opt/echo-ai
cd /opt/echo-ai

success "Fresh directory created"

# Step 4: Clone from GitHub
log "Step 4: Cloning from GitHub..."
git clone https://github.com/DoubleDiamond3D/echo-ai-assistant.git .
success "Code cloned from GitHub"

# Step 5: Set up virtual environment
log "Step 5: Setting up Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
success "Virtual environment created"

# Step 6: Install dependencies
log "Step 6: Installing Python dependencies..."
pip install -r requirements.txt
success "Dependencies installed"

# Step 7: Create configuration
log "Step 7: Creating configuration..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    log "Created .env file from template"
else
    log ".env file already exists, keeping existing configuration"
fi

# Step 8: Set up systemd services
log "Step 8: Setting up systemd services..."
sudo cp systemd/echo_web.service /etc/systemd/system/
sudo cp systemd/echo_face.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable echo_web.service
sudo systemctl enable echo_face.service
success "Systemd services configured"

# Step 9: Set proper permissions
log "Step 9: Setting permissions..."
sudo chown -R $USER:$USER /opt/echo-ai
chmod +x scripts/*.sh
success "Permissions set"

# Step 10: Test the installation
log "Step 10: Testing installation..."
if python run.py --help >/dev/null 2>&1; then
    success "Python application test passed"
else
    warning "Python application test failed, but continuing..."
fi

# Step 11: Start services
log "Step 11: Starting Echo AI Assistant..."
sudo systemctl start echo_web.service
sleep 3

if systemctl is-active --quiet echo_web.service; then
    success "Echo AI Assistant started successfully!"
else
    error "Failed to start Echo AI Assistant"
    log "Checking logs..."
    sudo journalctl -u echo_web.service --no-pager -n 20
    exit 1
fi

# Step 12: Verify installation
log "Step 12: Verifying installation..."

# Get the Pi's IP address
PI_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "🎉 Fresh Installation Complete!"
echo "==============================="
echo ""
echo "✅ Echo AI Assistant is running"
echo "🌐 Web interface: http://$PI_IP:5000"
echo "📊 Status: $(systemctl is-active echo_web.service)"
echo "📝 Logs: sudo journalctl -u echo_web.service -f"
echo ""

# Test web interface
log "Testing web interface..."
if command -v curl >/dev/null 2>&1; then
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null | grep -q "200"; then
        success "Web interface is accessible"
    else
        warning "Web interface test failed, but service is running"
    fi
else
    warning "curl not available, cannot test web interface"
fi

echo ""
echo "🔧 Next Steps:"
echo "1. Open http://$PI_IP:5000 in your browser"
echo "2. Configure your API keys in Advanced Settings"
echo "3. Test all the buttons and features"
echo "4. If you have issues, check logs: sudo journalctl -u echo_web.service -f"
echo ""
echo "📚 For help, see the documentation in the docs/ folder"
echo ""

success "Installation completed successfully!"
