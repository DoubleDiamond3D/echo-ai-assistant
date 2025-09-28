#!/usr/bin/env bash
# Quick build script for Echo AI Assistant Pi OS image

set -euo pipefail

echo "🤖 Echo AI Assistant - Quick Pi OS Image Builder"
echo "================================================="

# Check if running on supported OS
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ This script only works on Linux"
    echo "💡 For other systems, use the Docker build method"
    exit 1
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "❌ Please don't run this script as root"
    echo "💡 The script will use sudo when needed"
    exit 1
fi

# Check dependencies
echo "🔍 Checking dependencies..."
missing_deps=()

if ! command -v wget &> /dev/null; then missing_deps+=("wget"); fi
if ! command -v unzip &> /dev/null; then missing_deps+=("unzip"); fi
if ! command -v qemu-user-static &> /dev/null; then missing_deps+=("qemu-user-static"); fi
if ! command -v parted &> /dev/null; then missing_deps+=("parted"); fi
if ! command -v kpartx &> /dev/null; then missing_deps+=("kpartx"); fi
if ! command -v dosfstools &> /dev/null; then missing_deps+=("dosfstools"); fi
if ! command -v e2fsprogs &> /dev/null; then missing_deps+=("e2fsprogs"); fi

if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo "❌ Missing dependencies: ${missing_deps[*]}"
    echo "📦 Install them with:"
    echo "   sudo apt-get update"
    echo "   sudo apt-get install -y ${missing_deps[*]}"
    exit 1
fi

echo "✅ All dependencies found"

# Ask for confirmation
echo ""
echo "📋 This will:"
echo "   • Download Raspberry Pi OS (~500MB)"
echo "   • Install Echo AI Assistant"
echo "   • Configure all services"
echo "   • Create a custom image (~2GB)"
echo "   • Take about 30-60 minutes"
echo ""
read -p "🤔 Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Build cancelled"
    exit 1
fi

# Run the build
echo "🚀 Starting build process..."
chmod +x scripts/build_pi_os.sh
./scripts/build_pi_os.sh

echo ""
echo "🎉 Build complete!"
echo ""
echo "📦 Your Echo AI Assistant Pi OS image is ready!"
echo "📍 Location: /tmp/echo-pi-os/"
echo ""
echo "🚀 Next steps:"
echo "1. Download Raspberry Pi Imager"
echo "2. Select 'Use custom image'"
echo "3. Choose the .img.xz file from /tmp/echo-pi-os/"
echo "4. Flash to your SD card"
echo "5. Boot your Raspberry Pi"
echo "6. Access http://[PI_IP]:5000"
echo ""
echo "🔑 Default API Token: echo-dev-kit-2025"
echo "📚 Documentation: docs/PI_OS_IMAGE.md"
echo ""
echo "Happy building! 🤖✨"
