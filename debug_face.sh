#!/bin/bash
# Debug script for echo_face.service

echo "=== Echo Face Service Debug ==="
echo "Date: $(date)"
echo ""

# Check if the service file exists
echo "1. Checking service file..."
if [ -f "/etc/systemd/system/echo_face.service" ]; then
    echo "✅ Service file exists"
    echo "Contents:"
    cat /etc/systemd/system/echo_face.service
else
    echo "❌ Service file missing"
    exit 1
fi

echo ""
echo "2. Checking Python environment..."
cd /opt/echo-ai
if [ -f ".venv/bin/python" ]; then
    echo "✅ Python venv exists"
    echo "Python version: $(.venv/bin/python --version)"
else
    echo "❌ Python venv missing"
    exit 1
fi

echo ""
echo "3. Testing Python imports..."
.venv/bin/python -c "
try:
    import pygame
    print('✅ Pygame imported')
except Exception as e:
    print(f'❌ Pygame import failed: {e}')
    exit(1)

try:
    import cv2
    print('✅ OpenCV imported')
except Exception as e:
    print(f'❌ OpenCV import failed: {e}')

try:
    from app.config import Settings
    print('✅ App config imported')
except Exception as e:
    print(f'❌ App config import failed: {e}')
"

echo ""
echo "4. Testing face renderer directly..."
echo "Running: .venv/bin/python echo_face.py"
timeout 10s .venv/bin/python echo_face.py
echo "Exit code: $?"

echo ""
echo "5. Testing with different SDL drivers..."
for driver in fbcon x11 dummy; do
    echo "Testing SDL_VIDEODRIVER=$driver"
    SDL_VIDEODRIVER=$driver timeout 5s .venv/bin/python echo_face.py
    echo "Exit code: $?"
done

echo ""
echo "6. Checking systemd logs..."
echo "Recent logs:"
journalctl -u echo_face.service -n 10 --no-pager

echo ""
echo "7. Checking if display is available..."
echo "DISPLAY: $DISPLAY"
echo "Framebuffer devices:"
ls -la /dev/fb* 2>/dev/null || echo "No framebuffer devices found"

echo ""
echo "8. Testing as echo user..."
sudo -u echo bash -c "cd /opt/echo-ai && .venv/bin/python -c 'import pygame; pygame.init(); print(\"Pygame works as echo user\")'"
echo "Exit code: $?"

echo ""
echo "=== Debug Complete ==="




