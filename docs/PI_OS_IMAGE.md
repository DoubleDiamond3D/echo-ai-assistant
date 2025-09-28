# Echo AI Assistant - Custom Raspberry Pi OS Image

This guide explains how to create a custom Raspberry Pi OS image with Echo AI Assistant pre-installed, ready to flash with Raspberry Pi Imager.

## 🎯 Overview

The custom Pi OS image includes:
- ✅ Echo AI Assistant pre-installed and configured
- ✅ Ollama with Qwen2.5 model ready
- ✅ All dependencies installed
- ✅ Services enabled and configured
- ✅ WiFi setup capabilities
- ✅ SSH enabled for remote access
- ✅ Camera and audio pre-configured

## 🚀 Quick Start

### Option 1: Use Pre-built Image (Recommended)

1. **Download the latest release** from GitHub
2. **Use Raspberry Pi Imager**:
   - Download [Raspberry Pi Imager](https://www.raspberrypi.org/downloads/)
   - Select "Use custom image"
   - Choose the downloaded `.img.xz` file
   - Flash to your SD card
3. **Boot your Pi** and access `http://[PI_IP]:5000`
4. **Use API token**: `echo-dev-kit-2025`

### Option 2: Build Your Own Image

#### Prerequisites

- Ubuntu 20.04+ or similar Linux distribution
- At least 8GB free disk space
- Docker (optional, for easier building)

#### Method 1: Direct Build

```bash
# Clone the repository
git clone https://github.com/yourusername/echo-ai-assistant.git
cd echo-ai-assistant

# Install dependencies
sudo apt-get update
sudo apt-get install -y wget unzip qemu-user-static parted kpartx dosfstools e2fsprogs

# Run the build script
chmod +x scripts/build_pi_os.sh
./scripts/build_pi_os.sh
```

#### Method 2: Docker Build

```bash
# Clone the repository
git clone https://github.com/yourusername/echo-ai-assistant.git
cd echo-ai-assistant

# Build with Docker
chmod +x scripts/docker-build.sh
./scripts/docker-build.sh
```

## 📋 What's Included

### Pre-installed Software
- **Echo AI Assistant**: Complete application with all services
- **Ollama**: Local LLM server with Qwen2.5 model
- **Python 3.9+**: With all required packages
- **OpenCV**: Computer vision library
- **FFmpeg**: Audio/video processing
- **espeak**: Text-to-speech engine
- **NetworkManager**: WiFi configuration
- **SSH**: Remote access enabled

### Pre-configured Services
- **echo_web.service**: Web interface and API
- **echo_face.service**: Face display service
- **ollama.service**: AI model server
- **ssh.service**: Remote access
- **NetworkManager.service**: WiFi management

### Default Configuration
```bash
# API Authentication
ECHO_API_TOKEN=echo-dev-kit-2025

# AI Model
ECHO_AI_MODEL=qwen2.5:latest
OLLAMA_URL=http://localhost:11434

# Voice Settings
ECHO_VOICE_INPUT_ENABLED=1
ECHO_VOICE_INPUT_DEVICE=default

# Face Recognition
ECHO_FACE_RECOGNITION_ENABLED=1
ECHO_FACE_RECOGNITION_CONFIDENCE=0.6

# Network
ECHO_WIFI_SETUP_ENABLED=1
ECHO_REMOTE_ACCESS_ENABLED=1
```

## 🔧 First Boot Process

When you first boot the Pi with the custom image:

1. **Network Setup**: The Pi will attempt to connect to WiFi if configured
2. **System Update**: Automatic package updates
3. **Ollama Installation**: Downloads and installs Ollama
4. **Model Download**: Pulls Qwen2.5 model (may take time)
5. **Service Startup**: Starts all Echo services
6. **Ready**: Web interface available at `http://[PI_IP]:5000`

### First Boot Script

The image includes a first-boot script that:
- Waits for network connectivity
- Updates system packages
- Installs Ollama
- Downloads the AI model
- Starts Echo services
- Creates a welcome message

## 🌐 Network Configuration

### WiFi Setup

The image supports WiFi configuration in two ways:

#### Method 1: Pre-configure (Before Flashing)
1. Edit `wpa_supplicant.conf` in the boot partition
2. Add your WiFi credentials
3. Flash the image

#### Method 2: Post-boot Configuration
1. Connect via SSH or direct console
2. Use `echo-wifi-setup` command
3. Or configure through the web interface

### Static IP (Optional)
To set a static IP, edit `/etc/dhcpcd.conf`:
```bash
interface wlan0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8
```

## 🔐 Security Considerations

### Default Credentials
- **API Token**: `echo-dev-kit-2025` (CHANGE THIS!)
- **SSH**: Enabled with password authentication
- **User**: `echo` (no password by default)

### Recommended Security Steps
1. **Change API Token**: Use the web interface or edit `.env`
2. **Set SSH Password**: `sudo passwd echo`
3. **Enable SSH Keys**: Add your public key to `/home/echo/.ssh/authorized_keys`
4. **Disable Password Auth**: Edit `/etc/ssh/sshd_config`
5. **Update System**: `sudo apt update && sudo apt upgrade`

## 📱 Using the Image

### Web Interface
1. **Access**: `http://[PI_IP]:5000`
2. **Login**: Use API token `echo-dev-kit-2025`
3. **Configure**: Set up your preferences
4. **Start Chatting**: Begin using Echo!

### SSH Access
```bash
ssh echo@[PI_IP]
# No password required initially
```

### Service Management
```bash
# Check status
sudo systemctl status echo_web.service
sudo systemctl status echo_face.service

# Restart services
sudo systemctl restart echo_web.service
sudo systemctl restart echo_face.service

# View logs
journalctl -u echo_web.service -f
```

## 🛠️ Customization

### Before Building
Edit the build script to customize:
- Default configuration values
- Additional packages
- Service settings
- User accounts

### After Flashing
- Use the web interface for most settings
- Edit `/opt/echo-ai/.env` for advanced configuration
- Modify systemd services as needed

## 📊 Image Specifications

### Base Image
- **OS**: Raspberry Pi OS Lite (Bookworm)
- **Architecture**: ARM HF (32-bit)
- **Size**: ~2GB (compressed ~800MB)
- **Kernel**: 6.1.x

### Storage Requirements
- **Minimum SD Card**: 8GB
- **Recommended**: 16GB+
- **Used Space**: ~4GB after first boot

### Performance
- **Pi 4B (4GB)**: Good performance with Qwen2.5 7B
- **Pi 5 (8GB)**: Excellent performance with Qwen2.5 14B
- **Pi 3B+**: Limited performance, use smaller models

## 🐛 Troubleshooting

### Common Issues

**Image won't boot:**
- Verify SD card integrity
- Try a different SD card
- Check power supply (2.5A+ recommended)

**No network connectivity:**
- Check WiFi credentials
- Verify network configuration
- Use Ethernet cable for initial setup

**Services not starting:**
- Check logs: `journalctl -u echo_web.service`
- Verify configuration: `/opt/echo-ai/.env`
- Restart services: `sudo systemctl restart echo_web.service`

**AI model not loading:**
- Check Ollama status: `systemctl status ollama`
- Verify model download: `ollama list`
- Check available space: `df -h`

### Getting Help

1. **Check Logs**: `journalctl -u echo_web.service -f`
2. **Web Interface**: Access the dashboard for status
3. **GitHub Issues**: Report problems on GitHub
4. **Documentation**: Check the main README.md

## 🔄 Updates

### Updating Echo
```bash
cd /opt/echo-ai
sudo git pull
sudo systemctl restart echo_web.service
```

### Updating the Image
- Download the latest image
- Flash to SD card
- Restore your configuration

## 📚 Additional Resources

- [Main Documentation](../README.md)
- [API Reference](../docs/API.md)
- [Configuration Guide](../docs/CONFIGURATION.md)
- [GitHub Repository](https://github.com/yourusername/echo-ai-assistant)

---

**Ready to build your Echo AI Assistant Pi OS image?** 🚀

Follow the steps above and you'll have a complete, ready-to-use AI assistant that boots directly from an SD card!
