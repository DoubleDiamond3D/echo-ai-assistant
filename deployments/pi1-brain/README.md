# Pi #1: Echo Brain

This directory contains all files and services for the Echo Brain Pi (AI processing and backend services).

## Services
- Ollama Server (LLM processing)
- Echo Web Interface (API and dashboard)
- AI Service (decision making)
- Chat Logging (conversation history)
- Backup Service (data management)
- Cloudflare Tunnel (remote access)

## Setup
Run the setup script:
```bash
sudo ./scripts/setup_pi1_brain.sh
```

## Configuration
Edit the `.env` file with your settings:
- Set `ECHO_ROLE=brain`
- Configure `ECHO_FACE_PI_URL` to point to Pi #2
- Set Ollama and AI model settings