#!/usr/bin/env bash
# Docker-based manual Pi OS image builder for Echo AI Assistant
# This script assumes you've manually downloaded the Pi OS image

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE_NAME="echo-ai-assistant-$(date +%Y%m%d)"

echo "🐳 Building Echo AI Assistant Pi OS image with Docker (Manual Mode)..."
echo "📋 Make sure you've downloaded Raspberry Pi OS Lite and placed it in build-output/"

# Create output directory
OUTPUT_DIR="$REPO_DIR/build-output"
mkdir -p "$OUTPUT_DIR"

# Check if Pi OS image exists
if [[ ! -f "$OUTPUT_DIR/raspios-lite.img.xz" ]] && [[ ! -f "$OUTPUT_DIR/raspios-lite.img" ]]; then
    echo "❌ Pi OS image not found!"
    echo "📥 Please download Raspberry Pi OS Lite from:"
    echo "   https://www.raspberrypi.org/downloads/raspberry-pi-os/"
    echo "📁 And place it as: $OUTPUT_DIR/raspios-lite.img.xz"
    exit 1
fi

echo "✅ Pi OS image found"

# Create Dockerfile for building
cat > "$REPO_DIR/Dockerfile.pi-manual" << 'EOF'
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget unzip qemu-user-static \
    parted kpartx dosfstools e2fsprogs \
    xz-utils curl python3 python3-pip \
    sudo util-linux \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory
WORKDIR /build

# Copy build script
COPY scripts/build-pi-manual.sh /build/
RUN chmod +x /build/build-pi-manual.sh

# Switch to non-root user
USER builder

# Run build
CMD ["/build/build-pi-manual.sh"]
EOF

# Build Docker image
echo "Building Docker image..."
docker build -f "$REPO_DIR/Dockerfile.pi-manual" -t echo-pi-manual-builder "$REPO_DIR"

# Run build in container
echo "Building Pi OS image..."
docker run --rm \
    -v "$OUTPUT_DIR:/build-output" \
    -e BUILD_DIR=/build-output \
    -e DOCKER_BUILD=1 \
    echo-pi-manual-builder

echo "✅ Build complete!"
echo "📦 Image: $OUTPUT_DIR/${IMAGE_NAME}.img.xz"
echo "🚀 Ready to flash with Raspberry Pi Imager!"
