# 🚀 Quick Installation Guide

## One-Line Installation

Run this single command on your Raspberry Pi to install Echo AI Assistant:

```bash
curl -fsSL https://raw.githubusercontent.com/DoubleDiamond3D/echo-ai-assistant/main/scripts/setup_pi.sh | sudo bash
```

## What This Does

✅ **Downloads** the latest code from GitHub  
✅ **Installs** all required system packages  
✅ **Sets up** Python virtual environment  
✅ **Configures** system services  
✅ **Creates** secure API tokens  
✅ **Starts** Echo AI Assistant automatically  

## Prerequisites

- **Raspberry Pi 4B or Pi 5** (recommended)
- **Raspberry Pi OS** (any recent version)
- **Internet connection**
- **At least 2GB free space**

## After Installation

1. **Access the web interface:** `http://[PI_IP]:5000`
2. **Find your API token:** Check the terminal output or run `cat /opt/echo-ai/.env`
3. **Configure your AI model:** Add your Ollama server URL in the web interface

## Manual Installation (Alternative)

If you prefer to download manually:

```bash
# Download the project
git clone https://github.com/DoubleDiamond3D/echo-ai-assistant.git
cd echo-ai-assistant

# Run the setup script
sudo scripts/setup_pi.sh
```

## Troubleshooting

- **Permission denied?** Make sure you're running with `sudo`
- **No internet?** Check your WiFi connection or use ethernet
- **Services not starting?** Check logs: `journalctl -u echo_web.service -f`

## Need Help?

- 📚 **Documentation:** [GitHub Wiki](https://github.com/DoubleDiamond3D/echo-ai-assistant/wiki)
- 🐛 **Report Issues:** [GitHub Issues](https://github.com/DoubleDiamond3D/echo-ai-assistant/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/DoubleDiamond3D/echo-ai-assistant/discussions)

---

**Ready to get started?** Just run the one-liner above! 🤖✨
