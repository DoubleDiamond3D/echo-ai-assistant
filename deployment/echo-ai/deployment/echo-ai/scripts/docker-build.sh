#!/usr/bin/env bash
# Docker-based Pi OS image builder for Echo AI Assistant

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE_NAME="echo-ai-assistant-$(date +%Y%m%d)"

echo "🐳 Building Echo AI Assistant Pi OS image with Docker..."

# Create Dockerfile for building
cat > "$REPO_DIR/Dockerfile.pi-builder" << 'EOF'
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget unzip qemu-user-static \
    parted kpartx dosfstools e2fsprogs \
    xz-utils curl python3 python3-pip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory
WORKDIR /build

# Copy build script
COPY scripts/build_pi_os.sh /build/
RUN chmod +x /build/build_pi_os.sh

# Switch to non-root user
USER builder

# Run build
CMD ["/build/build_pi_os.sh"]
EOF

# Build Docker image
echo "Building Docker image..."
docker build -f "$REPO_DIR/Dockerfile.pi-builder" -t echo-pi-builder "$REPO_DIR"

# Create output directory in workspace
OUTPUT_DIR="$REPO_DIR/build-output"
mkdir -p "$OUTPUT_DIR"

# Run build in container
echo "Building Pi OS image..."
docker run --rm \
    -v "$OUTPUT_DIR:/build-output" \
    -e BUILD_DIR=/build-output \
    -e DOCKER_BUILD=1 \
    echo-pi-builder

echo "✅ Build complete!"
echo "📦 Image: $OUTPUT_DIR/${IMAGE_NAME}.img.xz"
echo "🚀 Ready to flash with Raspberry Pi Imager!"
