#!/bin/bash
# Custom Echo AI Assistant launcher

set -euo pipefail

ECHO_DIR="/opt/echo-ai"
VENV_DIR="$ECHO_DIR/.venv"
PYTHON_CMD="$VENV_DIR/bin/python"
RUN_SCRIPT="$ECHO_DIR/run.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "Please run as regular user (not root)"
    echo "Usage: echo-start [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --status       Check Echo status"
    echo "  --stop         Stop Echo services"
    echo "  --restart      Restart Echo services"
    echo "  --logs         Show Echo logs"
    echo ""
    exit 1
fi

# Check if Echo is installed
if [[ ! -d "$ECHO_DIR" ]]; then
    error "Echo AI Assistant not found at $ECHO_DIR"
    echo "Please run the installation script first:"
    echo "curl -fsSL https://raw.githubusercontent.com/DoubleDiamond3D/echo-ai-assistant/main/scripts/setup_pi.sh | sudo bash"
    exit 1
fi

# Check if virtual environment exists
if [[ ! -d "$VENV_DIR" ]]; then
    error "Python virtual environment not found at $VENV_DIR"
    echo "Please reinstall Echo AI Assistant"
    exit 1
fi

# Check if run script exists
if [[ ! -f "$RUN_SCRIPT" ]]; then
    error "Echo run script not found at $RUN_SCRIPT"
    echo "Please reinstall Echo AI Assistant"
    exit 1
fi

# Function to check if Echo is running
check_status() {
    if pgrep -f "python.*run.py" > /dev/null; then
        echo "✅ Echo AI Assistant is running"
        echo "🌐 Web interface: http://$(hostname -I | awk '{print $1}'):5000"
        echo "📊 Process ID: $(pgrep -f 'python.*run.py')"
    else
        echo "❌ Echo AI Assistant is not running"
    fi
}

# Function to stop Echo
stop_echo() {
    log "Stopping Echo AI Assistant..."
    if pgrep -f "python.*run.py" > /dev/null; then
        pkill -f "python.*run.py"
        sleep 2
        if pgrep -f "python.*run.py" > /dev/null; then
            warning "Echo is still running, force stopping..."
            pkill -9 -f "python.*run.py"
        fi
        success "Echo AI Assistant stopped"
    else
        warning "Echo AI Assistant is not running"
    fi
}

# Function to start Echo
start_echo() {
    log "Starting Echo AI Assistant..."
    
    # Check if already running
    if pgrep -f "python.*run.py" > /dev/null; then
        warning "Echo AI Assistant is already running"
        check_status
        return 0
    fi
    
    # Change to Echo directory
    cd "$ECHO_DIR"
    
    # Start Echo
    log "Launching Echo AI Assistant..."
    nohup "$PYTHON_CMD" "$RUN_SCRIPT" > /tmp/echo.log 2>&1 &
    
    # Wait a moment and check if it started
    sleep 3
    if pgrep -f "python.*run.py" > /dev/null; then
        success "Echo AI Assistant started successfully!"
        echo "🌐 Web interface: http://$(hostname -I | awk '{print $1}'):5000"
        echo "📝 Logs: tail -f /tmp/echo.log"
    else
        error "Failed to start Echo AI Assistant"
        echo "Check logs: cat /tmp/echo.log"
        exit 1
    fi
}

# Function to show logs
show_logs() {
    if [[ -f "/tmp/echo.log" ]]; then
        echo "📝 Echo AI Assistant logs:"
        echo "=========================="
        tail -f /tmp/echo.log
    else
        warning "No log file found at /tmp/echo.log"
    fi
}

# Main script logic
case "${1:-start}" in
    --help|-h)
        echo "Echo AI Assistant Launcher"
        echo "=========================="
        echo ""
        echo "Usage: echo-start [options]"
        echo ""
        echo "Options:"
        echo "  start         Start Echo AI Assistant (default)"
        echo "  --status      Check Echo status"
        echo "  --stop        Stop Echo services"
        echo "  --restart     Restart Echo services"
        echo "  --logs        Show Echo logs"
        echo "  --help, -h    Show this help message"
        echo ""
        echo "Examples:"
        echo "  echo-start                # Start Echo"
        echo "  echo-start --status       # Check status"
        echo "  echo-start --stop         # Stop Echo"
        echo "  echo-start --restart      # Restart Echo"
        echo "  echo-start --logs         # Show logs"
        ;;
    --status)
        check_status
        ;;
    --stop)
        stop_echo
        ;;
    --restart)
        stop_echo
        sleep 2
        start_echo
        ;;
    --logs)
        show_logs
        ;;
    start)
        start_echo
        ;;
    *)
        error "Unknown option: $1"
        echo "Use 'echo-start --help' for usage information"
        exit 1
        ;;
esac
