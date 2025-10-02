# Echo Face Service Troubleshooting Guide

This guide helps you fix issues with the `echo_face.service` that won't start or restart properly.

## 🔍 Common Issues

### 1. **Service Appears to Do Nothing**
- No error messages
- Service shows as "inactive" or "failed"
- `systemctl restart` seems to work but nothing happens

### 2. **Display/Graphics Issues**
- "No available video device" errors
- SDL initialization failures
- Permission denied errors for `/dev/fb0`

### 3. **User/Permission Issues**
- XDG_RUNTIME_DIR errors
- Video group membership problems
- File permission issues

## 🛠️ Quick Fix

Run the automated fix script:

```bash
sudo ./scripts/fix_face_service.sh
```

This script will:
- ✅ Create/fix the echo user and groups
- ✅ Fix directory and framebuffer permissions  
- ✅ Install an improved service configuration
- ✅ Test the service startup

## 🔧 Manual Troubleshooting

### Step 1: Diagnose the Issue

```bash
# Run comprehensive diagnostics
python3 scripts/diagnose_face_service.py

# Check service status
sudo systemctl status echo_face.service

# View recent logs
journalctl -u echo_face.service -n 20
```

### Step 2: Test Face Renderer Manually

```bash
# Test different display drivers
python3 scripts/test_face_renderer.py

# Test as echo user
sudo -u echo python3 scripts/test_face_renderer.py
```

### Step 3: Fix Common Issues

#### **User and Groups**
```bash
# Create echo user if missing
sudo useradd -r -s /bin/bash -d /opt/echo-ai echo

# Add to required groups
sudo usermod -a -G video,audio,input,render echo

# Verify groups
groups echo
```

#### **Directory Permissions**
```bash
# Fix ownership
sudo chown -R echo:echo /opt/echo-ai

# Create and fix XDG_RUNTIME_DIR
sudo mkdir -p /run/user/1000
sudo chown echo:echo /run/user/1000
sudo chmod 700 /run/user/1000
```

#### **Framebuffer Permissions**
```bash
# Fix framebuffer access
sudo chown echo:video /dev/fb0
sudo chmod 664 /dev/fb0

# Make permanent (add to udev rules)
echo 'KERNEL=="fb0", GROUP="video", MODE="0664"' | sudo tee /etc/udev/rules.d/99-framebuffer.rules
```

### Step 4: Choose the Right Service Configuration

#### **For Headless Pi (No Monitor)**
```bash
sudo systemctl disable echo_face.service
sudo systemctl enable echo_face_headless.service
sudo systemctl start echo_face_headless.service
```

#### **For Pi with Monitor**
```bash
sudo systemctl disable echo_face.service
sudo systemctl enable echo_face_kmsdrm.service
sudo systemctl start echo_face_kmsdrm.service
```

#### **For Development/Testing**
```bash
sudo systemctl disable echo_face.service
sudo systemctl enable echo_face_improved.service
sudo systemctl start echo_face_improved.service
```

## 📋 Service Configuration Options

### Available Service Files

| Service File | Use Case | Display Driver |
|--------------|----------|----------------|
| `echo_face.service` | Original (problematic) | X11 |
| `echo_face_headless.service` | No monitor attached | fbcon |
| `echo_face_kmsdrm.service` | Modern Pi with monitor | kmsdrm |
| `echo_face_improved.service` | Fixed version of original | fbcon |
| `echo_face_fixed.service` | X11 with fixes | x11 |

### Environment Variables

Key environment variables for the face service:

```bash
# Display driver selection
SDL_VIDEODRIVER=fbcon          # Framebuffer (headless)
SDL_VIDEODRIVER=kmsdrm         # Modern DRM (with monitor)
SDL_VIDEODRIVER=x11            # X11 (desktop environment)
SDL_VIDEODRIVER=dummy          # Testing only

# Framebuffer device
SDL_FBDEV=/dev/fb0

# Python settings
PYTHONUNBUFFERED=1
PYGAME_HIDE_SUPPORT_PROMPT=1

# Fullscreen mode
ECHO_FACE_FULLSCREEN=1         # 1 for fullscreen, 0 for windowed
```

## 🧪 Testing Commands

### Test Service Startup
```bash
# Start service and watch logs
sudo systemctl start echo_face.service
journalctl -u echo_face.service -f
```

### Test Manual Execution
```bash
# As echo user with framebuffer
sudo -u echo SDL_VIDEODRIVER=fbcon python3 /opt/echo-ai/echo_face.py

# As echo user with dummy driver (testing)
sudo -u echo SDL_VIDEODRIVER=dummy python3 /opt/echo-ai/echo_face.py
```

### Check System Resources
```bash
# Check if process is running
pgrep -f echo_face.py

# Check system resources
htop | grep echo

# Check graphics devices
ls -l /dev/fb* /dev/dri/*
```

## 🔍 Log Analysis

### Common Error Messages

**"No available video device"**
- **Cause**: SDL can't find a display
- **Fix**: Set correct `SDL_VIDEODRIVER` and fix permissions

**"Permission denied"**
- **Cause**: User not in video group or wrong file permissions
- **Fix**: Add user to video group, fix `/dev/fb0` permissions

**"XDG_RUNTIME_DIR not set"**
- **Cause**: Missing runtime directory
- **Fix**: Create `/run/user/1000` with correct ownership

**"Failed to initialize pygame"**
- **Cause**: Missing pygame or SDL libraries
- **Fix**: Install pygame: `pip3 install pygame`

### Useful Log Commands
```bash
# Real-time logs
journalctl -u echo_face.service -f

# Last 50 lines
journalctl -u echo_face.service -n 50

# Logs since last boot
journalctl -u echo_face.service -b

# Logs with timestamps
journalctl -u echo_face.service -o short-precise
```

## 🚀 Performance Optimization

### Resource Limits
The improved service includes resource limits:

```ini
MemoryMax=256M      # Limit memory usage
CPUQuota=50%        # Limit CPU usage
```

### Frame Rate Optimization
In `echo_face.py`, the frame rate is limited to 30 FPS:

```python
clock.tick(30)  # 30 FPS to reduce CPU usage
```

You can adjust this based on your Pi's performance.

## 🔐 Security Considerations

The improved service includes security hardening:

```ini
NoNewPrivileges=true    # Prevent privilege escalation
PrivateTmp=true         # Private /tmp directory
ProtectSystem=strict    # Read-only system directories
ProtectHome=true        # Protect user home directories
```

## 📚 Additional Resources

- [Pygame Documentation](https://www.pygame.org/docs/)
- [SDL Video Drivers](https://wiki.libsdl.org/SDL2/FAQUsingSDL)
- [Raspberry Pi Graphics](https://www.raspberrypi.org/documentation/configuration/config-txt/video.md)
- [Systemd Service Files](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

## 🆘 Getting Help

If you're still having issues:

1. **Run full diagnostics**: `python3 scripts/diagnose_face_service.py`
2. **Check the logs**: `journalctl -u echo_face.service -n 50`
3. **Test manually**: `python3 scripts/test_face_renderer.py`
4. **Try different service**: Switch to `echo_face_headless.service`

---

**Most face service issues are related to display drivers and permissions. The automated fix script should resolve 90% of problems!** 🎯