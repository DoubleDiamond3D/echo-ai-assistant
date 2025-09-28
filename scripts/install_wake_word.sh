#!/usr/bin/env bash
# Install wake word detection dependencies for Echo AI Assistant

set -euo pipefail

echo "🎤 Installing Wake Word Detection Dependencies"
echo "=============================================="

# Check if we're running as root
if [[ $EUID -eq 0 ]]; then
    echo "Please run as regular user (not root)"
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
VENV_DIR="$SCRIPT_DIR/.venv"

# Check if virtual environment exists
if [[ ! -d "$VENV_DIR" ]]; then
    echo "❌ Virtual environment not found at $VENV_DIR"
    echo "Please run the main setup script first: sudo scripts/setup_pi.sh"
    exit 1
fi

echo "📦 Installing audio system packages..."
sudo apt update
sudo apt install -y portaudio19-dev python3-pyaudio

echo "🐍 Installing Python packages..."

# Install PyAudio first (system dependency)
"$VENV_DIR/bin/pip" install pyaudio

# Install wake word engines (optional)
echo ""
echo "Choose wake word engine to install:"
echo "1) Porcupine (recommended - high accuracy, requires API key)"
echo "2) Snowboy (offline, requires model file)"
echo "3) Both"
echo "4) Skip wake word installation"
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "Installing Porcupine..."
        "$VENV_DIR/bin/pip" install pvporcupine
        echo "✅ Porcupine installed"
        echo "📝 Get your API key from: https://picovoice.ai/"
        echo "   Set it in your .env file: PORCUPINE_ACCESS_KEY=your_key_here"
        ;;
    2)
        echo "Installing Snowboy..."
        "$VENV_DIR/bin/pip" install snowboy
        echo "✅ Snowboy installed"
        echo "📝 Download a model file and set SNOWBOY_MODEL_PATH in your .env"
        ;;
    3)
        echo "Installing both Porcupine and Snowboy..."
        "$VENV_DIR/bin/pip" install pvporcupine snowboy
        echo "✅ Both engines installed"
        echo "📝 Configure your preferred engine in .env"
        ;;
    4)
        echo "Skipping wake word installation"
        ;;
    *)
        echo "Invalid choice, skipping wake word installation"
        ;;
esac

echo ""
echo "🔧 Testing audio setup..."
if "$VENV_DIR/bin/python" -c "import pyaudio; print('✅ PyAudio working')" 2>/dev/null; then
    echo "✅ Audio setup successful"
else
    echo "❌ Audio setup failed - check your microphone connection"
fi

echo ""
echo "🎯 Wake word setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure your .env file with wake word settings"
echo "2. Get API keys for your chosen engine (if needed)"
echo "3. Restart Echo: sudo systemctl restart echo_web.service"
echo ""
echo "Available wake word engines:"
echo "- Porcupine: High accuracy, requires API key"
echo "- Snowboy: Offline, requires model file"
echo "- Vosk: Offline, requires model download"
echo ""
echo "Configuration example in .env:"
echo "ECHO_WAKE_WORD_ENABLED=1"
echo "ECHO_WAKE_WORD_ENGINE=porcupine"
echo "ECHO_WAKE_WORD_KEYWORD=hey echo"
echo "ECHO_WAKE_WORD_SENSITIVITY=0.5"
