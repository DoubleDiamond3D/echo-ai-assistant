# Echo AI Assistant Deployment Package

This package contains everything needed to install Echo AI Assistant on a Raspberry Pi.

## Quick Start

1. **Copy this folder to your Raspberry Pi**
2. **Run the installation script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
3. **Access the web interface:** http://[PI_IP]:5000
4. **Use API token:** `echo-dev-kit-2025`

## What's Included

- ✅ Echo AI Assistant application
- ✅ Installation script with all dependencies
- ✅ Systemd services for auto-start
- ✅ Configuration files
- ✅ Documentation

## Requirements

- Raspberry Pi 4B (4GB+) or Pi 5 (8GB recommended)
- MicroSD card (32GB+ recommended)
- Internet connection
- USB microphone (optional)
- Camera (optional)

## Configuration

After installation, edit `/opt/echo-ai/.env` to configure:
- AI model settings
- Voice input options
- Face recognition settings
- Network configuration

## Support

- Documentation: `/opt/echo-ai/README.md`
- Logs: `journalctl -u echo_web.service -f`
- Configuration: `/opt/echo-ai/.env`

Happy chatting! 🤖✨
