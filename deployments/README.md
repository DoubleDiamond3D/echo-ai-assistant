# Echo AI Assistant - Multi-Pi Deployment 🤖

A distributed Echo AI Assistant setup with dedicated Brain and Face Pis for optimal performance.

## 🏗️ Architecture Overview

```
┌─────────────────┐    Network    ┌─────────────────┐
│   Pi #1 (Brain) │◄─────────────►│  Pi #2 (Face)   │
│                 │               │                 │
│ • AI Processing │               │ • Face Display  │
│ • Web Interface │               │ • Voice Input   │
│ • Ollama Server │               │ • Wake Word     │
│ • Data Storage  │               │ • Camera        │
│ • Remote Access │               │ • Audio Output  │
└─────────────────┘               └─────────────────┘
```

## 🚀 Quick Deployment

### **Deploy to Pi #1 (Brain)**
```bash
# Clone repository
git clone https://github.com/DoubleDiamond3D/echo-ai-assistant.git
cd echo-ai-assistant/deployments

# Run deployment script
chmod +x scripts/deploy-pi1.sh
./scripts/deploy-pi1.sh
```

### **Deploy to Pi #2 (Face)**
```bash
# Clone repository
git clone https://github.com/DoubleDiamond3D/echo-ai-assistant.git
cd echo-ai-assistant/deployments

# Run deployment script
chmod +x scripts/deploy-pi2.sh
./scripts/deploy-pi2.sh
```

## 📁 Directory Structure

```
deployments/
├── pi1-brain/              # Brain Pi files
│   ├── app/                # Web app and services
│   ├── scripts/            # Brain-specific scripts
│   ├── systemd/            # Brain service files
│   └── requirements.txt    # Python dependencies
├── pi2-face/               # Face Pi files
│   ├── echo_face.py        # Face display application
│   ├── scripts/            # Face-specific scripts
│   ├── configs/            # Face configurations
│   └── requirements.txt    # Python dependencies
├── shared/                 # Common components
│   └── api/                # Shared API definitions
├── scripts/                # Deployment scripts
│   ├── deploy-pi1.sh       # Deploy to Brain Pi
│   └── deploy-pi2.sh       # Deploy to Face Pi
└── docs/                   # Documentation
```

## 🧠 Pi #1: Brain (AI Processing)

### **Services**:
- Ollama Server (LLM processing)
- Echo Web Interface (API and dashboard)
- AI Service (decision making)
- Chat Logging (conversation history)
- Backup Service (data management)

### **Hardware Requirements**:
- Raspberry Pi 4B (4GB+) or Pi 5 (8GB recommended)
- MicroSD card (32GB+)
- Network connection
- No display/audio hardware needed

### **Network Ports**:
- `5000` - Web interface and API
- `11434` - Ollama server

## 🎭 Pi #2: Face (Interface)

### **Services**:
- Face Display (visual interface)
- Voice Input (speech recognition)
- Wake Word Detection
- Camera Service (optional)
- Audio Output

### **Hardware Requirements**:
- Raspberry Pi 4B with Desktop OS
- Display (touchscreen or HDMI monitor)
- USB microphone or Bluetooth headset
- USB camera (optional)
- Speakers for audio output

### **Network Ports**:
- `5001` - Face interface API

## ⚙️ Configuration

### **Pi #1 (.env)**:
```bash
ECHO_ROLE=brain
ECHO_FACE_PI_URL=http://192.168.1.102:5001
OLLAMA_URL=http://localhost:11434
ECHO_FACE_DISPLAY_ENABLED=0
ECHO_VOICE_INPUT_ENABLED=0
ECHO_CAMERA_ENABLED=0
```

### **Pi #2 (.env)**:
```bash
ECHO_ROLE=face
ECHO_BRAIN_PI_URL=http://192.168.1.101:5000
OLLAMA_URL=http://192.168.1.101:11434
ECHO_FACE_DISPLAY_ENABLED=1
ECHO_VOICE_INPUT_ENABLED=1
ECHO_CAMERA_ENABLED=1
```

## 🔧 Management Commands

### **Start Services**:
```bash
# Pi #1 (Brain)
sudo systemctl start echo_web.service

# Pi #2 (Face)
sudo systemctl start echo_face.service
```

### **Check Status**:
```bash
# Pi #1
sudo systemctl status echo_web.service

# Pi #2
sudo systemctl status echo_face.service
```

### **View Logs**:
```bash
# Pi #1
journalctl -u echo_web.service -f

# Pi #2
journalctl -u echo_face.service -f
```

## 🛠️ Troubleshooting

### **Common Issues**:
1. **Network connectivity** - Verify IP addresses in .env files
2. **Service startup** - Check systemd service status
3. **Dependencies** - Ensure Python packages are installed
4. **Permissions** - Verify file ownership and permissions

### **Diagnostic Scripts**:
```bash
# Test Ollama connection (Pi #1)
python3 /opt/echo-ai/scripts/test_ollama.py

# Test face display (Pi #2)
python3 /opt/echo-ai/scripts/test_face_display.py

# Full system diagnostics
python3 /opt/echo-ai/scripts/diagnose_connection.py
```

## 📖 Documentation

- [Dual Pi Architecture](docs/DUAL_PI_ARCHITECTURE.md) - Complete architecture guide
- [Face Service Troubleshooting](docs/FACE_SERVICE_TROUBLESHOOTING.md) - Display issues
- [Deployment Guide](docs/DEPLOYMENT.md) - Detailed deployment instructions

## 🔄 Updates

### **Update Pi #1**:
```bash
cd /opt/echo-ai
git pull origin main
./scripts/deploy-pi1.sh
sudo systemctl restart echo_web.service
```

### **Update Pi #2**:
```bash
cd /opt/echo-ai
git pull origin main
./scripts/deploy-pi2.sh
sudo systemctl restart echo_face.service
```

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/DoubleDiamond3D/echo-ai-assistant/issues)
- **Documentation**: [Wiki](https://github.com/DoubleDiamond3D/echo-ai-assistant/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/DoubleDiamond3D/echo-ai-assistant/discussions)

---

**Echo AI Assistant** - Distributed intelligence across multiple Raspberry Pis! 🤖✨
