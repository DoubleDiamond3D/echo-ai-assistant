# Echo AI Assistant - Dual Pi Architecture

## 🏗️ System Overview

```
┌─────────────────┐    Network    ┌─────────────────┐
│   Pi #1 (Brain) │◄─────────────►│  Pi #2 (Face)   │
│                 │               │                 │
│ • Ollama Server │               │ • Face Display  │
│ • Web Interface │               │ • Voice Input   │
│ • AI Processing │               │ • Wake Word     │
│ • Chat Logging  │               │ • Camera        │
│ • Backup System │               │ • Audio Output  │
│ • Remote Access │               │ • Sensors       │
└─────────────────┘               └─────────────────┘
```

## 🧠 Pi #1: Echo Brain (Current Pi)

### **Services**:
- `ollama.service` - LLM server
- `echo_web.service` - Web interface & API
- `echo_ai.service` - AI decision making
- `echo_chat_log.service` - Conversation logging
- `echo_backup.service` - Data backup
- `cloudflared.service` - Remote access

### **Hardware Requirements**:
- Pi 4B (4GB+) or Pi 5 (8GB recommended)
- Network connection
- Storage for models and logs
- No display/audio hardware needed

### **Network Role**:
- Main API server (port 5000)
- Ollama server (port 11434)
- Cloudflare tunnel endpoint
- Data storage and backup

## 🎭 Pi #2: Echo Face (New Pi)

### **Services**:
- `echo_face.service` - Visual face display
- `echo_voice_input.service` - Voice recognition
- `echo_wake_word.service` - Wake word detection
- `echo_camera.service` - Camera streaming
- `echo_speech_output.service` - Text-to-speech
- `echo_sensors.service` - GPIO sensors (optional)

### **Hardware Requirements**:
- Pi 4B with Desktop OS
- Display (touchscreen, HDMI monitor, etc.)
- USB microphone or Bluetooth headset
- USB camera (optional)
- Speakers for audio output

### **Network Role**:
- Interface client (connects to Pi #1)
- Real-time audio/video processing
- Physical world interaction

## 🌐 Communication Protocol

### **Pi #2 → Pi #1 (Input)**:
```bash
POST http://pi1:5000/api/voice/input
{
  "text": "Hello Echo",
  "confidence": 0.95,
  "timestamp": 1234567890
}

POST http://pi1:5000/api/camera/frame
{
  "image_data": "base64...",
  "faces_detected": 2,
  "timestamp": 1234567890
}
```

### **Pi #1 → Pi #2 (Output)**:
```bash
POST http://pi2:5001/api/face/state
{
  "mood": "talking",
  "message": "Hello! How can I help you?",
  "should_speak": true
}

POST http://pi2:5001/api/display/command
{
  "action": "show_notification",
  "text": "System update available"
}
```

## 📁 Project Structure

```
echo-ai-assistant/
├── pi1-brain/              # Pi #1 specific files
│   ├── services/           # Brain services
│   ├── scripts/            # Setup scripts for Pi #1
│   └── configs/            # Pi #1 configurations
├── pi2-face/               # Pi #2 specific files
│   ├── services/           # Face services
│   ├── scripts/            # Setup scripts for Pi #2
│   └── configs/            # Pi #2 configurations
├── shared/                 # Common code
│   ├── api/                # API definitions
│   ├── utils/              # Shared utilities
│   └── models/             # Data models
└── docs/                   # Documentation
```

## 🚀 Deployment Process

### **Phase 1: Prepare Pi #1 (Current)**
1. Reorganize current setup
2. Add Pi #2 communication APIs
3. Disable face/voice services
4. Test AI functionality

### **Phase 2: Setup Pi #2 (New)**
1. Flash Pi OS Desktop
2. Install Echo Face components
3. Configure display and audio
4. Test face rendering

### **Phase 3: Integration**
1. Configure network communication
2. Test end-to-end functionality
3. Set up monitoring and logging
4. Deploy to production

## 🔧 Configuration

### **Pi #1 (.env)**:
```bash
# Pi #1 (Brain) Configuration
ECHO_ROLE=brain
ECHO_FACE_PI_URL=http://192.168.1.102:5001
OLLAMA_URL=http://localhost:11434
ECHO_FACE_DISPLAY_ENABLED=0
ECHO_VOICE_INPUT_ENABLED=0
ECHO_CAMERA_ENABLED=0
```

### **Pi #2 (.env)**:
```bash
# Pi #2 (Face) Configuration
ECHO_ROLE=face
ECHO_BRAIN_PI_URL=http://192.168.1.101:5000
OLLAMA_URL=http://192.168.1.101:11434
ECHO_WEB_INTERFACE_ENABLED=0
ECHO_BACKUP_ENABLED=0
ECHO_FACE_DISPLAY_ENABLED=1
ECHO_VOICE_INPUT_ENABLED=1
ECHO_CAMERA_ENABLED=1
```

## 📊 Benefits

### **Performance**:
- Dedicated AI processing on Pi #1
- Real-time interface on Pi #2
- No resource conflicts

### **Reliability**:
- Fault isolation between systems
- Independent service restarts
- Better error handling

### **Scalability**:
- Easy to upgrade individual Pis
- Can add more Face Pis later
- Modular architecture

## 🔍 Monitoring

### **Health Checks**:
- Pi #1 monitors Pi #2 connectivity
- Pi #2 monitors Pi #1 API availability
- Automatic failover to local processing

### **Logging**:
- Centralized logs on Pi #1
- Local logs on Pi #2 for debugging
- Network communication logs

## 🛠️ Troubleshooting

### **Common Issues**:
1. **Network connectivity** - Check IP addresses and firewall
2. **Service dependencies** - Ensure proper startup order
3. **Resource usage** - Monitor CPU/RAM on both Pis
4. **Display issues** - Pi #2 specific, isolated from AI

### **Recovery Procedures**:
1. **Pi #2 offline** - Pi #1 continues AI processing
2. **Pi #1 offline** - Pi #2 shows offline status
3. **Network issues** - Local fallback processing