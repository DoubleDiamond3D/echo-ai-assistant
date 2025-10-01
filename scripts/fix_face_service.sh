#!/bin/bash
# Fix echo_face.service issues

set -e

echo "🤖 Echo AI - Face Service Fix"
echo "============================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script needs to be run as root (sudo)"
   exit 1
fi

# 1. Stop the current service
print_info "Stopping echo_face service..."
systemctl stop echo_face.service 2>/dev/null || true

# 2. Check if echo user exists
if ! id "echo" &>/dev/null; then
    print_warning "Echo user doesn't exist, creating..."
    useradd -r -s /bin/bash -d /opt/echo-ai echo
    print_status "Echo user created"
fi

# 3. Add echo user to necessary groups
print_info "Adding echo user to required groups..."
usermod -a -G video,audio,input,render echo 2>/dev/null || true
print_status "User groups updated"

# 4. Fix directory permissions
print_info "Fixing directory permissions..."
mkdir -p /opt/echo-ai/data
mkdir -p /run/user/1000
chown -R echo:echo /opt/echo-ai
chown echo:echo /run/user/1000
chmod 700 /run/user/1000
print_status "Directory permissions fixed"

# 5. Fix framebuffer permissions
print_info "Fixing framebuffer permissions..."
if [[ -e /dev/fb0 ]]; then
    chown echo:video /dev/fb0
    chmod 664 /dev/fb0
    print_status "Framebuffer permissions fixed"
else
    print_warning "Framebuffer /dev/fb0 not found"
fi

# 6. Install the improved service file
print_info "Installing improved service file..."
if [[ -f "systemd/echo_face_improved.service" ]]; then
    cp systemd/echo_face_improved.service /etc/systemd/system/echo_face.service
    print_status "Service file updated"
else
    print_warning "Improved service file not found, using existing"
fi

# 7. Reload systemd and enable service
print_info "Reloading systemd configuration..."
systemctl daemon-reload
systemctl enable echo_face.service
print_status "Service enabled"

# 8. Test the service
print_info "Testing service startup..."
if systemctl start echo_face.service; then
    print_status "Service started successfully"
    
    # Wait a moment and check status
    sleep 3
    if systemctl is-active --quiet echo_face.service; then
        print_status "Service is running"
    else
        print_error "Service failed to stay running"
        print_info "Checking logs..."
        journalctl -u echo_face.service --no-pager -n 10
    fi
else
    print_error "Service failed to start"
    print_info "Checking logs..."
    journalctl -u echo_face.service --no-pager -n 10
fi

echo
print_info "Face service fix completed!"
echo
print_info "Useful commands:"
echo "- Check status: systemctl status echo_face.service"
echo "- View logs: journalctl -u echo_face.service -f"
echo "- Restart: sudo systemctl restart echo_face.service"
echo "- Run diagnostics: python3 scripts/diagnose_face_service.py"