#!/bin/bash
# Install echo-start command system-wide

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (sudo scripts/install-echo-command.sh)"
    exit 1
fi

echo "🚀 Installing 'echo-start' command..."

# Copy the script to /usr/local/bin
cp scripts/echo-start.sh /usr/local/bin/echo-start
chmod +x /usr/local/bin/echo-start

# Create alias for convenience
echo 'alias "set echo free"="echo-start"' >> /etc/bash.bashrc

echo "✅ 'echo-start' command installed successfully!"
echo ""
echo "Usage:"
echo "  echo-start                # Start Echo AI Assistant"
echo "  echo-start --status       # Check status"
echo "  echo-start --stop         # Stop Echo"
echo "  echo-start --restart      # Restart Echo"
echo "  echo-start --logs         # Show logs"
echo ""
echo "Or use the alias:"
echo "  set echo free             # Start Echo AI Assistant"
echo ""
echo "Note: You may need to restart your terminal or run 'source /etc/bash.bashrc'"
