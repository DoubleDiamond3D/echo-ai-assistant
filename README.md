<<<<<<< HEAD
# Echo AI Assistant 🤖

A comprehensive AI-powered telepresence and automation platform designed for Raspberry Pi. Echo combines voice interaction, computer vision, face recognition, and intelligent decision-making to create a truly interactive AI assistant.

## ✨ Features

### 🧠 AI Intelligence
- **Local LLM Integration**: Works with Qwen2.5, Llama 3.2, and other Ollama models
- **Natural Conversation**: Voice and text-based interaction with context awareness
- **Decision Making**: AI can make autonomous decisions and ask clarifying questions
- **Multi-language Support**: English, Spanish, French, German, and more

### 🎤 Voice & Audio
- **Voice Input**: Speech recognition with USB microphones and Bluetooth support
- **Text-to-Speech**: High-quality voice synthesis with multiple voice options
- **Audio Processing**: Real-time audio capture and processing
- **Voice Commands**: Natural language voice control

### 👁️ Computer Vision
- **Face Recognition**: Learn and identify people with confidence scoring
- **Camera Streaming**: Real-time MJPEG video streaming
- **Multi-camera Support**: Front, rear, and head camera configurations
- **Visual Processing**: OpenCV-based image analysis

### 🌐 Web Interface
- **Modern Dashboard**: Responsive, mobile-friendly control center
- **Real-time Monitoring**: System metrics, status indicators, and live data
- **Configuration Management**: Web-based settings and API key management
- **Chat Interface**: Interactive conversation with the AI assistant

### 💾 Data Management
- **Comprehensive Backup**: Configurable backup system with compression
- **Chat Logging**: Persistent conversation history and analytics
- **Face Database**: Secure storage and management of face recognition data
- **Export Options**: Data export for analysis and migration

### 🔧 System Features
- **Raspberry Pi Optimized**: Designed for Pi 4B and Pi 5 with resource management
- **Service Management**: Systemd integration for reliable operation
- **Network Configuration**: WiFi setup and remote access capabilities
- **Security**: API key authentication and secure data handling

## 🚀 Quick Start

### Option 1: One-Line Installation (Fastest) ⚡

**Install on any Raspberry Pi in seconds!**

```bash
curl -fsSL https://raw.githubusercontent.com/DoubleDiamond3D/echo-ai-assistant/main/scripts/setup_pi.sh | sudo bash
```

**That's it!** Access your Echo AI Assistant at `http://[PI_IP]:5000`

### Option 2: Pre-built Pi OS Image (Complete Setup) ⭐

**Easiest way to get started with a fresh Pi!**

1. **Download the latest image** from [Releases](https://github.com/DoubleDiamond3D/echo-ai-assistant/releases)
2. **Use Raspberry Pi Imager**:
   - Download [Raspberry Pi Imager](https://www.raspberrypi.org/downloads/)
   - Select "Use custom image"
   - Choose the downloaded `.img.xz` file
   - Flash to your SD card
3. **Boot your Pi** and access `http://[PI_IP]:5000`
4. **Use API token**: `echo-dev-kit-2025`

**What's included:**
- ✅ Echo AI Assistant pre-installed
- ✅ Ollama with Qwen2.5 model ready
- ✅ All dependencies installed
- ✅ Services configured and enabled
- ✅ WiFi setup ready

### Option 2: Manual Installation

**For development or customization:**

1. **Clone the repository:**
   ```bash
   git clone https://github.com/DoubleDiamond3D/echo-ai-assistant.git
   cd echo-ai-assistant
   ```

2. **Run the setup script:**
   ```bash
   sudo scripts/setup_pi.sh
   ```

3. **Configure your settings:**
   - Edit `/opt/echo-ai/.env` with your API keys and preferences
   - Set up your Ollama server URL
   - Add OpenAI API key (optional)

4. **Access the web interface:**
   - Open `http://[PI_IP_ADDRESS]:5000` in your browser
   - Use the API token displayed during setup

### Prerequisites
- Raspberry Pi 4B (4GB+) or Pi 5 (8GB recommended)
- MicroSD card (8GB+ for image, 32GB+ for manual install)
- USB microphone or Bluetooth headset
- Camera (optional but recommended)
- Internet connection

### Development Setup

For development on your local machine:

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Run the application
python run.py
```

## 📖 Configuration

### Environment Variables

Key configuration options in `.env`:

```bash
# Core Settings
ECHO_API_TOKEN=your-secure-api-token
ECHO_AI_MODEL=qwen2.5:latest
OLLAMA_URL=http://localhost:11434

# Voice Settings
ECHO_VOICE_INPUT_ENABLED=1
ECHO_VOICE_INPUT_DEVICE=default
ECHO_VOICE_INPUT_LANGUAGE=en

# Face Recognition
ECHO_FACE_RECOGNITION_ENABLED=1
ECHO_FACE_RECOGNITION_CONFIDENCE=0.6

# Network
ECHO_WIFI_SETUP_ENABLED=1
ECHO_REMOTE_ACCESS_ENABLED=1
CLOUDFLARE_TUNNEL_TOKEN=your-tunnel-token

# Performance
ECHO_MAX_CONCURRENT_REQUESTS=10
ECHO_REQUEST_TIMEOUT=30
```

### AI Model Configuration

Echo supports various AI models through Ollama:

- **Qwen2.5**: Recommended for best performance and accuracy
- **Llama 3.2**: Good alternative with strong reasoning
- **Mistral**: Fast and efficient for resource-constrained environments

### Camera Setup

Configure cameras in the web interface or environment variables:

```bash
# Camera devices (device paths)
CAM_DEVICES='{"head": "/dev/video0", "rear": "/dev/video1"}'
CAM_W=1280
CAM_H=720
CAM_FPS=30
```

## 🎯 Usage

### Web Interface

1. **Dashboard**: Monitor system status, metrics, and control Echo's state
2. **Chat**: Have conversations with Echo through text or voice
3. **Configuration**: Manage AI settings, voice options, and face recognition
4. **Backup**: Create and manage data backups

### Voice Commands

Echo responds to natural language commands:

- "Hello Echo" - Greeting and status check
- "What's the weather like?" - Information requests
- "Take a picture" - Camera control
- "Go to sleep" - Change state to sleeping
- "Who am I?" - Face recognition query

### API Usage

Echo provides a REST API for integration:

```bash
# Send a message to Echo
curl -X POST http://localhost:5000/api/ai/chat \
  -H "X-API-Key: your-api-token" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello Echo!"}'

# Get system status
curl -H "X-API-Key: your-api-token" \
  http://localhost:5000/api/state

# Control voice input
curl -X POST http://localhost:5000/api/voice/start \
  -H "X-API-Key: your-api-token"
```

## 🔧 Advanced Features

### Face Recognition

1. **Add Faces**: Use the web interface to capture and register faces
2. **Recognition**: Echo automatically recognizes people and greets them
3. **Management**: View, edit, and remove known faces
4. **Privacy**: Face data is stored locally and encrypted

### Backup System

1. **Automatic Backups**: Scheduled daily backups with configurable retention
2. **Selective Backup**: Choose what data to include (logs, faces, recordings)
3. **Compression**: Efficient storage with gzip compression
4. **Export**: Download backups for external storage or migration

### Remote Access

1. **Cloudflare Tunnel**: Secure remote access without port forwarding
2. **VPN Support**: Works with WireGuard and other VPN solutions
3. **Dynamic DNS**: Automatic IP address updates
4. **SSL/TLS**: Encrypted connections for security

## 🛠️ Troubleshooting

### Common Issues

**Voice input not working:**
```bash
# Check audio devices
arecord -l
# Test microphone
arecord -f cd -d 5 test.wav && aplay test.wav
```

**Camera not detected:**
```bash
# List video devices
ls /dev/video*
# Test camera
ffmpeg -f v4l2 -i /dev/video0 -t 10 test.mp4
```

**AI responses slow:**
- Check Ollama server status
- Reduce model size (use 7B instead of 14B)
- Increase `ECHO_REQUEST_TIMEOUT`

**High memory usage:**
- Disable face recognition temporarily
- Reduce camera resolution
- Close unused services

### Logs and Debugging

```bash
# View service logs
journalctl -u echo_web.service -f
journalctl -u echo_face.service -f

# Check system resources
htop
df -h
free -h
```

## 📊 Performance Optimization

### Raspberry Pi 4B (4GB)
- Use Qwen2.5 7B model
- Disable camera recordings by default
- Set `ECHO_MAX_CONCURRENT_REQUESTS=5`
- Enable swap file: `sudo dphys-swapfile swapoff && sudo dphys-swapfile swapon`

### Raspberry Pi 5 (8GB)
- Use Qwen2.5 14B model
- Enable all features
- Set `ECHO_MAX_CONCURRENT_REQUESTS=10`
- Consider overclocking for better performance

## 🏗️ Building Pi OS Image

Want to create your own custom Pi OS image? We've got you covered!

### Quick Build
```bash
# Clone the repository
git clone https://github.com/DoubleDiamond3D/echo-ai-assistant.git
cd echo-ai-assistant

# Run the quick build script
chmod +x scripts/quick-build.sh
./scripts/quick-build.sh
```

### Docker Build
```bash
# Build with Docker (easier on non-Linux systems)
chmod +x scripts/docker-build.sh
./scripts/docker-build.sh
```

### Manual Build
```bash
# Install dependencies
sudo apt-get install -y wget unzip qemu-user-static parted kpartx dosfstools e2fsprogs

# Run the full build script
chmod +x scripts/build_pi_os.sh
./scripts/build_pi_os.sh
```

### What You Get
- **Custom Pi OS image** with Echo pre-installed
- **Ready to flash** with Raspberry Pi Imager
- **All services configured** and enabled
- **Qwen2.5 model** ready to use
- **WiFi setup** capabilities

📚 **Detailed guide**: [Pi OS Image Documentation](docs/PI_OS_IMAGE.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ollama](https://ollama.ai/) for local LLM support
- [OpenCV](https://opencv.org/) for computer vision
- [Flask](https://flask.palletsprojects.com/) for the web framework
- [Raspberry Pi Foundation](https://www.raspberrypi.org/) for the amazing hardware

## 📞 Support

- **Documentation**: [Wiki](https://github.com/DoubleDiamond3D/echo-ai-assistant/wiki)
- **Issues**: [GitHub Issues](https://github.com/DoubleDiamond3D/echo-ai-assistant/issues)
- **Discussions**: [GitHub Discussions](https://github.com/DoubleDiamond3D/echo-ai-assistant/discussions)
- **Email**: support@echo-ai.dev

---

**Echo AI Assistant** - Bringing intelligence to your Raspberry Pi! 🤖✨
=======
# echo-ai-assistant
>>>>>>> 4d60de218488589dfc459239e1b43e4715f99dec
